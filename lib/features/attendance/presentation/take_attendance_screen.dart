import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/drift_db_provider.dart';
import '../../../shared/widgets/roll_card.dart';
import '../data/attendance_repository_impl.dart';
import '../domain/attendance_notifier.dart';
import '../domain/attendance_session_model.dart';

class TakeAttendanceScreen extends ConsumerStatefulWidget {
  final String courseId;

  const TakeAttendanceScreen({super.key, required this.courseId});

  @override
  ConsumerState<TakeAttendanceScreen> createState() =>
      _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState
    extends ConsumerState<TakeAttendanceScreen> {
  bool _initialized = false;
  final _topicController = TextEditingController();

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    if (_initialized) return;
    _initialized = true;

    final db = ref.read(driftDbProvider);
    final students = await db.getStudentsByCourse(widget.courseId);
    await ref
        .read(attendanceNotifierProvider.notifier)
        .initSession(widget.courseId, students);
  }

  Future<void> _submitAttendance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Attendance'),
        content: const Text(
            'Are you sure you want to submit this attendance? This action cannot be undone.'),
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
      ),
    );

    if (confirmed != true || !mounted) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final notifier = ref.read(attendanceNotifierProvider.notifier);
    final attendanceState = ref.read(attendanceNotifierProvider);
    final sessionId = const Uuid().v4();

    notifier.setSessionId(sessionId);
    notifier.setTopic(_topicController.text);

    final repo = ref.read(attendanceRepositoryProvider);

    // Create session
    final session = AttendanceSessionModel(
      id: sessionId,
      courseId: widget.courseId,
      teacherId: user.id,
      date: DateTime.now(),
      classNumber: attendanceState.classNumber,
      topic: _topicController.text.isEmpty ? null : _topicController.text,
      status: 'submitted',
      createdAt: DateTime.now(),
    );

    await repo.createSession(session);

    // Save records
    final records = attendanceState.records.values
        .map((r) => {
              'id': const Uuid().v4(),
              'student_id': r.studentId,
              'roll_number': r.rollNumber,
              'status': r.status,
              'comment': r.comment,
              'marked_by': r.markedBy,
            })
        .toList();

    await repo.saveRecords(sessionId, records);
    await repo.submitSession(sessionId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeSession();

    final attendanceState = ref.watch(attendanceNotifierProvider);
    final notifier = ref.read(attendanceNotifierProvider.notifier);
    final today = AppDateUtils.formatDate(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('Class #${attendanceState.classNumber} - $today'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'all_p':
                  notifier.markAllPresent();
                case 'all_a':
                  notifier.markAllAbsent();
                case 'reset':
                  notifier.resetAll();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                  value: 'all_p', child: Text('Mark All Present')),
              const PopupMenuItem(
                  value: 'all_a', child: Text('Mark All Absent')),
              const PopupMenuItem(
                  value: 'reset', child: Text('Reset All')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Session info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Chip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(today),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    avatar: const Icon(Icons.class_, size: 16),
                    label: Text('Class #${attendanceState.classNumber}'),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _topicController,
                      decoration: InputDecoration(
                        hintText: 'Topic (optional)',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Attendance list
          Expanded(
            child: attendanceState.records.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: attendanceState.records.length,
                    itemBuilder: (context, index) {
                      final roll =
                          attendanceState.records.keys.toList()..sort();
                      final record =
                          attendanceState.records[roll[index]]!;

                      return RollCard(
                        rollNumber: record.rollNumber,
                        studentId: record.studentName != null
                            ? null
                            : null,
                        studentName: record.studentName,
                        currentStatus: record.status,
                        comment: record.comment,
                        onStatusChanged: (status) {
                          notifier.markStatus(
                              record.rollNumber, status);
                        },
                        onCommentChanged: (comment) {
                          notifier.addComment(
                              record.rollNumber, comment);
                        },
                      );
                    },
                  ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: const Border(
                top: BorderSide(color: AppColors.cardBorder),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  _CountChip(
                    label: 'P',
                    count: attendanceState.presentCount,
                    color: AppColors.statusPresent,
                  ),
                  const SizedBox(width: 8),
                  _CountChip(
                    label: 'A',
                    count: attendanceState.absentCount,
                    color: AppColors.statusAbsent,
                  ),
                  const SizedBox(width: 8),
                  _CountChip(
                    label: 'LA',
                    count: attendanceState.lateCount,
                    color: AppColors.statusLate,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: attendanceState.records.isEmpty
                        ? null
                        : _submitAttendance,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
