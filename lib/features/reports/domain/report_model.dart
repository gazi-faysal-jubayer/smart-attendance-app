class StudentAttendanceSummary {
  final int rollNumber;
  final String? studentId;
  final String? name;
  final int totalClasses;
  final int present;
  final int absent;
  final int late;
  final int excused;

  const StudentAttendanceSummary({
    required this.rollNumber,
    this.studentId,
    this.name,
    required this.totalClasses,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
  });

  double get percentage =>
      totalClasses == 0 ? 0.0 : ((present + late) / totalClasses) * 100;
}

class CourseReport {
  final List<StudentAttendanceSummary> summaries;
  final int totalSessions;
  final int totalPresent;
  final int totalAbsent;
  final int totalLate;
  final int totalExcused;

  const CourseReport({
    required this.summaries,
    required this.totalSessions,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLate,
    required this.totalExcused,
  });
}
