import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class RollGenerator {
  RollGenerator._();

  static const _uuid = Uuid();

  static List<StudentsCompanion> generateStudents({
    required String courseId,
    required int count,
  }) {
    return List.generate(count, (index) {
      return StudentsCompanion(
        id: Value(_uuid.v4()),
        courseId: Value(courseId),
        rollNumber: Value(index + 1),
        studentId: const Value.absent(),
        name: const Value.absent(),
      );
    });
  }
}
