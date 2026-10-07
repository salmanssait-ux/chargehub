import 'dart:async';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/station_submission.dart';
import '../../domain/errors/station_submission_failure.dart';
import '../models/station_submission_model.dart';

class SupabaseStationSubmissionDataSource {
  SupabaseStationSubmissionDataSource(this._client);

  static const _requestTimeout = Duration(seconds: 15);
  final SupabaseClient? _client;

  Future<StationSubmission> create(StationSubmissionDraft draft) async {
    final client = _requireClient();
    final user = await _authenticatedUser(client);
    final values = {
      'id': draft.id,
      'submitted_by': user.id,
      'name': draft.name.trim(),
      'operator_name': _optional(draft.operatorName),
      'address': _optional(draft.address),
      'latitude': draft.latitude,
      'longitude': draft.longitude,
      'connector_types': draft.connectorTypes,
      'charger_count': draft.chargerCount,
      'power_kw': draft.powerKw,
      'notes': _optional(draft.notes),
    };

    Map<String, dynamic> row;
    try {
      row = await client
          .from('station_submissions')
          .insert(values)
          .select()
          .single()
          .timeout(_requestTimeout);
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
      final existing = await client
          .from('station_submissions')
          .select()
          .eq('id', draft.id)
          .eq('submitted_by', user.id)
          .maybeSingle()
          .timeout(_requestTimeout);
      if (existing == null) rethrow;
      row = existing;
    }

    return StationSubmissionModel.fromJson(row).submission;
  }

  Future<List<StationSubmission>> getMine() async {
    final client = _requireClient();
    final user = await _authenticatedUser(client);
    final rows = await client
        .from('station_submissions')
        .select()
        .eq('submitted_by', user.id)
        .order('created_at', ascending: false)
        .timeout(_requestTimeout);

    return rows
        .map((row) => StationSubmissionModel.fromJson(row).submission)
        .toList();
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw const StationSubmissionFailure(
        'Add SUPABASE_URL and SUPABASE_ANON_KEY to the local .env file.',
      );
    }
    return client;
  }

  Future<User> _authenticatedUser(SupabaseClient client) async {
    final currentUser = client.auth.currentUser;
    if (currentUser != null) return currentUser;

    final response = await client.auth.signInAnonymously().timeout(
      _requestTimeout,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Could not create an authenticated session.');
    }
    return user;
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

String? stationSubmissionErrorMessage(Object error) {
  if (error is StationSubmissionFailure) return error.message;
  if (error is TimeoutException) {
    return 'The request took too long. Check your connection and try again.';
  }
  if (error is ClientException) {
    return 'You appear to be offline. Reconnect and try again.';
  }
  if (error is AuthRetryableFetchException) {
    return 'Could not connect to Supabase. Check your internet connection and retry.';
  }
  if (error is AuthException) {
    return 'Could not start a secure submission session. Please try again.';
  }
  if (error is PostgrestException) {
    return 'The server could not accept this station. Check the details and try again.';
  }
  return null;
}
