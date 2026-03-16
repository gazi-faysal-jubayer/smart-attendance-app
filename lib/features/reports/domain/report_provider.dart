import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failure.dart';
import 'report_model.dart';
import '../data/report_repository_impl.dart';

final courseReportProvider = FutureProvider.family<CourseReport, String>((ref, courseId) async {
  final repo = ref.watch(reportRepositoryProvider);
  final result = await repo.generateCourseReport(courseId);
  return result.when(
    success: (data) => data,
    failure: (e) => throw e,
  );
});
