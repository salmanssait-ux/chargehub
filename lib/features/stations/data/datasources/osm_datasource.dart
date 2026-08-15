import 'dart:convert';

import 'package:http/http.dart' as http;

class OsmDataSource {
  OsmDataSource(this._client);

  final http.Client _client;

  static const List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];

  static const Duration _requestTimeout = Duration(seconds: 12);

  Future<List<Map<String, dynamic>>> getNearbyStations({
    required double latitude,
    required double longitude,
    double distanceKm = 10,
  }) async {
    final radiusMeters = (distanceKm * 1000).round();

    final query = '''
[out:json][timeout:10];

(
  node["amenity"="charging_station"](
    around:$radiusMeters,$latitude,$longitude
  );

  way["amenity"="charging_station"](
    around:$radiusMeters,$latitude,$longitude
  );

  node["man_made"="charge_point"](
    around:$radiusMeters,$latitude,$longitude
  );

  way["man_made"="charge_point"](
    around:$radiusMeters,$latitude,$longitude
  );
);

out center;
''';

    Object? lastError;

    for (final endpoint in _endpoints) {
      try {
        print('Trying OSM endpoint: $endpoint');

        final response = await _client
            .post(
          Uri.parse(endpoint),
          headers: const {
            'User-Agent': 'ChargeHub/1.0',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'data': query,
          },
        )
            .timeout(_requestTimeout);

        print(
          'OSM response from $endpoint: ${response.statusCode}',
        );

        if (response.statusCode != 200) {
          lastError = Exception(
            'OSM server returned ${response.statusCode}',
          );
          continue;
        }

        final decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          throw const FormatException(
            'Invalid OSM response format',
          );
        }

        final elements = decoded['elements'];

        if (elements is! List) {
          return [];
        }

        final stations = elements
            .whereType<Map<String, dynamic>>()
            .toList();

        print(
          'OSM stations received: ${stations.length}',
        );

        return stations;
      } catch (e) {
        print(
          'OSM endpoint failed: $endpoint\n$e',
        );

        lastError = e;
      }
    }

    throw Exception(
      'All OSM servers failed: $lastError',
    );
  }
}