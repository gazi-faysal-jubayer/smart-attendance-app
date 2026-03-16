class CourseModel {
  final String id;
  final String teacherId;
  final String courseCode;
  final String courseName;
  final String department;
  final int semester;
  final String type;
  final int studentCount;
  final DateTime createdAt;
  final bool isSynced;

  const CourseModel({
    required this.id,
    required this.teacherId,
    required this.courseCode,
    required this.courseName,
    required this.department,
    required this.semester,
    required this.type,
    required this.studentCount,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'course_code': courseCode,
      'course_name': courseName,
      'department': department,
      'semester': semester,
      'type': type,
      'student_count': studentCount,
    };
  }

  CourseModel copyWith({
    String? id,
    String? teacherId,
    String? courseCode,
    String? courseName,
    String? department,
    int? semester,
    String? type,
    int? studentCount,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return CourseModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      type: type ?? this.type,
      studentCount: studentCount ?? this.studentCount,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
