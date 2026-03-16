import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────

class Courses extends Table {
  TextColumn get id => text()();
  TextColumn get teacherId => text()();
  TextColumn get courseCode => text()();
  TextColumn get courseName => text()();
  TextColumn get department => text()();
  IntColumn get semester => integer()();
  TextColumn get type => text()();
  IntColumn get studentCount => integer()();
  TextColumn get createdAt => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Students extends Table {
  TextColumn get id => text()();
  TextColumn get courseId => text().references(Courses, #id)();
  IntColumn get rollNumber => integer()();
  TextColumn get studentId => text().nullable()();
  TextColumn get name => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AttendanceSessions extends Table {
  TextColumn get id => text()();
  TextColumn get courseId => text().references(Courses, #id)();
  TextColumn get teacherId => text()();
  TextColumn get date => text()();
  IntColumn get classNumber => integer()();
  TextColumn get topic => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class AttendanceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId =>
      text().references(AttendanceSessions, #id)();
  TextColumn get studentId => text().references(Students, #id)();
  IntColumn get rollNumber => integer()();
  TextColumn get status => text().withDefault(const Constant('P'))();
  TextColumn get comment => text().nullable()();
  TextColumn get markedBy => text().withDefault(const Constant('manual'))();
  TextColumn get timestamp => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingSyncs extends Table {
  TextColumn get id => text()();
  TextColumn get syncTableName => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  TextColumn get createdAt => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database ─────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Courses,
  Students,
  AttendanceSessions,
  AttendanceRecords,
  PendingSyncs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Future migrations go here
        },
      );

  // ─── Course DAO methods ──────────────────────────────────────────

  Stream<List<Course>> watchAllCourses(String teacherId) {
    return (select(courses)
          ..where((c) => c.teacherId.equals(teacherId))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .watch();
  }

  Future<Course?> getCourseById(String id) {
    return (select(courses)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertCourse(CoursesCompanion course) {
    return into(courses).insert(course);
  }

  Future<bool> updateCourse(CoursesCompanion course) {
    return update(courses).replace(course);
  }

  Future<int> deleteCourseById(String id) {
    return (delete(courses)..where((c) => c.id.equals(id))).go();
  }

  // ─── Student DAO methods ─────────────────────────────────────────

  Stream<List<Student>> watchStudentsByCourse(String courseId) {
    return (select(students)
          ..where((s) => s.courseId.equals(courseId))
          ..orderBy([(s) => OrderingTerm.asc(s.rollNumber)]))
        .watch();
  }

  Future<List<Student>> getStudentsByCourse(String courseId) {
    return (select(students)
          ..where((s) => s.courseId.equals(courseId))
          ..orderBy([(s) => OrderingTerm.asc(s.rollNumber)]))
        .get();
  }

  Future<void> insertStudents(List<StudentsCompanion> studentList) async {
    await batch((b) => b.insertAll(students, studentList));
  }

  Future<bool> updateStudent(StudentsCompanion student) {
    return update(students).replace(student);
  }

  // ─── Attendance Session DAO methods ──────────────────────────────

  Stream<List<AttendanceSession>> watchSessionsByCourse(String courseId) {
    return (select(attendanceSessions)
          ..where((s) => s.courseId.equals(courseId))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .watch();
  }

  Future<AttendanceSession?> getSessionById(String id) {
    return (select(attendanceSessions)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int?> getNextClassNumber(String courseId) async {
    final query = selectOnly(attendanceSessions)
      ..addColumns([attendanceSessions.classNumber.max()])
      ..where(attendanceSessions.courseId.equals(courseId));
    final result = await query.getSingleOrNull();
    final maxNum =
        result?.read(attendanceSessions.classNumber.max());
    return (maxNum ?? 0) + 1;
  }

  Future<int> insertSession(AttendanceSessionsCompanion session) {
    return into(attendanceSessions).insert(session);
  }

  Future<bool> updateSession(AttendanceSessionsCompanion session) {
    return update(attendanceSessions).replace(session);
  }

  // ─── Attendance Record DAO methods ───────────────────────────────

  Stream<List<AttendanceRecord>> watchRecordsBySession(String sessionId) {
    return (select(attendanceRecords)
          ..where((r) => r.sessionId.equals(sessionId))
          ..orderBy([(r) => OrderingTerm.asc(r.rollNumber)]))
        .watch();
  }

  Future<List<AttendanceRecord>> getRecordsBySession(String sessionId) {
    return (select(attendanceRecords)
          ..where((r) => r.sessionId.equals(sessionId))
          ..orderBy([(r) => OrderingTerm.asc(r.rollNumber)]))
        .get();
  }

  Future<List<AttendanceRecord>> getRecordsByCourse(String courseId) async {
    final sessions = await (select(attendanceSessions)
          ..where((s) => s.courseId.equals(courseId)))
        .get();
    final sessionIds = sessions.map((s) => s.id).toList();
    if (sessionIds.isEmpty) return [];
    return (select(attendanceRecords)
          ..where((r) => r.sessionId.isIn(sessionIds)))
        .get();
  }

  Future<void> insertRecords(
      List<AttendanceRecordsCompanion> records) async {
    await batch((b) => b.insertAll(attendanceRecords, records));
  }

  Future<void> upsertRecords(
      List<AttendanceRecordsCompanion> records) async {
    await batch((b) {
      for (final record in records) {
        b.insert(attendanceRecords, record,
            mode: InsertMode.insertOrReplace);
      }
    });
  }

  // ─── Pending Sync DAO methods ────────────────────────────────────

  Stream<int> watchPendingSyncCount() {
    final count = pendingSyncs.id.count();
    final query = selectOnly(pendingSyncs)..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<List<PendingSync>> getPendingSyncs() {
    return (select(pendingSyncs)
          ..orderBy([(p) => OrderingTerm.asc(p.createdAt)])
          ..limit(50))
        .get();
  }

  Future<int> insertPendingSync(PendingSyncsCompanion sync) {
    return into(pendingSyncs).insert(sync);
  }

  Future<int> deletePendingSync(String id) {
    return (delete(pendingSyncs)..where((p) => p.id.equals(id))).go();
  }

  Future<void> incrementRetryCount(String id) async {
    final item =
        await (select(pendingSyncs)..where((p) => p.id.equals(id)))
            .getSingleOrNull();
    if (item != null) {
      await (update(pendingSyncs)..where((p) => p.id.equals(id))).write(
        PendingSyncsCompanion(retryCount: Value(item.retryCount + 1)),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'smart_attendance.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
