import 'dart:math';

import '../../domain/entities/station.dart';

class StationDeduplicator {
  const StationDeduplicator();

  static const double _duplicateRadiusMeters = 50;

  List<Station> deduplicate(List<Station> stations) {
    final result = <Station>[];

    for (final station in stations) {
      final duplicateIndex = _findDuplicateIndex(
        result,
        station,
      );

      if (duplicateIndex == -1) {
        result.add(station);
        continue;
      }

      final existing = result[duplicateIndex];

      result[duplicateIndex] = _mergeStations(
        existing,
        station,
      );
    }

    result.sort(
      (a, b) => a.distanceKm.compareTo(b.distanceKm),
    );

    return result;
  }

  int _findDuplicateIndex(
    List<Station> existingStations,
    Station candidate,
  ) {
    for (var i = 0; i < existingStations.length; i++) {
      final existing = existingStations[i];

      final distanceMeters = _calculateDistanceMeters(
        existing.latitude,
        existing.longitude,
        candidate.latitude,
        candidate.longitude,
      );

      if (distanceMeters > _duplicateRadiusMeters) {
        continue;
      }

      if (_namesMatch(existing.name, candidate.name)) {
        return i;
      }

      if (_addressesMatch(existing.address, candidate.address)) {
        return i;
      }
    }

    return -1;
  }

  bool _namesMatch(String first, String second) {
    final a = _normalize(first);
    final b = _normalize(second);

    if (a.isEmpty || b.isEmpty) {
      return false;
    }

    if (a == b) {
      return true;
    }

    if (a.contains(b) || b.contains(a)) {
      return true;
    }

    final firstWords = a.split(' ').toSet();
    final secondWords = b.split(' ').toSet();

    if (firstWords.isEmpty || secondWords.isEmpty) {
      return false;
    }

    final commonWords =
        firstWords.intersection(secondWords).length;

    final smallerWordCount =
        min(firstWords.length, secondWords.length);

    return smallerWordCount >= 2 &&
        commonWords >= 2;
  }

  bool _addressesMatch(String first, String second) {
    final a = _normalize(first);
    final b = _normalize(second);

    if (a.isEmpty ||
        b.isEmpty ||
        a == 'address unavailable' ||
        b == 'address unavailable' ||
        a == 'unknown address' ||
        b == 'unknown address') {
      return false;
    }

    if (a == b) {
      return true;
    }

    return a.contains(b) || b.contains(a);
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Station _mergeStations(
    Station first,
    Station second,
  ) {
    final preferred = _preferredStation(
      first,
      second,
    );

    final other = identical(preferred, first)
        ? second
        : first;

    return Station(
      id: preferred.id,
      name: _bestName(
        preferred.name,
        other.name,
      ),
      address: _bestAddress(
        preferred.address,
        other.address,
      ),
      latitude: preferred.latitude,
      longitude: preferred.longitude,
      distanceKm: min(
        first.distanceKm,
        second.distanceKm,
      ),
      operationalStatus: _mergeOperationalStatus(
        first.operationalStatus,
        second.operationalStatus,
      ),
      isPublic: _mergePublicStatus(
        first.isPublic,
        second.isPublic,
      ),
      connectors: _mergeConnectors(
        first.connectors,
        second.connectors,
      ),
      source: preferred.source,
    );
  }

  Station _preferredStation(
    Station first,
    Station second,
  ) {
    if (first.source == StationSource.ocm &&
        second.source == StationSource.osm) {
      return _hasBetterData(first, second)
          ? first
          : second;
    }

    if (first.source == StationSource.osm &&
        second.source == StationSource.ocm) {
      return _hasBetterData(second, first)
          ? second
          : first;
    }

    return _hasBetterData(first, second)
        ? first
        : second;
  }

  bool _hasBetterData(
    Station first,
    Station second,
  ) {
    return _dataScore(first) >= _dataScore(second);
  }

  int _dataScore(Station station) {
    var score = 0;

    if (_isUsefulName(station.name)) {
      score += 2;
    }

    if (_isUsefulAddress(station.address)) {
      score += 2;
    }

    if (station.connectors.any(
      (connector) => connector.type != 'Unknown',
    )) {
      score += 2;
    }

    if (station.connectors.any(
      (connector) => connector.powerKw != null,
    )) {
      score += 2;
    }

    if (station.isPublic != null) {
      score++;
    }

    if (station.operationalStatus !=
        StationOperationalStatus.unknown) {
      score++;
    }

    return score;
  }

  bool _isUsefulName(String value) {
    final normalized = _normalize(value);

    return normalized.isNotEmpty &&
        normalized != 'ev charging station' &&
        normalized != 'charging station';
  }

  bool _isUsefulAddress(String value) {
    final normalized = _normalize(value);

    return normalized.isNotEmpty &&
        normalized != 'address unavailable' &&
        normalized != 'unknown address';
  }

  String _bestName(
    String first,
    String second,
  ) {
    if (!_isUsefulName(first) &&
        _isUsefulName(second)) {
      return second;
    }

    return first;
  }

  String _bestAddress(
    String first,
    String second,
  ) {
    if (!_isUsefulAddress(first) &&
        _isUsefulAddress(second)) {
      return second;
    }

    return first;
  }

  StationOperationalStatus _mergeOperationalStatus(
    StationOperationalStatus first,
    StationOperationalStatus second,
  ) {
    if (first == StationOperationalStatus.operational ||
        second == StationOperationalStatus.operational) {
      return StationOperationalStatus.operational;
    }

    if (first == StationOperationalStatus.unavailable ||
        second == StationOperationalStatus.unavailable) {
      return StationOperationalStatus.unavailable;
    }

    return StationOperationalStatus.unknown;
  }

  bool? _mergePublicStatus(
    bool? first,
    bool? second,
  ) {
    return first ?? second;
  }

  List<Connector> _mergeConnectors(
    List<Connector> first,
    List<Connector> second,
  ) {
    final merged = <Connector>[];

    for (final connector in [
      ...first,
      ...second,
    ]) {
      final exists = merged.any(
        (existing) =>
            _normalize(existing.type) ==
            _normalize(connector.type),
      );

      if (!exists) {
        merged.add(connector);
      }
    }

    return merged;
  }

  double _calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;

    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;

    final deltaLat = (lat2 - lat1) * pi / 180;
    final deltaLon = (lon2 - lon1) * pi / 180;

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLon / 2) *
            sin(deltaLon / 2);

    final c = 2 * atan2(
      sqrt(a),
      sqrt(1 - a),
    );

    return earthRadiusMeters * c;
  }
}
