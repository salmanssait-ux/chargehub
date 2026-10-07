import '../entities/station_submission.dart';

abstract class StationSubmissionRepository {
  Future<StationSubmission> submit(StationSubmissionDraft submission);

  Future<List<StationSubmission>> getMySubmissions();
}
