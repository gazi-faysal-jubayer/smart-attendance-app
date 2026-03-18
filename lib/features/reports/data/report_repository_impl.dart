import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/excel_generator.dart';
import '../../../shared/providers/drift_db_provider.dart';
import '../domain/report_model.dart';
import '../domain/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final db = ref.watch(driftDbProvider);
  return ReportRepositoryImpl(db);
});

class ReportRepositoryImpl implements ReportRepository {
  final AppDatabase _db;

  ReportRepositoryImpl(this._db);

  @override
  Future<Result<CourseReport>> generateCourseReport(String courseId) async {
    try {
      final course = await _db.getCourseById(courseId);
      if (course == null) {
        return const Failure(ValidationException('Course not found'));
      }

      final students = await _db.getStudentsByCourse(courseId);
      final sessions = await _db.watchSessionsByCourse(courseId).first;
      final records = await _db.getRecordsByCourse(courseId);

      int totalPresent = 0;
      int totalAbsent = 0;
      int totalLate = 0;
      int totalExcused = 0;

      final summaries = students.map((student) {
        final studentRecords = records
            .where((r) => r.studentId == student.id)
            .toList();
        final totalClasses = studentRecords.length;
        final present = studentRecords.where((r) => r.status == 'P').length;
        final absent = studentRecords.where((r) => r.status == 'A').length;
        final late = studentRecords.where((r) => r.status == 'LA').length;
        final excused = studentRecords.where((r) => r.status == 'E').length;

        totalPresent += present;
        totalAbsent += absent;
        totalLate += late;
        totalExcused += excused;

        return StudentAttendanceSummary(
          rollNumber: student.rollNumber,
          studentId: student.studentId,
          name: student.name,
          totalClasses: totalClasses,
          present: present,
          absent: absent,
          late: late,
          excused: excused,
        );
      }).toList()
        ..sort((a, b) => a.rollNumber.compareTo(b.rollNumber));

      return Success(CourseReport(
        summaries: summaries,
        totalSessions: sessions.length,
        totalPresent: totalPresent,
        totalAbsent: totalAbsent,
        totalLate: totalLate,
        totalExcused: totalExcused,
      ));
    } catch (e) {
      return Failure(DatabaseException(e.toString()));
    }
  }

  @override
  Future<Result<String>> exportCourseReport(String courseId) async {
    try {
      final course = await _db.getCourseById(courseId);
      if (course == null) {
        return const Failure(ValidationException('Course not found'));
      }

      final students = await _db.getStudentsByCourse(courseId);
      final sessions = await _db.watchSessionsByCourse(courseId).first;
      final records = await _db.getRecordsByCourse(courseId);

      final studentMaps = students
          .map((s) => {
                'id': s.id,
                'roll_number': s.rollNumber,
                'student_id': s.studentId,
                'name': s.name,
              })
          .toList();

      final sessionMaps = sessions.map((s) {
        final sessionRecords =
            records.where((r) => r.sessionId == s.id).toList();
        final present = sessionRecords.where((r) => r.status == 'P').length;
        final absent = sessionRecords.where((r) => r.status == 'A').length;
        final late = sessionRecords.where((r) => r.status == 'LA').length;

        return {
          'id': s.id,
          'class_number': s.classNumber,
          'date': s.date,
          'topic': s.topic,
          'total': sessionRecords.length,
          'present': present,
          'absent': absent,
          'late': late,
          'created_at': s.createdAt,
        };
      }).toList();

      final recordMaps = records
          .map((r) => {
                'id': r.id,
                'session_id': r.sessionId,
                'student_id': r.studentId,
                'roll_number': r.rollNumber,
                'status': r.status,
                'comment': r.comment,
                'marked_by': r.markedBy,
              })
          .toList();

      final file = await ExcelGenerator.buildAttendanceExcel(
        courseCode: course.courseCode,
        semester: course.semester,
        students: studentMaps,
        sessions: sessionMaps,
        records: recordMaps,
      );

      return Success(file.path);
    } catch (e) {
      return Failure(DatabaseException(e.toString()));
    }
  }
}
