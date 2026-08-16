import 'dart:math' as math;

import '../../domain/entities/station.dart';

class ZigWheelsStationModel {
  const ZigWheelsStationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.connectorTypes,
    required this.powerKw,
    required this.chargerCount,
    required this.access,
    required this.status,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> connectorTypes;
  final double? powerKw;
  final int chargerCount;
  final String access;
  final String status;

  factory ZigWheelsStationModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawConnectorTypes = json['connector_types'];

    final connectorTypes = rawConnectorTypes is List
        ? rawConnectorTypes
        .whereType<String>()
        .where((type) => type.trim().isNotEmpty)
        .toList()
        : <String>[];

    return ZigWheelsStationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'EV Charging Station',
      address: json['address']?.toString().trim().isNotEmpty == true
          ? json['address'].toString().trim()
          : 'Address unavailable',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      connectorTypes: connectorTypes,
      powerKw: (json['power_kw'] as num?)?.toDouble(),
      chargerCount:
      (json['charger_count'] as num?)?.toInt() ?? 1,
      access: json['access']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  Station toEntity({
    required double userLatitude,
    required double userLongitude,
  }) {
    return Station(
      id: 'zigwheels_$id',
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      distanceKm: _distanceKm(
        userLatitude,
        userLongitude,
        latitude,
        longitude,
      ),
      operationalStatus: _operationalStatus,
      isPublic: _isPublic,
      connectors: _buildConnectors(),
      source: StationSource.zigwheels,
    );
  }

  List<Connector> _buildConnectors() {
    if (connectorTypes.isEmpty) {
      return [
        Connector(
          type: 'Unknown',
          currentType: 'Unknown',
          powerKw: powerKw,
          quantity: chargerCount,
        ),
      ];
    }

    return connectorTypes.map(
          (type) {
        return Connector(
          type: type,
          currentType: 'Unknown',
          powerKw: powerKw,
          quantity: chargerCount,
        );
      },
    ).toList();
  }

  StationOperationalStatus get _operationalStatus {
    final value = status.toLowerCase().trim();

    if (value.contains('operational') ||
        value.contains('available') ||
        value == 'active') {
      return StationOperationalStatus.operational;
    }

    if (value.contains('unavailable') ||
        value.contains('closed') ||
        value.contains('inactive')) {
      return StationOperationalStatus.unavailable;
    }

    return StationOperationalStatus.unknown;
  }

  bool? get _isPublic {
    final value = access.toLowerCase();

    if (value.contains('public')) {
      return true;
    }

    if (value.contains('private')) {
      return false;
    }

    return null;
  }

  static double _distanceKm(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const earthRadiusKm = 6371.0;

    final lat1Rad = lat1 * math.pi / 180;
    final lat2Rad = lat2 * math.pi / 180;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(lat1Rad) *
                math.cos(lat2Rad) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);

    final c =
        2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }
}