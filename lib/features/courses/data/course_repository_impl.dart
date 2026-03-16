import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/supabase_tables.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/network/sync_queue_service.dart';
import '../../../core/utils/roll_generator.dart';
import '../../../shared/providers/connectivity_provider.dart';
import '../../../shared/providers/drift_db_provider.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../domain/course_model.dart';
import '../domain/course_repository.dart';

const _uuid = Uuid();

final courseRepositoryImplProvider = Provider<CourseRepositoryImpl>((ref) {
  return CourseRepositoryImpl(
    db: ref.watch(driftDbProvider),
    syncService: SyncQueueService(
      ref.watch(driftDbProvider),
      ref.watch(supabaseProvider),
    ),
    connectivityService: ref.watch(connectivityServiceProvider),
    supabase: ref.watch(supabaseProvider),
  );
});

class CourseRepositoryImpl implements CourseRepository {
  final AppDatabase _db;
  final SyncQueueService _syncService;
  final ConnectivityService _connectivityService;
  // ignore: unused_field
  final dynamic _supabase;

  CourseRepositoryImpl({
    required AppDatabase db,
    required SyncQueueService syncService,
    required ConnectivityService connectivityService,
    required dynamic supabase,
  })  : _db = db,
        _syncService = syncService,
        _connectivityService = connectivityService,
        _supabase = supabase;

  @override
  Stream<List<CourseModel>> watchCourses(String teacherId) {
    return _db.watchAllCourses(teacherId).map((courses) => courses
        .map((c) => CourseModel(
              id: c.id,
              teacherId: c.teacherId,
              courseCode: c.courseCode,
              courseName: c.courseName,
              department: c.department,
              semester: c.semester,
              type: c.type,
              studentCount: c.studentCount,
              createdAt: DateTime.tryParse(c.createdAt) ?? DateTime.now(),
              isSynced: c.isSynced,
            ))
        .toList());
  }

  @override
  Future<Result<CourseModel>> createCourse(CourseModel course) async {
    try {
      // 1. Insert course locally
      await _db.insertCourse(CoursesCompanion(
        id: Value(course.id),
        teacherId: Value(course.teacherId),
        courseCode: Value(course.courseCode),
        courseName: Value(course.courseName),
        department: Value(course.department),
        semester: Value(course.semester),
        type: Value(course.type),
        studentCount: Value(course.studentCount),
        createdAt: Value(course.createdAt.toIso8601String()),
        isSynced: const Value(false),
      ));

      // 2. Generate students locally
      final students = RollGenerator.generateStudents(
        courseId: course.id,
        count: course.studentCount,
      );
      await _db.insertStudents(students);

      // 3. Queue sync for course
      await _syncService.addToSyncQueue(
        id: _uuid.v4(),
        tableName: SupabaseTables.courses,
        recordId: course.id,
        operation: 'insert',
        payload: course.toSupabaseMap(),
      );

      // 4. Queue sync for students
      for (final student in students) {
        await _syncService.addToSyncQueue(
          id: _uuid.v4(),
          tableName: SupabaseTables.students,
          recordId: student.id.value,
          operation: 'insert',
          payload: {
            'id': student.id.value,
            'course_id': student.courseId.value,
            'roll_number': student.rollNumber.value,
            'student_id': null,
            'name': null,
          },
        );
      }

      // 5. Try immediate sync if online
      if (_connectivityService.isOnline) {
        _syncService.processPendingQueue();
      }

      return Success(course);
    } catch (e) {
      return Failure(DatabaseException(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteCourse(String id) async {
    try {
      await _db.deleteCourseById(id);

      await _syncService.addToSyncQueue(
        id: _uuid.v4(),
        tableName: SupabaseTables.courses,
        recordId: id,
        operation: 'delete',
        payload: {'id': id},
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
  Future<Result<CourseModel?>> getCourseById(String id) async {
    try {
      final course = await _db.getCourseById(id);
      if (course == null) return const Success(null);
      return Success(CourseModel(
        id: course.id,
        teacherId: course.teacherId,
        courseCode: course.courseCode,
        courseName: course.courseName,
        department: course.department,
        semester: course.semester,
        type: course.type,
        studentCount: course.studentCount,
        createdAt: DateTime.tryParse(course.createdAt) ?? DateTime.now(),
        isSynced: course.isSynced,
      ));
    } catch (e) {
      return Failure(DatabaseException(e.toString()));
    }
  }
}
