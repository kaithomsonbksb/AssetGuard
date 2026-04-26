/// InspectionItem model -> single item inspected within job
class InspectionItem {
  final String inspectionId;
  final String jobId;
  final String notes;
  final String result;
  final DateTime updatedAt;
  final String syncState;

  InspectionItem({
    required this.inspectionId,
    required this.jobId,
    required this.notes,
    required this.result,
    required this.updatedAt,
    required this.syncState,
  });

  ///  InspectionItem instance --> map for database storage
  Map<String, dynamic> toMap() {
    return {
      'inspection_id': inspectionId,
      'job_id': jobId,
      'notes': notes,
      'result': result,
      'updated_at': updatedAt.toIso8601String(),
      'sync_state': syncState,
    };
  }

  /// create an InspectionItem instance --> Map retrieved from database
  factory InspectionItem.fromMap(Map<String, dynamic> map) {
    return InspectionItem(
      inspectionId: map['inspection_id'] as String,
      jobId: map['job_id'] as String,
      notes: map['notes'] as String,
      result: map['result'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncState: map['sync_state'] as String,
    );
  }

  /// create a copy of InspectionItem with some fields replaced
  InspectionItem copyWith({
    String? inspectionId,
    String? jobId,
    String? notes,
    String? result,
    DateTime? updatedAt,
    String? syncState,
  }) {
    return InspectionItem(
      inspectionId: inspectionId ?? this.inspectionId,
      jobId: jobId ?? this.jobId,
      notes: notes ?? this.notes,
      result: result ?? this.result,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
    );
  }
}
