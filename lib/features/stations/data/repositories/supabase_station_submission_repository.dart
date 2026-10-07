import '../../domain/entities/station_submission.dart';
import '../../domain/errors/station_submission_failure.dart';
import '../../domain/repositories/station_submission_repository.dart';
import '../datasources/supabase_station_submission_datasource.dart';

class SupabaseStationSubmissionRepository
    implements StationSubmissionRepository {
  SupabaseStationSubmissionRepository(this._dataSource);

  final SupabaseStationSubmissionDataSource _dataSource;

  @override
  Future<StationSubmission> submit(StationSubmissionDraft submission) async {
    if (submission.name.trim().isEmpty) {
      throw ArgumentError.value(submission.name, 'name', 'Name is required.');
    }
    if (!submission.latitude.isFinite ||
        submission.latitude < -90 ||
        submission.latitude > 90 ||
        !submission.longitude.isFinite ||
        submission.longitude < -180 ||
        submission.longitude > 180) {
      throw ArgumentError('Station coordinates are invalid.');
    }
    if (submission.chargerCount < 1 ||
        (submission.powerKw != null &&
            (!submission.powerKw!.isFinite || submission.powerKw! <= 0))) {
      throw ArgumentError('Station charger details are invalid.');
    }

    try {
      return await _dataSource.create(submission);
    } catch (error) {
      if (error is StationSubmissionFailure) rethrow;
      throw StationSubmissionFailure(
        stationSubmissionErrorMessage(error) ??
            'Could not submit this station. Please try again.',
      );
    }
  }

  @override
  Future<List<StationSubmission>> getMySubmissions() async {
    try {
      return await _dataSource.getMine();
    } catch (error) {
      if (error is StationSubmissionFailure) rethrow;
      throw StationSubmissionFailure(
        stationSubmissionErrorMessage(error) ??
            'Could not load your submissions. Please try again.',
      );
    }
  }
}
