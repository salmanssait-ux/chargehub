#!/usr/bin/env python3
"""
ChargeHub Mumbai EV charger dataset builder.

What it does:
1. Downloads several public Mumbai EV-charger directory pages.
2. Extracts station-like name/address/metadata.
3. Geocodes addresses with OpenStreetMap Nominatim.
4. Keeps only records inside the Mumbai bounding box.
5. Deduplicates records using coordinates + normalized names/addresses.
6. Writes:
      output/mumbai_region_chargers.csv
      output/mumbai_region_chargers.json

This is intended for a TEST DATASET, not production scraping.

Install:
    python -m pip install requests beautifulsoup4

Run:
    python build_mumbai_dataset.py

Notes:
- Some directories are JavaScript-driven and may expose only part of their
  records through normal HTTP requests. The script records failures instead
  of pretending it scraped data that was not available.
- Nominatim is rate-limited. The script waits at least 1.1 seconds between
  geocoding requests and caches results in output/geocode_cache.json.
"""

from __future__ import annotations
import math
import csv
import hashlib
import json
import re
import time
import unicodedata
from pathlib import Path
from urllib.parse import quote

import requests
from bs4 import BeautifulSoup

OUT = Path("output")
OUT.mkdir(exist_ok=True)

HEADERS = {
    "User-Agent": "ChargeHub-Mumbai-TestDataset/1.0 (local development)"
}

SOURCES = [
    {
        "name": "ZigWheels",
        "url": "https://www.zigwheels.com/electric-charging-station/Mumbai",
    },
    {
        "name": "CarDekho",
        "url": "https://www.cardekho.com/electric-charging-station/mumbai",
    },
    {
        "name": "EcoGears",
        "url": "https://ecogears.in/ev-charging-station/mumbai/",
    },
    {
        "name": "Statiq",
        "url": "https://www.statiq.in/mumbai-ev-charging-station",
    },
    {
        "name": "MeraEV",
        "url": "https://www.meraev.com/charging-stations-in/mumbai",
    },
    {
        "name": "Tata Motors",
        "url": "https://xprest.tatamotors.com/electric/chargingpoint",
    },
]

# Approximate Mumbai metro bounding box. This deliberately includes
# Mumbai + nearby suburbs but excludes most of Navi Mumbai/Thane.
LAT_MIN = 18.85
LAT_MAX = 19.35
LON_MIN = 72.75
LON_MAX = 73.10

session = requests.Session()
session.headers.update(HEADERS)


def clean(value: str | None) -> str:
    if not value:
        return ""
    value = unicodedata.normalize("NFKC", value)
    value = re.sub(r"\s+", " ", value)
    return value.strip(" \t\r\n|•")


def norm(value: str) -> str:
    value = unicodedata.normalize("NFKD", value.lower())
    value = "".join(c for c in value if not unicodedata.combining(c))
    value = re.sub(r"[^a-z0-9]+", " ", value)
    return re.sub(r"\s+", " ", value).strip()


def fetch(url: str) -> str:
    r = session.get(url, timeout=30)
    r.raise_for_status()
    return r.text


def looks_like_address(text: str) -> bool:
    t = norm(text)
    address_words = [
        "mumbai", "bandra", "andheri", "powai", "malad", "goregaon",
        "borivali", "kurla", "chembur", "dadar", "worli", "colaba",
        "lower parel", "vile parle", "ghatkopar", "bkc", "sion",
        "mulund", "bhandup", "vikhroli", "marol", "kandivali",
        "byculla", "mazgaon", "tardeo", "santacruz", "matunga",
        "juhu", "prabhadevi", "mahima", "fort"
    ]
    return any(w in t for w in address_words) or bool(re.search(r"\b400\d{3}\b", text))


