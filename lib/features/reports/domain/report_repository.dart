import '../../../core/errors/failure.dart';
import 'report_model.dart';

abstract class ReportRepository {
  Future<Result<CourseReport>> generateCourseReport(String courseId);
  Future<Result<String>> exportCourseReport(String courseId);
}
