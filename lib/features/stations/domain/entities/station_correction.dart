import 'station.dart';

class StationCorrection {
  const StationCorrection({
    required this.stationId,
    this.name,
    this.address,
    this.chargerCount,
    this.connectorTypes,
    this.operationalStatus,
  });

  final String stationId;
  final String? name;
  final String? address;
  final int? chargerCount;
  final List<String>? connectorTypes;
  final StationOperationalStatus? operationalStatus;

  Station applyTo(Station station) {
    if (station.id != stationId) return station;

    return Station(
      id: station.id,
      name: name ?? station.name,
      address: address ?? station.address,
      latitude: station.latitude,
      longitude: station.longitude,
      distanceKm: station.distanceKm,
      operationalStatus: operationalStatus ?? station.operationalStatus,
      isPublic: station.isPublic,
      connectors: connectorTypes == null
          ? station.connectors
          : _correctedConnectors(station.connectors, connectorTypes!),
      source: station.source,
      chargerCount: chargerCount ?? station.chargerCount,
      operatorName: station.operatorName,
      notes: station.notes,
    );
  }

  List<Connector> _correctedConnectors(
    List<Connector> existing,
    List<String> types,
  ) {
    return [
      for (final type in types)
        if (type.trim().isNotEmpty) _connectorFor(existing, type.trim()),
    ];
  }

  Connector _connectorFor(List<Connector> existing, String type) {
    for (final connector in existing) {
      if (connector.type.toLowerCase() == type.toLowerCase()) {
        return Connector(
          type: type,
          currentType: connector.currentType,
          powerKw: connector.powerKw,
          quantity: connector.quantity,
        );
      }
    }
    return Connector(
      type: type,
      currentType: 'Unknown',
      powerKw: null,
      quantity: 1,
    );
  }
}
