class SupabaseTables {
  SupabaseTables._();

  // Table names
  static const String profiles = 'profiles';
  static const String courses = 'courses';
  static const String students = 'students';
  static const String attendanceSessions = 'attendance_sessions';
  static const String attendanceRecords = 'attendance_records';

  // Profiles columns
  static const String colId = 'id';
  static const String colFullName = 'full_name';
  static const String colEmployeeId = 'employee_id';
  static const String colDepartment = 'department';
  static const String colRole = 'role';
  static const String colCreatedAt = 'created_at';

  // Courses columns
  static const String colTeacherId = 'teacher_id';
  static const String colCourseCode = 'course_code';
  static const String colCourseName = 'course_name';
  static const String colSemester = 'semester';
  static const String colType = 'type';
  static const String colStudentCount = 'student_count';

  // Students columns
  static const String colCourseId = 'course_id';
  static const String colRollNumber = 'roll_number';
  static const String colStudentId = 'student_id';
  static const String colName = 'name';

  // Attendance sessions columns
  static const String colDate = 'date';
  static const String colClassNumber = 'class_number';
  static const String colTopic = 'topic';
  static const String colStatus = 'status';

  // Attendance records columns
  static const String colSessionId = 'session_id';
  static const String colComment = 'comment';
  static const String colMarkedBy = 'marked_by';
  static const String colTimestamp = 'timestamp';
}
