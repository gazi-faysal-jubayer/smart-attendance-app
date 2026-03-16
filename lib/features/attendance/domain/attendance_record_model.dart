class AttendanceRecordDraft {
  final int rollNumber;
  final String studentId;
  final String? studentName;
  final String status;
  final String? comment;
  final String markedBy;

  const AttendanceRecordDraft({
    required this.rollNumber,
    required this.studentId,
    this.studentName,
    this.status = 'P',
    this.comment,
    this.markedBy = 'manual',
  });

  AttendanceRecordDraft copyWith({
    int? rollNumber,
    String? studentId,
    String? studentName,
    String? status,
    String? comment,
    String? markedBy,
  }) {
    return AttendanceRecordDraft(
      rollNumber: rollNumber ?? this.rollNumber,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      status: status ?? this.status,
      comment: comment ?? this.comment,
      markedBy: markedBy ?? this.markedBy,
    );
  }
}
