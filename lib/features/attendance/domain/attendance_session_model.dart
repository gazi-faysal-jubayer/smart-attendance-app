class AttendanceSessionModel {
  final String id;
  final String courseId;
  final String teacherId;
  final DateTime date;
  final int classNumber;
  final String? topic;
  final String status;
  final bool isSynced;
  final DateTime createdAt;

  const AttendanceSessionModel({
    required this.id,
    required this.courseId,
    required this.teacherId,
    required this.date,
    required this.classNumber,
    this.topic,
    this.status = 'draft',
    this.isSynced = false,
    required this.createdAt,
  });

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'course_id': courseId,
      'teacher_id': teacherId,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'class_number': classNumber,
      'topic': topic,
      'status': status,
    };
  }
}
