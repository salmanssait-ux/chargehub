import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/station.dart';
import '../../domain/entities/station_edit_suggestion.dart';

class SupabaseStationEditSuggestionDataSource {
  SupabaseStationEditSuggestionDataSource(this._client);

  static const _requestTimeout = Duration(seconds: 15);
  final SupabaseClient? _client;

  Future<void> create(StationEditSuggestion suggestion) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }

    final user =
        client.auth.currentUser ??
        (await client.auth.signInAnonymously().timeout(_requestTimeout)).user;
    if (user == null) {
      throw const AuthException('Could not create an authenticated session.');
    }

    await client
        .from('station_edit_submissions')
        .insert({
          'station_id': suggestion.stationId,
          'submitted_by': user.id,
          'current_name': suggestion.currentName,
          'current_address': suggestion.currentAddress,
          'current_charger_count': suggestion.currentChargerCount,
          'current_connector_types': suggestion.currentConnectorTypes,
          'current_operational_status': _statusValue(
            suggestion.currentOperationalStatus,
          ),
          'suggested_name': suggestion.name,
          'suggested_address': suggestion.address,
          'suggested_charger_count': suggestion.chargerCount,
          'suggested_connector_types': suggestion.connectorTypes,
          'suggested_operational_status': _statusValue(
            suggestion.operationalStatus,
          ),
        })
        .timeout(_requestTimeout);
  }

  String _statusValue(StationOperationalStatus status) {
    return switch (status) {
      StationOperationalStatus.operational => 'operational',
      StationOperationalStatus.unavailable => 'unavailable',
      StationOperationalStatus.unknown => 'unknown',
    };
  }
}
