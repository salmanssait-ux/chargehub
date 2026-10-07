import 'station.dart';

class StationEditSuggestion {
  const StationEditSuggestion({
    required this.stationId,
    required this.currentName,
    required this.currentAddress,
    required this.currentChargerCount,
    required this.currentConnectorTypes,
    required this.currentOperationalStatus,
    required this.name,
    required this.address,
    required this.chargerCount,
    required this.connectorTypes,
    required this.operationalStatus,
  });

  final String stationId;

  final String currentName;
  final String currentAddress;
  final int? currentChargerCount;
  final List<String> currentConnectorTypes;
  final StationOperationalStatus currentOperationalStatus;

  final String name;
  final String address;
  final int chargerCount;
  final List<String> connectorTypes;
  final StationOperationalStatus operationalStatus;
}