def extract_candidate_blocks(soup: BeautifulSoup, source: str) -> list[str]:
    """
    Extract station records without passing page-level text to the geocoder.

    ZigWheels/CarDekho pages contain repeated station cards. We look for
    headings containing "charging station", then extract only the nearest
    card-like ancestor. The parser also removes page-level headings and
    navigation noise.
    """
    blocks = []
    seen = set()

    if source in {"ZigWheels", "CarDekho"}:
        for heading in soup.find_all(["h2", "h3", "h4"]):
            title = clean(heading.get_text(" ", strip=True))

            if "charging station" not in title.lower():
                continue

            # Reject page-level titles such as "461 electric car charging
            # stations in Mumbai".
            if re.search(r"^\d+\s+electric\s+car\s+charging\s+stations?", title, re.I):
                continue

            # Search upward for the smallest ancestor that looks like one
            # station card.
            best = None
            parent = heading.parent

            for _ in range(8):
                if parent is None:
                    break

                txt = clean(parent.get_text(" ", strip=True))

                # A useful card normally contains Location and/or Charging
                # Slots and is not enormous.
                if (
                    40 <= len(txt) <= 1400
                    and re.search(r"\bLocation\b", txt, re.I)
                ):
                    best = txt
                    break

                parent = parent.parent

            if best is None:
                continue

            # Remove obvious page/navigation fragments.
            if norm(best).startswith("electric car charging stations in mumbai"):
                continue

            key = norm(best)
            if key not in seen:
                seen.add(key)
                blocks.append(best)

        return blocks

    # Other sources: use repeated station-ish containers, but never accept
    # very large containers that are probably the whole page.
    selectors = [
        "article",
        ".station",
        ".charging-station",
        ".charger",
        "[class*='station']",
        "[class*='charger']",
    ]

    for selector in selectors:
        for node in soup.select(selector):
            txt = clean(node.get_text(" ", strip=True))

            if len(txt) < 25 or len(txt) > 900:
                continue

            key = norm(txt)
            if key in seen:
                continue

            if not looks_like_address(txt):
                continue

            seen.add(key)
            blocks.append(txt)

        if len(blocks) >= 20:
            break

    return blocks

def parse_block(block: str, source: str) -> dict | None:
    text = clean(block)

    # Extract the station name from the beginning of the card.
    name_match = re.search(
        r"^(.*?charging station)",
        text,
        flags=re.I,
    )
    if name_match:
        name = clean(name_match.group(1))
    else:
        name = clean(text.split("Location", 1)[0])

    # Extract ONLY the text after "Location" and before the next metadata
    # label. This is what gets sent to Nominatim.
    location_match = re.search(
        r"\bLocation\b\s*[:\-]?\s*(.*?)(?=\bCharging Slots?\b|\bContact\b|\bPhone\b|\bGet Direction\b|$)",
        text,
        flags=re.I,
    )

    if location_match:
        address = clean(location_match.group(1))
    else:
        # Conservative fallback: don't geocode the whole card. Use only the
        # first short segment if it looks address-like.
        address = ""
        parts = [clean(p) for p in re.split(r"\s{2,}|\|", text) if clean(p)]
        for part in parts[1:]:
            if looks_like_address(part) and len(part) <= 500:
                address = part
                break

    # Reject obvious non-station/page headings.
    bad = [
        "electric car charging stations in mumbai",
        "electric charging station",
        "ev charging station in mumbai",
    ]
    if not name or norm(name) in bad or len(name) < 3:
        return None

    connector_matches = re.findall(
        r"\b(CCS(?:-?II|-?2)?|CHAdeMO|Type ?2|Type ?1|AC|DC|GBT|GB/T)\b",
        text,
        flags=re.I,
    )
    connectors = sorted({
        clean(x).upper()
        .replace("CCS-II", "CCS2")
        .replace("CCS-2", "CCS2")
    for x in connector_matches})

    power_match = re.search(r"\b(\d+(?:\.\d+)?)\s*kW\b", text, flags=re.I)
    power_kw = float(power_match.group(1)) if power_match else None

    slots_match = re.search(
        r"\b(?:slots?|slot)\s*[-: ]\s*(\d+)\b",
        text,
        flags=re.I,
    )
    slots = int(slots_match.group(1)) if slots_match else None

    return {
        "name": name[:250],
        "operator": guess_operator(name),
        "address": address[:500],
        "connector_types": connectors,
        "power_kw": power_kw,
        "charger_count": slots,
        "access": guess_access(name, text),
        "status": "",
        "source": source,
        "source_id": "",
        "latitude": None,
        "longitude": None,
    }

