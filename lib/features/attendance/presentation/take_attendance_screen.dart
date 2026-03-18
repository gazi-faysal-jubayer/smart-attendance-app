import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/drift_db_provider.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/roll_card.dart';
import 'package:drift/drift.dart' show Value;

class TakeAttendanceScreen extends ConsumerStatefulWidget {
  final String courseId;
  const TakeAttendanceScreen({super.key, required this.courseId});

  @override
  ConsumerState<TakeAttendanceScreen> createState() =>
      _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends ConsumerState<TakeAttendanceScreen> {
  final _topicController = TextEditingController();
  List<Student> _students = [];
  final Map<int, String> _statusMap = {};
  final Map<int, String> _commentMap = {};
  int _classNumber = 1;
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    final db = ref.read(driftDbProvider);

    // Get students
    final students = await db.watchStudentsByCourse(widget.courseId).first;

    // Calculate next class number
    final sessions = await db.watchSessionsByCourse(widget.courseId).first;

    setState(() {
      _students = students;
      _classNumber = sessions.length + 1;
      // Default all students to present
      for (final s in students) {
        _statusMap[s.rollNumber] = 'P';
      }
      _initialized = true;
    });
  }

  Future<void> _submitAttendance() async {
    if (_students.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final present = _statusMap.values.where((s) => s == 'P').length;
        final absent = _statusMap.values.where((s) => s == 'A').length;
        final late = _statusMap.values.where((s) => s == 'LA').length;
        final excused = _statusMap.values.where((s) => s == 'E').length;

        return AlertDialog(
          title: const Text('Submit Attendance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Class #$_classNumber',
                  style: Theme.of(ctx).textTheme.titleSmall),
              if (_topicController.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(_topicController.text,
                    style: Theme.of(ctx).textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CountChip('P', present, AppColors.statusPresent),
                  _CountChip('A', absent, AppColors.statusAbsent),
                  _CountChip('LA', late, AppColors.statusLate),
                  _CountChip('E', excused, AppColors.statusExcused),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'This action cannot be undone.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final db = ref.read(driftDbProvider);
      final sessionId = const Uuid().v4();
      final user = ref.read(currentUserProvider);

      // Create session
      await db.insertSession(AttendanceSessionsCompanion.insert(
        id: sessionId,
        courseId: widget.courseId,
        teacherId: user!.id,
        classNumber: _classNumber,
        date: AppDateUtils.formatDateForStorage(DateTime.now()),
        topic: Value(_topicController.text.isEmpty
            ? null
            : _topicController.text.trim()),
        status: const Value('submitted'),
        isSynced: const Value(false),
        createdAt: DateTime.now().toIso8601String(),
      ));

      // Create records
      final records = _students.map((student) {
        return AttendanceRecordsCompanion.insert(
          id: const Uuid().v4(),
          sessionId: sessionId,
          studentId: student.id,
          rollNumber: student.rollNumber,
          status: Value(_statusMap[student.rollNumber] ?? 'P'),
          comment: Value(_commentMap[student.rollNumber]),
          timestamp: DateTime.now().toIso8601String(),
        );
      }).toList();
      
      await db.insertRecords(records);

      if (mounted) {
        AppToast.show(context, 'Attendance submitted!', isSuccess: true);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _markAllAs(String status) {
    setState(() {
      for (final s in _students) {
        _statusMap[s.rollNumber] = status;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Preparing attendance...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final present = _statusMap.values.where((s) => s == 'P').length;
    final absent = _statusMap.values.where((s) => s == 'A').length;
    final late = _statusMap.values.where((s) => s == 'LA').length;
    final excused = _statusMap.values.where((s) => s == 'E').length;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F2448),
                      AppColors.primary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Class #$_classNumber',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                AppDateUtils.formatDate(DateTime.now()),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_students.length} students',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.more_vert_rounded,
                      color: Colors.white),
                ),
                onSelected: _markAllAs,
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                      value: 'P',
                      child: Text('Mark all Present')),
                  const PopupMenuItem(
                      value: 'A',
                      child: Text('Mark all Absent')),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ─── Topic Input ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _topicController,
                decoration: InputDecoration(
                  hintText: 'Topic / Lecture notes (optional)',
                  prefixIcon: const Icon(Icons.topic_outlined),
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color ??
                      Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: AppColors.cardBorder.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),
          ),

          // ─── Student Cards ─────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final student = _students[index];
                  return RollCard(
                    rollNumber: student.rollNumber,
                    studentId: student.studentId,
                    studentName: student.name,
                    currentStatus: _statusMap[student.rollNumber] ?? 'P',
                    comment: _commentMap[student.rollNumber],
                    onStatusChanged: (status) {
                      setState(() {
                        _statusMap[student.rollNumber] = status;
                      });
                    },
                    onCommentChanged: (comment) {
                      setState(() {
                        _commentMap[student.rollNumber] = comment;
                      });
                    },
                  );
                },
                childCount: _students.length,
              ),
            ),
          ),
        ],
      ),

      // ─── Bottom Action Bar ──────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Counts
            Expanded(
              child: Row(
                children: [
                  _CountChip('P', present, AppColors.statusPresent),
                  const SizedBox(width: 6),
                  _CountChip('A', absent, AppColors.statusAbsent),
                  const SizedBox(width: 6),
                  _CountChip('LA', late, AppColors.statusLate),
                  const SizedBox(width: 6),
                  _CountChip('E', excused, AppColors.statusExcused),
                ],
              ),
            ),
            // Submit button
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitAttendance,
              icon: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(_isSubmitting ? 'Saving...' : 'Submit'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
