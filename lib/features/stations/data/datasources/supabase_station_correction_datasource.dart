import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/station.dart';
import '../../domain/entities/station_correction.dart';

class SupabaseStationCorrectionDataSource {
  SupabaseStationCorrectionDataSource(this._client);

  static const _requestTimeout = Duration(seconds: 10);
  final SupabaseClient? _client;

  Future<Map<String, StationCorrection>> getForStationIds(
    Iterable<String> stationIds,
  ) async {
    final ids = stationIds.toSet().toList();
    final client = _client;
    if (ids.isEmpty || client == null) return const {};

    final rows = await client
        .from('station_corrections')
        .select(
          'station_id,name,address,charger_count,connector_types,operational_status',
        )
        .inFilter('station_id', ids)
        .timeout(_requestTimeout);

    return {
      for (final row in rows) row['station_id'].toString(): _fromRow(row),
    };
  }

  StationCorrection _fromRow(Map<String, dynamic> row) {
    final rawStatus = row['operational_status']?.toString().toLowerCase();
    final status = switch (rawStatus) {
      'operational' => StationOperationalStatus.operational,
      'unavailable' ||
      'not operational' => StationOperationalStatus.unavailable,
      'unknown' => StationOperationalStatus.unknown,
      _ => null,
    };
    final rawTypes = row['connector_types'];

    return StationCorrection(
      stationId: row['station_id'].toString(),
      name: row['name'] as String?,
      address: row['address'] as String?,
      chargerCount: (row['charger_count'] as num?)?.toInt(),
      connectorTypes: rawTypes is List
          ? rawTypes.map((value) => value.toString()).toList()
          : null,
      operationalStatus: status,
    );
  }
}
