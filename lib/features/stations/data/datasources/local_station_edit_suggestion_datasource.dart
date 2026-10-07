import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/station_edit_suggestion.dart';

class LocalStationEditSuggestionDataSource {
  LocalStationEditSuggestionDataSource(this._preferences);

  static const _storageKey = 'station_edit_suggestions';
  final SharedPreferences _preferences;

  Future<void> save(StationEditSuggestion suggestion) async {
    final suggestions = _preferences.getStringList(_storageKey) ?? [];
    suggestions.add(
      jsonEncode({
        'stationId': suggestion.stationId,
        'currentValues': {
          'name': suggestion.currentName,
          'address': suggestion.currentAddress,
          'chargerCount': suggestion.currentChargerCount,
          'connectorTypes': suggestion.currentConnectorTypes,
          'operationalStatus': suggestion.currentOperationalStatus.name,
        },
        'suggestedValues': {
          'name': suggestion.name,
          'address': suggestion.address,
          'chargerCount': suggestion.chargerCount,
          'connectorTypes': suggestion.connectorTypes,
          'operationalStatus': suggestion.operationalStatus.name,
        },
        'status': 'pending',
        'submittedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );

    final saved = await _preferences.setStringList(_storageKey, suggestions);
    if (!saved) {
      throw StateError('Could not save this suggestion on this device.');
    }
  }
}
