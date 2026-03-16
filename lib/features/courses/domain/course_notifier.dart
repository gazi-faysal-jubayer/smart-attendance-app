import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/drift_db_provider.dart';
import '../data/course_repository_impl.dart';
import 'course_model.dart';
import 'course_repository.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return ref.watch(courseRepositoryImplProvider);
});

final courseListProvider =
    AsyncNotifierProvider<CourseListNotifier, List<CourseModel>>(
        CourseListNotifier.new);

class CourseListNotifier extends AsyncNotifier<List<CourseModel>> {
  @override
  Future<List<CourseModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final db = ref.watch(driftDbProvider);

    // Watch Drift stream for reactive updates
    final sub = db.watchAllCourses(user.id).listen((driftCourses) {
      final models = driftCourses
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
          .toList();
      state = AsyncData(models);
    });

    ref.onDispose(() => sub.cancel());

    // Return initial from Drift
    final initial = await db.watchAllCourses(user.id).first;
    return initial
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
        .toList();
  }

  Future<void> createCourse(CourseModel course) async {
    final repo = ref.read(courseRepositoryProvider);
    await repo.createCourse(course);
    // Stream will auto-update
  }

  Future<void> deleteCourse(String id) async {
    final repo = ref.read(courseRepositoryProvider);
    await repo.deleteCourse(id);
  }
}
