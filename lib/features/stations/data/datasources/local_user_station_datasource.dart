import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/station.dart';

class LocalUserStationDataSource {
  LocalUserStationDataSource(this._preferences);

  static const _storageKey = 'user_stations';
  final SharedPreferences _preferences;

  List<Station> readStations() {
    final raw = _preferences.getStringList(_storageKey) ?? const [];
    return raw.map((value) => _fromJson(jsonDecode(value))).toList();
  }

  Future<void> writeStations(List<Station> stations) async {
    final values = stations
        .map((station) => jsonEncode(_toJson(station)))
        .toList();
    final saved = await _preferences.setStringList(_storageKey, values);
    if (!saved) {
      throw Exception('Could not save user-added station locally.');
    }
  }

  Map<String, dynamic> _toJson(Station station) {
    return {
      'id': station.id,
      'name': station.name,
      'address': station.address,
      'latitude': station.latitude,
      'longitude': station.longitude,
      'isPublic': station.isPublic,
      'operatorName': station.operatorName,
      'notes': station.notes,
      'connectors': station.connectors
          .map(
            (connector) => {
              'type': connector.type,
              'currentType': connector.currentType,
              'powerKw': connector.powerKw,
              'quantity': connector.quantity,
            },
          )
          .toList(),
    };
  }

  Station _fromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid saved user station.');
    }

    final connectors = (value['connectors'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (connector) => Connector(
            type: connector['type']?.toString() ?? 'Unknown',
            currentType: connector['currentType']?.toString() ?? 'Unknown',
            powerKw: (connector['powerKw'] as num?)?.toDouble(),
            quantity: (connector['quantity'] as num?)?.toInt() ?? 1,
          ),
        )
        .toList();

    return Station(
      id: value['id']?.toString() ?? '',
      name: value['name']?.toString() ?? '',
      address: value['address']?.toString() ?? '',
      latitude: (value['latitude'] as num).toDouble(),
      longitude: (value['longitude'] as num).toDouble(),
      distanceKm: 0,
      operationalStatus: StationOperationalStatus.unknown,
      isPublic: value['isPublic'] as bool?,
      connectors: connectors,
      source: StationSource.user,
      operatorName: value['operatorName']?.toString(),
      notes: value['notes']?.toString(),
    );
  }
}
