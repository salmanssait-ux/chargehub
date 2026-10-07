enum StationSubmissionStatus { pending, approved, rejected }

class StationSubmission {
  const StationSubmission({
    required this.id,
    required this.submittedBy,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.connectorTypes,
    required this.chargerCount,
    required this.status,
    required this.createdAt,
    this.operatorName,
    this.address,
    this.powerKw,
    this.notes,
    this.adminNotes,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String id;
  final String submittedBy;
  final String name;
  final String? operatorName;
  final String? address;
  final double latitude;
  final double longitude;
  final List<String> connectorTypes;
  final int chargerCount;
  final double? powerKw;
  final String? notes;
  final StationSubmissionStatus status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
}

class StationSubmissionDraft {
  const StationSubmissionDraft({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.connectorTypes,
    required this.chargerCount,
    this.operatorName,
    this.address,
    this.powerKw,
    this.notes,
  });

  final String id;
  final String name;
  final String? operatorName;
  final String? address;
  final double latitude;
  final double longitude;
  final List<String> connectorTypes;
  final int chargerCount;
  final double? powerKw;
  final String? notes;
}
