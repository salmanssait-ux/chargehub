import '../../domain/entities/station.dart';

class OcmStationModel {
  const OcmStationModel({
    required this.id,
    required this.addressInfo,
    required this.statusType,
    required this.usageType,
    required this.connections,
  });

  final int id;
  final OcmAddressInfo addressInfo;
  final OcmStatusType? statusType;
  final OcmUsageType? usageType;
  final List<OcmConnection> connections;

  factory OcmStationModel.fromJson(Map<String, dynamic> json) {
    return OcmStationModel(
      id: json['ID'] as int? ?? 0,
      addressInfo: OcmAddressInfo.fromJson(
        (json['AddressInfo'] as Map<String, dynamic>?) ?? {},
      ),
      statusType: json['StatusType'] != null
          ? OcmStatusType.fromJson(
        json['StatusType'] as Map<String, dynamic>,
      )
          : null,
      usageType: json['UsageType'] != null
          ? OcmUsageType.fromJson(
        json['UsageType'] as Map<String, dynamic>,
      )
          : null,
      connections: (json['Connections'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(OcmConnection.fromJson)
          .toList() ??
          const [],
    );
  }

  Station toEntity() {
    return Station(
      id: id.toString(),
      name: addressInfo.title,
      address: addressInfo.addressLine1,
      latitude: addressInfo.latitude,
      longitude: addressInfo.longitude,
      distanceKm: addressInfo.distance ?? 0.0,
      operationalStatus: _getOperationalStatus(),
      isPublic: usageType?.isPublic,
      connectors: connections.map((e) => e.toEntity()).toList(),
      source: StationSource.ocm,
    );
  }

  StationOperationalStatus _getOperationalStatus() {
    final operational = statusType?.isOperational;

    if (operational == true) {
      return StationOperationalStatus.operational;
    }

    if (operational == false) {
      return StationOperationalStatus.unavailable;
    }

    return StationOperationalStatus.unknown;
  }
}

class OcmAddressInfo {
  const OcmAddressInfo({
    required this.title,
    required this.addressLine1,
    required this.latitude,
    required this.longitude,
    this.distance,
  });

  final String title;
  final String addressLine1;
  final double latitude;
  final double longitude;
  final double? distance;

  factory OcmAddressInfo.fromJson(Map<String, dynamic> json) {
    return OcmAddressInfo(
      title: json['Title'] as String? ?? 'Unknown Station',
      addressLine1: json['AddressLine1'] as String? ?? '',
      latitude: (json['Latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['Longitude'] as num?)?.toDouble() ?? 0.0,
      distance: (json['Distance'] as num?)?.toDouble(),
    );
  }
}

class OcmStatusType {
  const OcmStatusType({
    required this.isOperational,
  });

  final bool? isOperational;

  factory OcmStatusType.fromJson(Map<String, dynamic> json) {
    return OcmStatusType(
      isOperational: json['IsOperational'] as bool?,
    );
  }
}

class OcmUsageType {
  const OcmUsageType({
    required this.isPublic,
  });

  final bool? isPublic;

  factory OcmUsageType.fromJson(Map<String, dynamic> json) {
    final title = json['Title'] as String?;

    if (title == null) {
      return const OcmUsageType(
        isPublic: null,
      );
    }

    if (title.toLowerCase() == 'public') {
      return const OcmUsageType(
        isPublic: true,
      );
    }

    if (title.toLowerCase() == 'private') {
      return const OcmUsageType(
        isPublic: false,
      );
    }

    return const OcmUsageType(
      isPublic: null,
    );
  }
}

class OcmConnection {
  const OcmConnection({
    required this.type,
    required this.currentType,
    required this.powerKw,
    required this.quantity,
  });

  final String type;
  final String currentType;
  final double? powerKw;
  final int quantity;

  factory OcmConnection.fromJson(Map<String, dynamic> json) {
    return OcmConnection(
      type: (json['ConnectionType']
      as Map<String, dynamic>?)?['Title']
      as String? ??
          'Unknown',
      currentType: (json['CurrentType']
      as Map<String, dynamic>?)?['Title']
      as String? ??
          'Unknown',
      powerKw: (json['PowerKW'] as num?)?.toDouble(),
      quantity: json['Quantity'] as int? ?? 1,
    );
  }

  Connector toEntity() {
    return Connector(
      type: type,
      currentType: currentType,
      powerKw: powerKw,
      quantity: quantity,
    );
  }
}