import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/drift_db_provider.dart';
import 'attendance_record_model.dart';

class AttendanceState {
  final Map<int, AttendanceRecordDraft> records;
  final String? sessionId;
  final int classNumber;
  final String? topic;

  const AttendanceState({
    this.records = const {},
    this.sessionId,
    this.classNumber = 1,
    this.topic,
  });

  AttendanceState copyWith({
    Map<int, AttendanceRecordDraft>? records,
    String? sessionId,
    int? classNumber,
    String? topic,
  }) {
    return AttendanceState(
      records: records ?? this.records,
      sessionId: sessionId ?? this.sessionId,
      classNumber: classNumber ?? this.classNumber,
      topic: topic ?? this.topic,
    );
  }

  int get presentCount =>
      records.values.where((r) => r.status == 'P').length;
  int get absentCount =>
      records.values.where((r) => r.status == 'A').length;
  int get lateCount =>
      records.values.where((r) => r.status == 'LA').length;
  int get excusedCount =>
      records.values.where((r) => r.status == 'E').length;
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AppDatabase _db;

  AttendanceNotifier(this._db) : super(const AttendanceState());

  Future<void> initSession(String courseId,
      List<Student> students) async {
    final classNum = await _db.getNextClassNumber(courseId) ?? 1;

    final records = <int, AttendanceRecordDraft>{};
    for (final student in students) {
      records[student.rollNumber] = AttendanceRecordDraft(
        rollNumber: student.rollNumber,
        studentId: student.id,
        studentName: student.name,
        status: 'P',
      );
    }

    state = AttendanceState(
      records: records,
      classNumber: classNum,
    );
  }

  void markStatus(int rollNumber, String status, {String? markedBy}) {
    final current = state.records[rollNumber];
    if (current == null) return;

    final updated = Map<int, AttendanceRecordDraft>.from(state.records);
    updated[rollNumber] = current.copyWith(
      status: status,
      markedBy: markedBy ?? 'manual',
    );
    state = state.copyWith(records: updated);
  }

  void addComment(int rollNumber, String comment) {
    final current = state.records[rollNumber];
    if (current == null) return;

    final updated = Map<int, AttendanceRecordDraft>.from(state.records);
    updated[rollNumber] = current.copyWith(comment: comment);
    state = state.copyWith(records: updated);
  }

  void markAllPresent() {
    final updated = state.records.map((k, v) =>
        MapEntry(k, v.copyWith(status: 'P')));
    state = state.copyWith(records: updated);
  }

  void markAllAbsent() {
    final updated = state.records.map((k, v) =>
        MapEntry(k, v.copyWith(status: 'A')));
    state = state.copyWith(records: updated);
  }

  void resetAll() {
    final updated = state.records.map((k, v) =>
        MapEntry(k, v.copyWith(status: 'P', comment: null)));
    state = state.copyWith(records: updated);
  }

  void setTopic(String topic) {
    state = state.copyWith(topic: topic);
  }

  void setSessionId(String id) {
    state = state.copyWith(sessionId: id);
  }
}

final attendanceNotifierProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier(ref.watch(driftDbProvider));
});
