import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/common_providers.dart';
import 'data/datasources/ocm_datasource.dart';
import 'data/datasources/osm_datasource.dart';
import 'data/datasources/supabase_approved_station_datasource.dart';
import 'data/datasources/supabase_station_correction_datasource.dart';
import 'data/datasources/supabase_station_submission_datasource.dart';
import 'data/datasources/zigwheels_datasource.dart';
import 'data/datasources/local_user_station_datasource.dart';
import 'data/datasources/supabase_station_edit_suggestion_datasource.dart';
import 'data/repositories/station_repository_impl.dart';
import 'data/repositories/supabase_station_submission_repository.dart';
import 'data/repositories/local_user_station_repository.dart';
import 'data/repositories/supabase_station_edit_suggestion_repository.dart';
import 'domain/repositories/station_edit_suggestion_repository.dart';
import 'domain/repositories/station_repository.dart';
import 'domain/repositories/station_submission_repository.dart';
import 'domain/repositories/user_station_repository.dart';

final ocmDataSourceProvider = Provider<OcmDataSource>((ref) {
  final client = ref.watch(httpClientProvider);
  return OcmDataSource(client);
});

final osmDataSourceProvider = Provider<OsmDataSource>((ref) {
  final client = ref.watch(httpClientProvider);
  return OsmDataSource(client);
});

final zigWheelsDataSourceProvider = Provider<ZigWheelsDataSource>((ref) {
  return const ZigWheelsDataSource();
});

final supabaseStationSubmissionDataSourceProvider =
    Provider<SupabaseStationSubmissionDataSource>((ref) {
      return SupabaseStationSubmissionDataSource(
        ref.watch(supabaseClientProvider),
      );
    });

final stationSubmissionRepositoryProvider =
    Provider<StationSubmissionRepository>((ref) {
      return SupabaseStationSubmissionRepository(
        ref.watch(supabaseStationSubmissionDataSourceProvider),
      );
    });

final supabaseApprovedStationDataSourceProvider =
    Provider<SupabaseApprovedStationDataSource>((ref) {
      return SupabaseApprovedStationDataSource(
        ref.watch(supabaseClientProvider),
      );
    });

final supabaseStationCorrectionDataSourceProvider =
    Provider<SupabaseStationCorrectionDataSource>((ref) {
      return SupabaseStationCorrectionDataSource(
        ref.watch(supabaseClientProvider),
      );
    });

// Kept for access to legacy SharedPreferences records; public feeds no longer read it.
final userStationRepositoryProvider = Provider<UserStationRepository>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  return LocalUserStationRepository(LocalUserStationDataSource(preferences));
});

final stationEditSuggestionRepositoryProvider =
    Provider<StationEditSuggestionRepository>((ref) {
      return SupabaseStationEditSuggestionRepository(
        SupabaseStationEditSuggestionDataSource(
          ref.watch(supabaseClientProvider),
        ),
      );
    });

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  final ocmDataSource = ref.watch(ocmDataSourceProvider);
  final osmDataSource = ref.watch(osmDataSourceProvider);
  final zigWheelsDataSource = ref.watch(zigWheelsDataSourceProvider);
  final approvedStationDataSource = ref.watch(
    supabaseApprovedStationDataSourceProvider,
  );
  final stationCorrectionDataSource = ref.watch(
    supabaseStationCorrectionDataSourceProvider,
  );

  return StationRepositoryImpl(
    ocmDataSource,
    osmDataSource,
    zigWheelsDataSource,
    approvedStationDataSource,
    stationCorrectionDataSource,
  );
});
