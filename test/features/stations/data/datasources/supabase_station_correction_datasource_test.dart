import 'dart:convert';

import 'package:chargebub/features/stations/data/datasources/supabase_station_correction_datasource.dart';
import 'package:chargebub/features/stations/domain/entities/station.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('loads corrections for multiple text IDs in one batch query', () async {
    var requestCount = 0;
    String? requestedIds;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
      httpClient: MockClient((request) async {
        requestCount++;
        requestedIds = request.url.queryParameters['station_id'];
        return http.Response(
          jsonEncode([
            {
              'station_id': 'zigwheels_mumbai_0003',
              'name': 'Corrected station',
              'address': 'Corrected road',
              'charger_count': 4,
              'connector_types': ['CCS2', 'Type 2'],
              'operational_status': 'operational',
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    final dataSource = SupabaseStationCorrectionDataSource(client);

    final corrections = await dataSource.getForStationIds([
      'zigwheels_mumbai_0003',
      'ocm:station-42',
    ]);

    expect(requestCount, 1);
    expect(requestedIds, contains('zigwheels_mumbai_0003'));
    expect(requestedIds, contains('ocm:station-42'));
    expect(corrections.keys, ['zigwheels_mumbai_0003']);
    expect(
      corrections['zigwheels_mumbai_0003']!.operationalStatus,
      StationOperationalStatus.operational,
    );
  });

  test('does not call Supabase when the station ID list is empty', () async {
    var requestCount = 0;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
      httpClient: MockClient((_) async {
        requestCount++;
        return http.Response('[]', 200);
      }),
    );
    final dataSource = SupabaseStationCorrectionDataSource(client);

    final corrections = await dataSource.getForStationIds(const []);

    expect(corrections, isEmpty);
    expect(requestCount, 0);
  });
}