def guess_operator(name: str) -> str:
    n = norm(name)
    operators = [
        ("tata power", "Tata Power"),
        ("statiq", "Statiq"),
        ("charge zone", "Charge Zone"),
        ("jio bp", "Jio-bp"),
        ("adani", "Adani"),
        ("ather", "Ather"),
        ("iocl", "IOCL"),
        ("bpcl", "BPCL"),
        ("hpcl", "HPCL"),
        ("mg ", "MG"),
        ("bolt earth", "Bolt.Earth"),
        ("zeon", "Zeon"),
    ]
    for needle, label in operators:
        if needle in n:
            return label
    return ""


def guess_access(name: str, text: str) -> str:
    n = norm(name + " " + text)
    if "private" in n or "resident only" in n or "restricted" in n:
        return "restricted"
    return "public/unknown"


def geocode(address: str, cache: dict) -> tuple[float | None, float | None]:
    """
    Geocode with Nominatim first, then Photon.

    Existing successful cache entries are reused.
    Existing null cache entries are retried through Photon instead of being
    treated as permanently failed.
    """
    key = norm(address)
    if not key:
        return None, None

    cached = cache.get(key)
    if cached and cached.get("lat") is not None and cached.get("lon") is not None:
        return cached["lat"], cached["lon"]

    query = address
    if "mumbai" not in norm(query):
        query += ", Mumbai, Maharashtra, India"

    # First try Nominatim. The previous run showed that many detailed
    # Mumbai addresses fail there, so Photon is used as the fallback.
    nominatim_url = (
        "https://nominatim.openstreetmap.org/search"
        f"?format=jsonv2&limit=1&countrycodes=in&q={quote(query)}"
    )

    try:
        r = session.get(nominatim_url, timeout=15)
        r.raise_for_status()
        data = r.json()

        if data:
            lat = float(data[0]["lat"])
            lon = float(data[0]["lon"])

            if inside_mumbai(lat, lon):
                cache[key] = {"lat": lat, "lon": lon, "provider": "nominatim"}
                return lat, lon
    except Exception as exc:
        print(f"  Nominatim failed: {exc}")

    time.sleep(1.1)

    # Photon is an OSM-based geocoder with a public demo server. We bias the
    # search toward Mumbai and restrict the result to the Mumbai bounding box.
    photon_url = "https://photon.komoot.io/api/"
    params = {
        "q": query,
        "limit": 1,
        "lang": "en",
        "lat": 19.0760,
        "lon": 72.8777,
        "zoom": 12,
        "bbox": f"{LON_MIN},{LAT_MIN},{LON_MAX},{LAT_MAX}",
    }

    try:
        r = session.get(photon_url, params=params, timeout=20)
        r.raise_for_status()
        data = r.json()

        features = data.get("features", [])
        if features:
            coords = features[0].get("geometry", {}).get("coordinates", [])
            if len(coords) >= 2:
                lon = float(coords[0])
                lat = float(coords[1])

                if inside_mumbai(lat, lon):
                    cache[key] = {"lat": lat, "lon": lon, "provider": "photon"}
                    return lat, lon

    except Exception as exc:
        print(f"  Photon failed: {exc}")

    cache[key] = {"lat": None, "lon": None, "provider": "failed"}
    return None, None


def deduplicate(rows: list[dict]) -> list[dict]:
    """
    Remove duplicate station records while preserving stations with the same
    name at different locations.

    Before geocoding, use normalized name + address.
    After geocoding, also merge records whose coordinates are effectively
    identical (within roughly 50 metres).
    """
    result = []
    seen_text = set()

    for row in rows:
        name_key = norm(row.get("name", ""))
        address_key = norm(row.get("address", ""))

        # If both name and address are present, this is the safest textual key.
        text_key = (name_key, address_key)

        lat = row.get("latitude")
        lon = row.get("longitude")

        duplicate = text_key in seen_text

        if not duplicate and lat is not None and lon is not None:
            for existing in result:
                elat = existing.get("latitude")
                elon = existing.get("longitude")

                if elat is None or elon is None:
                    continue

                # ~50 m coordinate-level duplicate check.
                dlat = float(lat) - float(elat)
                dlon = float(lon) - float(elon)

                if abs(dlat) < 0.0005 and abs(dlon) < 0.0005:
                    duplicate = True
                    break

        if duplicate:
            continue

        seen_text.add(text_key)
        result.append(row)

    return result


