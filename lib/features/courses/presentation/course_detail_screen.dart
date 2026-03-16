import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/drift_db_provider.dart';
import '../domain/course_model.dart';
import '../domain/course_notifier.dart';
import '../../attendance/presentation/session_history_screen.dart';
import '../../reports/presentation/report_screen.dart';

final currentCourseProvider =
    FutureProvider.family<CourseModel?, String>((ref, courseId) async {
  final repo = ref.watch(courseRepositoryProvider);
  final result = await repo.getCourseById(courseId);
  return result.dataOrNull;
});

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() =>
      _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(currentCourseProvider(widget.courseId));

    return courseAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (course) {
        if (course == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Course not found')),
          );
        }
        return _buildContent(context, course);
      },
    );
  }

  Widget _buildContent(BuildContext context, CourseModel course) {
    final isLab = course.type == 'lab';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isLab
                          ? [
                              AppColors.labGradientStart,
                              AppColors.labGradientEnd,
                            ]
                          : [AppColors.primary, AppColors.theoryGradientEnd],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            course.courseCode,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            course.courseName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _HeaderChip(course.department),
                              _HeaderChip('Sem ${course.semester}'),
                              _HeaderChip(
                                  '${course.studentCount} students'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: 'Sessions'),
                  Tab(text: 'Students'),
                  Tab(text: 'Reports'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            SessionHistoryScreen(courseId: widget.courseId),
            _StudentsTab(courseId: widget.courseId),
            ReportScreen(courseId: widget.courseId),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.go('/courses/${widget.courseId}/attendance/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  const _HeaderChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class _StudentsTab extends ConsumerWidget {
  final String courseId;
  const _StudentsTab({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(driftDbProvider);

    return StreamBuilder<List<Student>>(
      stream: db.watchStudentsByCourse(courseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data ?? [];
        if (students.isEmpty) {
          return const Center(child: Text('No students'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  '${student.rollNumber}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              title: Text(student.name ?? 'Student ${student.rollNumber}'),
              subtitle:
                  student.studentId != null ? Text(student.studentId!) : null,
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _editStudent(context, ref, student),
              ),
            );
          },
        );
      },
    );
  }

  void _editStudent(
      BuildContext context, WidgetRef ref, Student student) {
    final nameController = TextEditingController(text: student.name);
    final idController =
        TextEditingController(text: student.studentId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit Student ${student.rollNumber}',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: idController,
              decoration:
                  const InputDecoration(labelText: 'Student ID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: 'Student Name'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final db = ref.read(driftDbProvider);
                await db.updateStudent(StudentsCompanion(
                  id: Value(student.id),
                  courseId: Value(student.courseId),
                  rollNumber: Value(student.rollNumber),
                  studentId: Value(idController.text.isEmpty
                      ? null
                      : idController.text),
                  name: Value(nameController.text.isEmpty
                      ? null
                      : nameController.text),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
