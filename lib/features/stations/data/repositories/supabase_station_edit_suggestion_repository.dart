import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/station.dart';
import '../../domain/entities/station_edit_suggestion.dart';
import '../../domain/errors/station_submission_failure.dart';
import '../../domain/repositories/station_edit_suggestion_repository.dart';
import '../datasources/supabase_station_edit_suggestion_datasource.dart';

class SupabaseStationEditSuggestionRepository
    implements StationEditSuggestionRepository {
  SupabaseStationEditSuggestionRepository(this._dataSource);

  final SupabaseStationEditSuggestionDataSource _dataSource;

  @override
  Future<void> submit(StationEditSuggestion suggestion) async {
    _validate(suggestion);
    if (!_hasChanges(suggestion)) {
      throw ArgumentError('At least one station detail must be corrected.');
    }

    try {
      await _dataSource.create(suggestion);
    } catch (error) {
      if (error is StationSubmissionFailure) rethrow;
      throw StationSubmissionFailure(_errorMessage(error));
    }
  }

  void _validate(StationEditSuggestion suggestion) {
    if (suggestion.stationId.trim().isEmpty) {
      throw ArgumentError('Station identifier is required.');
    }
    if (suggestion.name.trim().isEmpty || suggestion.address.trim().isEmpty) {
      throw ArgumentError('Station name and address are required.');
    }
    if (suggestion.chargerCount < 1) {
      throw ArgumentError('Charger count must be a positive whole number.');
    }
    if (suggestion.connectorTypes.isEmpty ||
        suggestion.connectorTypes.any((type) => type.trim().isEmpty)) {
      throw ArgumentError('Select at least one charger type.');
    }
    if (suggestion.operationalStatus == StationOperationalStatus.unknown) {
      throw ArgumentError('Select a valid station status.');
    }
  }

  bool _hasChanges(StationEditSuggestion suggestion) {
    return suggestion.name.trim() != suggestion.currentName.trim() ||
        suggestion.address.trim() != suggestion.currentAddress.trim() ||
        suggestion.chargerCount != suggestion.currentChargerCount ||
        !_sameTypes(
          suggestion.connectorTypes,
          suggestion.currentConnectorTypes,
        ) ||
        suggestion.operationalStatus != suggestion.currentOperationalStatus;
  }

  bool _sameTypes(List<String> first, List<String> second) {
    final a = first.map((type) => type.trim().toLowerCase()).toSet();
    final b = second.map((type) => type.trim().toLowerCase()).toSet();
    return a.length == b.length && a.containsAll(b);
  }

  String _errorMessage(Object error) {
    if (error is TimeoutException) {
      return 'The request took too long. Check your connection and try again.';
    }
    if (error is ClientException || error is AuthRetryableFetchException) {
      return 'Could not connect to submit the edit. Check your internet and retry.';
    }
    if (error is AuthException) {
      return 'Could not start a secure submission session. Please try again.';
    }
    if (error is PostgrestException) {
      return 'The server could not accept this edit. Please try again.';
    }
    if (error is StateError) {
      return 'Edit submission is unavailable because Supabase is not configured.';
    }
    return 'Could not submit this edit. Please try again.';
  }
}