# Central Mumbai reference point used for the testing dataset.
CENTER_LAT = 19.0760
CENTER_LON = 72.8777
REGION_RADIUS_KM = 50.0


def distance_km(lat: float, lon: float) -> float:
    """Great-circle distance from central Mumbai."""
    r = 6371.0
    p1 = math.radians(CENTER_LAT)
    p2 = math.radians(lat)
    dp = math.radians(lat - CENTER_LAT)
    dl = math.radians(lon - CENTER_LON)

    a = (
        math.sin(dp / 2) ** 2
        + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    )
    return 2 * r * math.asin(math.sqrt(a))


def inside_mumbai(lat: float, lon: float) -> bool:
    """Keep stations within the testing radius around central Mumbai."""
    return distance_km(lat, lon) <= REGION_RADIUS_KM



def write_outputs(rows: list[dict]) -> None:
    for i, row in enumerate(rows, start=1):
        row["id"] = f"mumbai_{i:04d}"

    fields = [
        "id", "name", "operator", "address", "latitude", "longitude",
        "connector_types", "power_kw", "charger_count", "access",
        "status", "source", "source_id",
    ]

    with open(OUT / "mumbai_region_chargers.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            out = dict(row)
            out["connector_types"] = ", ".join(out["connector_types"] or [])
            writer.writerow(out)

    with open(OUT / "mumbai_region_chargers.json", "w", encoding="utf-8") as f:
        json.dump(rows, f, ensure_ascii=False, indent=2)

    print(f"\nWrote {len(rows)} stations.")
    print(f"CSV : {OUT / 'mumbai_region_chargers.csv'}")
    print(f"JSON: {OUT / 'mumbai_region_chargers.json'}")


def main() -> None:
    all_rows: list[dict] = []

    for source in SOURCES:
        print(f"\n=== {source['name']} ===")
        try:
            html = fetch(source["url"])
            soup = BeautifulSoup(html, "html.parser")
            blocks = extract_candidate_blocks(soup, source["name"])
            print(f"Candidate blocks: {len(blocks)}")

            source_rows = []
            for block in blocks:
                row = parse_block(block, source["name"])
                if row:
                    source_rows.append(row)

            print(f"Parsed stations: {len(source_rows)}")
            all_rows.extend(source_rows)

        except Exception as exc:
            print(f"FAILED: {exc}")

    # Remove obvious duplicates before geocoding.
    early = deduplicate(all_rows)
    print(f"\nAfter initial deduplication: {len(early)}")

    missing_address = sum(1 for r in early if not r.get("address"))
    print(f"Records without a usable address: {missing_address}")

    # Safety check: don't accidentally send hundreds of bad page fragments
    # to Nominatim if a source's HTML structure changes.
    if len(early) > 700:
        raise RuntimeError(
            f"Safety stop: {len(early)} records were extracted before geocoding. "
            "The source parser is probably over-capturing page content. "
            "No geocoding requests were made."
        )

    cache_path = OUT / "geocode_cache.json"
    if cache_path.exists():
        cache = json.loads(cache_path.read_text(encoding="utf-8"))
    else:
        cache = {}

    final_rows = []
    for i, row in enumerate(early, start=1):
        if row["latitude"] is None:
            print(f"Geocoding {i}/{len(early)}: {row['address'] or row['name']}")
            lat, lon = geocode(row["address"], cache)
            row["latitude"] = lat
            row["longitude"] = lon

        if (
            row.get("latitude") is not None
            and row.get("longitude") is not None
            and inside_mumbai(row["latitude"], row["longitude"])
        ):
            final_rows.append(row)

        cache_path.write_text(
            json.dumps(cache, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    final_rows = deduplicate(final_rows)

    providers = {}
    for key, value in cache.items():
        provider = value.get("provider", "legacy")
        providers[provider] = providers.get(provider, 0) + 1

    print(f"Inside {REGION_RADIUS_KM:.0f} km Mumbai region: {len(final_rows)}")
    print("Geocoder results:", providers)
    write_outputs(final_rows)


if __name__ == "__main__":
    main()