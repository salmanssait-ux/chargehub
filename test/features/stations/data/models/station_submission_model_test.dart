import 'package:chargebub/features/stations/data/models/station_submission_model.dart';
import 'package:chargebub/features/stations/domain/entities/station_submission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StationSubmissionModel.fromJson', () {
    test('maps submission fields and review status', () {
      final submittedAt = DateTime.utc(2026, 10, 7, 10);
      final submission = StationSubmissionModel.fromJson({
        'id': 'submission-id',
        'submitted_by': 'user-id',
        'name': 'ChargeHub Station',
        'operator_name': 'Network',
        'address': 'Main Road',
        'latitude': 19.07,
        'longitude': 72.87,
        'connector_types': ['CCS', 'Type 2'],
        'charger_count': 4,
        'power_kw': 120.0,
        'notes': 'Near the entrance',
        'status': 'approved',
        'admin_notes': 'Verified',
        'created_at': submittedAt.toIso8601String(),
        'reviewed_at': submittedAt.toIso8601String(),
        'reviewed_by': 'reviewer-id',
      }).submission;

      expect(submission.id, 'submission-id');
      expect(submission.submittedBy, 'user-id');
      expect(submission.operatorName, 'Network');
      expect(submission.connectorTypes, ['CCS', 'Type 2']);
      expect(submission.chargerCount, 4);
      expect(submission.status, StationSubmissionStatus.approved);
      expect(submission.createdAt.toUtc(), submittedAt);
      expect(submission.reviewedBy, 'reviewer-id');
    });

    test('maps pending and rejected statuses', () {
      expect(
        _submissionWithStatus('pending').status,
        StationSubmissionStatus.pending,
      );
      expect(
        _submissionWithStatus('rejected').status,
        StationSubmissionStatus.rejected,
      );
    });
  });
}

StationSubmission _submissionWithStatus(String status) {
  return StationSubmissionModel.fromJson({
    'id': 'submission-id',
    'submitted_by': 'user-id',
    'name': 'Station',
    'latitude': 19.07,
    'longitude': 72.87,
    'connector_types': <String>[],
    'charger_count': 1,
    'status': status,
    'created_at': DateTime.utc(2026).toIso8601String(),
  }).submission;
}
