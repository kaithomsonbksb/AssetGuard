/// Attachment model represents files attached to inspection items
class Attachment {
  final String attachmentId;
  final String inspectionId;
  final String filePath;
  final String fileType;
  final String syncState;

  Attachment({
    required this.attachmentId,
    required this.inspectionId,
    required this.filePath,
    required this.fileType,
    required this.syncState,
  });

  ///  Attachment instance --> map for database storage
  Map<String, dynamic> toMap() {
    return {
      'attachment_id': attachmentId,
      'inspection_id': inspectionId,
      'file_path': filePath,
      'file_type': fileType,
      'sync_state': syncState,
    };
  }

  /// create an Attachment instance from a Map retrieved from database
  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      attachmentId: map['attachment_id'] as String,
      inspectionId: map['inspection_id'] as String,
      filePath: map['file_path'] as String,
      fileType: map['file_type'] as String,
      syncState: map['sync_state'] as String,
    );
  }

  /// create a copy of Attachment with some fields replaced
  Attachment copyWith({
    String? attachmentId,
    String? inspectionId,
    String? filePath,
    String? fileType,
    String? syncState,
  }) {
    return Attachment(
      attachmentId: attachmentId ?? this.attachmentId,
      inspectionId: inspectionId ?? this.inspectionId,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      syncState: syncState ?? this.syncState,
    );
  }
}
