import 'dart:async';
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/station.dart';

class SupabaseApprovedStationDataSource {
  SupabaseApprovedStationDataSource(this._client);

  static const _requestTimeout = Duration(seconds: 15);
  final SupabaseClient? _client;

  Future<List<Station>> getNearbyStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final client = _client;
    if (client == null) return const [];

    final latitudeDelta = radiusKm / 110.574;
    final longitudeScale = math.max(
      math.cos(latitude * math.pi / 180).abs(),
      0.000001,
    );
    final longitudeDelta = radiusKm / (111.320 * longitudeScale);
    final rows = await client
        .from('stations')
        .select()
        .gte('latitude', latitude - latitudeDelta)
        .lte('latitude', latitude + latitudeDelta)
        .gte('longitude', longitude - longitudeDelta)
        .lte('longitude', longitude + longitudeDelta)
        .limit(500)
        .timeout(_requestTimeout);

    return rows
        .map((row) => _toStation(row, latitude, longitude))
        .where(
          (station) =>
              _distanceKm(
                latitude,
                longitude,
                station.latitude,
                station.longitude,
              ) <=
              radiusKm,
        )
        .toList();
  }

  Station _toStation(
    Map<String, dynamic> row,
    double userLatitude,
    double userLongitude,
  ) {
    final latitude = (row['latitude'] as num).toDouble();
    final longitude = (row['longitude'] as num).toDouble();
    final connectorTypes =
        (row['connector_types'] as List<dynamic>? ?? const [])
            .map((value) => value.toString())
            .toList();
    final chargerCount = (row['charger_count'] as num?)?.toInt() ?? 1;
    final powerKw = (row['power_kw'] as num?)?.toDouble();
    final operationalStatus = switch (row['operational_status']) {
      'operational' => StationOperationalStatus.operational,
      'unavailable' => StationOperationalStatus.unavailable,
      _ => StationOperationalStatus.unknown,
    };

    return Station(
      id: row['id'].toString(),
      name: row['name'] as String,
      address: row['address'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
      distanceKm: _distanceKm(userLatitude, userLongitude, latitude, longitude),
      operationalStatus: operationalStatus,
      isPublic: true,
      connectors: connectorTypes.isEmpty
          ? const []
          : [
              for (final connectorType in connectorTypes)
                Connector(
                  type: connectorType,
                  currentType: 'Unknown',
                  powerKw: powerKw,
                  quantity: 1,
                ),
            ],
      source: StationSource.user,
      chargerCount: chargerCount,
      operatorName: row['operator_name'] as String?,
      notes: row['notes'] as String?,
    );
  }

  double _distanceKm(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadiusKm = 6371.0;
    final deltaLatitude = _radians(latitude2 - latitude1);
    final deltaLongitude = _radians(longitude2 - longitude1);
    final a =
        math.pow(math.sin(deltaLatitude / 2), 2) +
        math.cos(_radians(latitude1)) *
            math.cos(_radians(latitude2)) *
            math.pow(math.sin(deltaLongitude / 2), 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}
