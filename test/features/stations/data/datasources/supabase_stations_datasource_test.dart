import 'dart:convert';

import 'package:chargebub/features/stations/data/datasources/supabase_stations_datasource.dart';
import 'package:chargebub/features/stations/domain/entities/station.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'maps public stations and skips malformed or out-of-radius records',
    () async {
      late Uri requestedUri;
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test-anon-key',
        httpClient: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode([
              {
                'id': '11111111-1111-4111-8111-111111111111',
                'name': 'EcoGears Station',
                'operator_name': null,
                'address': null,
                'latitude': 19.1,
                'longitude': 72.9,
                'connector_types': ['CCS2', '', 42],
                'charger_count': 4,
                'power_kw': null,
                'operational_status': 'operational',
                'source': 'EcoGears June 2026',
                'notes': null,
              },
              {
                'id': '22222222-2222-4222-8222-222222222222',
                'name': 'Invalid coordinates',
                'latitude': 91,
                'longitude': 72.9,
                'charger_count': 1,
              },
              {
                'id': '33333333-3333-4333-8333-333333333333',
                'name': 'Invalid charger count',
                'latitude': 19.1,
                'longitude': 72.9,
                'charger_count': 0,
              },
              {
                'id': '44444444-4444-4444-8444-444444444444',
                'name': 'Far station',
                'latitude': 19.5,
                'longitude': 72.9,
                'connector_types': [],
                'charger_count': 1,
                'operational_status': 'unknown',
                'source': 'ZigWheels',
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      final dataSource = SupabaseStationsDataSource(client);

      final stations = await dataSource.getNearbyStations(
        latitude: 19.076,
        longitude: 72.8777,
        radiusKm: 20,
      );

      expect(stations, hasLength(1));
      final station = stations.single;
      expect(station.id, '11111111-1111-4111-8111-111111111111');
      expect(station.name, 'EcoGears Station');
      expect(station.address, isEmpty);
      expect(station.operatorName, isNull);
      expect(station.chargerCount, 4);
      expect(station.connectors.map((connector) => connector.type), ['CCS2']);
      expect(station.connectors.single.powerKw, isNull);
      expect(station.operationalStatus, StationOperationalStatus.operational);
      expect(station.source, StationSource.supabase);
      expect(station.sourceName, 'EcoGears June 2026');
      expect(station.notes, isNull);
      expect(requestedUri.path, '/rest/v1/stations');
      expect(
        requestedUri.queryParametersAll['latitude']!.any(
          (value) => value.startsWith('gte.'),
        ),
        isTrue,
      );
      expect(
        requestedUri.queryParametersAll['longitude']!.any(
          (value) => value.startsWith('gte.'),
        ),
        isTrue,
      );
    },
  );

  test('surfaces a Supabase request error', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
      httpClient: MockClient(
        (request) async => http.Response(
          '{"message":"database unavailable"}',
          503,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
    );
    final dataSource = SupabaseStationsDataSource(client);

    await expectLater(
      dataSource.getNearbyStations(
        latitude: 19.076,
        longitude: 72.8777,
        radiusKm: 20,
      ),
      throwsA(isA<PostgrestException>()),
    );
  });
}
