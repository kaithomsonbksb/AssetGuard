/// job model
class job {
  final String jobId;
  final String siteName;
  final String assignedEngineer;
  final DateTime dueDate;
  final String status;

  job({
    required this.jobId,
    required this.siteName,
    required this.assignedEngineer,
    required this.dueDate,
    required this.status,
  });

  /// job --> map for database
  Map<String, dynamic> toMap() {
    return {
      'job_id': jobId,
      'site_name': siteName,
      'assigned_engineer': assignedEngineer,
      'due_date': dueDate.toIso8601String(),
      'status': status,
    };
  }

  /// create job instance from map database
  factory job.fromMap(Map<String, dynamic> map) {
    return job(
      jobId: map['job_id'] as String,
      siteName: map['site_name'] as String,
      assignedEngineer: map['assigned_engineer'] as String,
      dueDate: DateTime.parse(map['due_date'] as String),
      status: map['status'] as String,
    );
  }

  /// create copy of job with some fields replaced
  job copyWith({
    String? jobId,
    String? siteName,
    String? assignedEngineer,
    DateTime? dueDate,
    String? status,
  }) {
    return job(
      jobId: jobId ?? this.jobId,
      siteName: siteName ?? this.siteName,
      assignedEngineer: assignedEngineer ?? this.assignedEngineer,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }
}
