
class Station {
  const Station({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.isOperational,
    required this.isPublic,
    required this.connectors,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final bool isOperational;
  final bool isPublic;
  final List<Connector> connectors;
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