import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/supabase_tables.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/network/sync_queue_service.dart';
import '../../../shared/providers/connectivity_provider.dart';
import '../../../shared/providers/drift_db_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../domain/attendance_repository.dart';
import '../domain/attendance_session_model.dart';

const _uuid = Uuid();

final attendanceRepositoryProvider =
    Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(
    db: ref.watch(driftDbProvider),
    syncService: SyncQueueService(
      ref.watch(driftDbProvider),
      ref.watch(supabaseProvider),
    ),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AppDatabase _db;
  final SyncQueueService _syncService;
  final ConnectivityService _connectivityService;

  AttendanceRepositoryImpl({
    required AppDatabase db,
    required SyncQueueService syncService,
    required ConnectivityService connectivityService,
  })  : _db = db,
        _syncService = syncService,
        _connectivityService = connectivityService;

  @override
  Future<Result<AttendanceSessionModel>> createSession(
      AttendanceSessionModel session) async {
    try {
      await _db.insertSession(AttendanceSessionsCompanion(
        id: Value(session.id),
        courseId: Value(session.courseId),
        teacherId: Value(session.teacherId),
        date: Value(
            '${session.date.year}-${session.date.month.toString().padLeft(2, '0')}-${session.date.day.toString().padLeft(2, '0')}'),
        classNumber: Value(session.classNumber),
        topic: Value(session.topic),
        status: Value(session.status),
        isSynced: const Value(false),
        createdAt: Value(session.createdAt.toIso8601String()),
      ));

      await _syncService.addToSyncQueue(
        id: _uuid.v4(),
        tableName: SupabaseTables.attendanceSessions,
        recordId: session.id,
        operation: 'insert',
        payload: session.toSupabaseMap(),
      );

      return Success(session);
    } catch (e) {
      return Failure(DatabaseException(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveRecords(
      String sessionId, List<Map<String, dynamic>> records) async {
    try {
      final companions = records.map((r) {
        final recordId = r['id'] as String? ?? _uuid.v4();
        return AttendanceRecordsCompanion(
          id: Value(recordId),
          sessionId: Value(sessionId),
          studentId: Value(r['student_id'] as String),
          rollNumber: Value(r['roll_number'] as int),
          status: Value(r['status'] as String? ?? 'P'),
          comment: Value(r['comment'] as String?),
          markedBy: Value(r['marked_by'] as String? ?? 'manual'),
          timestamp: Value(DateTime.now().toIso8601String()),
        );
      }).toList();

      await _db.upsertRecords(companions);

      // Queue sync for each record
      for (final companion in companions) {
        final payload = {
          'id': companion.id.value,
          'session_id': sessionId,
          'student_id': companion.studentId.value,
          'roll_number': companion.rollNumber.value,
          'status': companion.status.value,
          'comment': companion.comment.value,
          'marked_by': companion.markedBy.value,
        };
        await _syncService.addToSyncQueue(
          id: _uuid.v4(),
          tableName: SupabaseTables.attendanceRecords,
          recordId: companion.id.value,
          operation: 'insert',
          payload: payload,
        );
      }

      if (_connectivityService.isOnline) {
        _syncService.processPendingQueue();
      }

      return const Success(null);
    } catch (e) {
      return Failure(DatabaseException(e.toString()));
    }
  }

  @override
  Future<Result<void>> submitSession(String sessionId) async {
    try {
      final session = await _db.getSessionById(sessionId);
      if (session == null) {
        return const Failure(DatabaseException('Session not found'));
      }

      await _db.updateSession(AttendanceSessionsCompanion(
        id: Value(sessionId),
        courseId: Value(session.courseId),
        teacherId: Value(session.teacherId),
        date: Value(session.date),
        classNumber: Value(session.classNumber),
        topic: Value(session.topic),
        status: const Value('submitted'),
        isSynced: const Value(false),
        createdAt: Value(session.createdAt),
      ));

      await _syncService.addToSyncQueue(
        id: _uuid.v4(),
        tableName: SupabaseTables.attendanceSessions,
        recordId: sessionId,
        operation: 'update',
        payload: {
          'id': sessionId,
          'status': 'submitted',
        },
      );

      if (_connectivityService.isOnline) {
        _syncService.processPendingQueue();
      }

      return const Success(null);
    } catch (e) {
      return Failure(DatabaseException(e.toString()));
    }
  }

  @override
  Stream<List<AttendanceSessionModel>> watchSessions(String courseId) {
    return _db.watchSessionsByCourse(courseId).map((sessions) => sessions
        .map((s) => AttendanceSessionModel(
              id: s.id,
              courseId: s.courseId,
              teacherId: s.teacherId,
              date: DateTime.tryParse(s.date) ?? DateTime.now(),
              classNumber: s.classNumber,
              topic: s.topic,
              status: s.status,
              isSynced: s.isSynced,
              createdAt:
                  DateTime.tryParse(s.createdAt) ?? DateTime.now(),
            ))
        .toList());
  }
}
