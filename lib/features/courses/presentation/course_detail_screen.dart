import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/errors/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/drift_db_provider.dart';
import '../../../shared/widgets/app_toast.dart';
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
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading course...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error loading course',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('$e',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
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
              expandedHeight: 200,
              pinned: true,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                onPressed: () => context.go('/dashboard'),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white),
                  ),
                  onPressed: () => _confirmDelete(context, course),
                ),
                const SizedBox(width: 8),
              ],
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
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            course.courseCode,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            course.courseName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _HeaderChip(
                                  Icons.school_rounded, course.department),
                              _HeaderChip(Icons.calendar_month_rounded,
                                  'Sem ${course.semester}'),
                              _HeaderChip(Icons.people_outline_rounded,
                                  '${course.studentCount} students'),
                              _HeaderChip(
                                  isLab
                                      ? Icons.science_rounded
                                      : Icons.menu_book_rounded,
                                  isLab ? 'Lab' : 'Theory'),
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
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.go('/courses/${widget.courseId}/attendance/new'),
        icon: const Icon(Icons.checklist_rounded),
        label: const Text('Take Attendance'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CourseModel course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
            'Are you sure you want to delete "${course.courseCode} - ${course.courseName}"? This will also delete all attendance records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(courseListProvider.notifier).deleteCourse(course.id);
      if (mounted) {
        AppToast.show(context, 'Course deleted', isSuccess: true);
        context.go('/dashboard');
      }
    }
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Students Tab ─────────────────────────────────────────────────────
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No students',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey.shade600,
                        )),
                const SizedBox(height: 4),
                Text('Students will appear after course creation',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ??
                    Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.cardBorder.withValues(alpha: 0.3),
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${student.rollNumber}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                title: Text(
                  student.name ?? 'Student ${student.rollNumber}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                subtitle: student.studentId != null
                    ? Text(
                        student.studentId!,
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : null,
                trailing: IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 20, color: Colors.grey.shade500),
                  onPressed: () => _editStudent(context, ref, student),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editStudent(BuildContext context, WidgetRef ref, Student student) {
    final nameController = TextEditingController(text: student.name);
    final idController = TextEditingController(text: student.studentId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit Student #${student.rollNumber}',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final db = ref.read(driftDbProvider);
                await db.updateStudent(StudentsCompanion(
                  id: Value(student.id),
                  courseId: Value(student.courseId),
                  rollNumber: Value(student.rollNumber),
                  studentId: Value(
                      idController.text.isEmpty ? null : idController.text),
                  name: Value(
                      nameController.text.isEmpty ? null : nameController.text),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
