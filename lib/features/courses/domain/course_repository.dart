import '../../../core/errors/failure.dart';
import 'course_model.dart';

abstract class CourseRepository {
  Stream<List<CourseModel>> watchCourses(String teacherId);
  Future<Result<CourseModel>> createCourse(CourseModel course);
  Future<Result<void>> deleteCourse(String id);
  Future<Result<CourseModel?>> getCourseById(String id);
}
