import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/station.dart';

class SupabaseStationsDataSource {
  SupabaseStationsDataSource(this._client);

  static const _requestTimeout = Duration(seconds: 15);
  static const _pageSize = 500;
  final SupabaseClient? _client;

  Future<List<Station>> getNearbyStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }

    final latitudeDelta = radiusKm / 110.574;
    final longitudeScale = math.max(
      math.cos(latitude * math.pi / 180).abs(),
      0.000001,
    );
    final longitudeDelta = radiusKm / (111.320 * longitudeScale);
    final south = math.max(-90.0, latitude - latitudeDelta);
    final north = math.min(90.0, latitude + latitudeDelta);
    final west = math.max(-180.0, longitude - longitudeDelta);
    final east = math.min(180.0, longitude + longitudeDelta);
    final stations = <Station>[];
    var offset = 0;

    while (true) {
      final rows = await client
          .from('stations')
          .select(
            'id,name,operator_name,address,latitude,longitude,connector_types,'
            'charger_count,power_kw,operational_status,source,notes',
          )
          .gte('latitude', south)
          .lte('latitude', north)
          .gte('longitude', west)
          .lte('longitude', east)
          .order('id')
          .range(offset, offset + _pageSize - 1)
          .timeout(_requestTimeout);

      for (final row in rows) {
        try {
          final station = _toStation(row, latitude, longitude);
          if (station.distanceKm <= radiusKm) stations.add(station);
        } on FormatException catch (error) {
          debugPrint(
            'Skipping malformed public station ${row['id'] ?? '<unknown>'}: '
            '$error',
          );
        }
      }

      if (rows.length < _pageSize) break;
      offset += _pageSize;
    }

    stations.sort(
      (first, second) => first.distanceKm.compareTo(second.distanceKm),
    );
    return stations;
  }

  Station _toStation(
    Map<String, dynamic> row,
    double userLatitude,
    double userLongitude,
  ) {
    final id = row['id'];
    final name = row['name'];
    final rawLatitude = row['latitude'];
    final rawLongitude = row['longitude'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        rawLatitude is! num ||
        rawLongitude is! num) {
      throw const FormatException('Missing required station fields.');
    }

    final latitude = rawLatitude.toDouble();
    final longitude = rawLongitude.toDouble();
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180) {
      throw const FormatException('Station coordinates are invalid.');
    }

    final rawChargerCount = row['charger_count'];
    if (rawChargerCount is! num ||
        !rawChargerCount.isFinite ||
        rawChargerCount < 1 ||
        rawChargerCount.toInt() != rawChargerCount) {
      throw const FormatException('Station charger count is invalid.');
    }
    final chargerCount = rawChargerCount.toInt();
    final rawConnectorTypes = row['connector_types'];
    final connectorTypes = rawConnectorTypes is List
        ? rawConnectorTypes
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList()
        : const <String>[];
    final rawPowerKw = row['power_kw'];
    final powerKw = rawPowerKw is num && rawPowerKw.isFinite
        ? rawPowerKw.toDouble()
        : null;
    final operationalStatus = switch (row['operational_status']
        ?.toString()
        .toLowerCase()
        .trim()) {
      'operational' ||
      'available' ||
      'active' => StationOperationalStatus.operational,
      'unavailable' ||
      'not operational' ||
      'closed' ||
      'inactive' => StationOperationalStatus.unavailable,
      _ => StationOperationalStatus.unknown,
    };
    final sourceName = _optionalText(row['source']);

    return Station(
      id: id,
      name: name.trim(),
      address: _optionalText(row['address']) ?? '',
      latitude: latitude,
      longitude: longitude,
      distanceKm: _distanceKm(userLatitude, userLongitude, latitude, longitude),
      operationalStatus: operationalStatus,
      isPublic: true,
      connectors: [
        for (final connectorType in connectorTypes)
          Connector(
            type: connectorType,
            currentType: 'Unknown',
            powerKw: powerKw,
            quantity: 1,
          ),
      ],
      source: sourceName?.toLowerCase() == 'user'
          ? StationSource.user
          : StationSource.supabase,
      chargerCount: chargerCount,
      operatorName: _optionalText(row['operator_name']),
      notes: _optionalText(row['notes']),
      sourceName: sourceName,
    );
  }

  String? _optionalText(dynamic value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
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
