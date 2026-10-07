import '../../domain/entities/station_submission.dart';

class StationSubmissionModel {
  const StationSubmissionModel(this.submission);

  final StationSubmission submission;

  factory StationSubmissionModel.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status']) {
      'approved' => StationSubmissionStatus.approved,
      'rejected' => StationSubmissionStatus.rejected,
      _ => StationSubmissionStatus.pending,
    };

    return StationSubmissionModel(
      StationSubmission(
        id: json['id'] as String,
        submittedBy: json['submitted_by'] as String,
        name: json['name'] as String,
        operatorName: json['operator_name'] as String?,
        address: json['address'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        connectorTypes: (json['connector_types'] as List<dynamic>? ?? const [])
            .map((value) => value.toString())
            .toList(),
        chargerCount: (json['charger_count'] as num).toInt(),
        powerKw: (json['power_kw'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        status: status,
        adminNotes: json['admin_notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        reviewedAt: (json['reviewed_at'] as String?) == null
            ? null
            : DateTime.parse(json['reviewed_at'] as String).toLocal(),
        reviewedBy: json['reviewed_by'] as String?,
      ),
    );
  }
}
