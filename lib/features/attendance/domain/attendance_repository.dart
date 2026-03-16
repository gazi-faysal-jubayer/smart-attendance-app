import '../../../core/errors/failure.dart';
import 'attendance_session_model.dart';

abstract class AttendanceRepository {
  Future<Result<AttendanceSessionModel>> createSession(
      AttendanceSessionModel session);
  Future<Result<void>> saveRecords(
      String sessionId, List<Map<String, dynamic>> records);
  Future<Result<void>> submitSession(String sessionId);
  Stream<List<AttendanceSessionModel>> watchSessions(String courseId);
}
