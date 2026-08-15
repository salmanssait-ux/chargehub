class Station {
  const Station({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.operationalStatus,
    required this.isPublic,
    required this.connectors,
    required this.source,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final StationOperationalStatus operationalStatus;
  final bool? isPublic;
  final List<Connector> connectors;
  final StationSource source;
}

enum StationSource {
  ocm,
  osm,
}

enum StationOperationalStatus {
  operational,
  unavailable,
  unknown,
}

class Connector {
  const Connector({
    required this.type,
    required this.currentType,
    required this.powerKw,
    required this.quantity,
  });

  final String type;
  final String currentType;
  final double? powerKw;
  final int quantity;
}
