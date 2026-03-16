import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/providers/drift_db_provider.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class SessionHistoryScreen extends ConsumerWidget {
  final String courseId;

  const SessionHistoryScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(driftDbProvider);

    return StreamBuilder<List<AttendanceSession>>(
      stream: db.watchSessionsByCourse(courseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.event_note_outlined,
            message: 'No sessions yet.\nTap + to take attendance.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _SessionCard(
              session: session,
              courseId: courseId,
            );
          },
        );
      },
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final AttendanceSession session;
  final String courseId;

  const _SessionCard({
    required this.session,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(driftDbProvider);
    final date = DateTime.tryParse(session.date) ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () =>
            context.go('/courses/$courseId/sessions/${session.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date column
              Column(
                children: [
                  Text(
                    '${date.day}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    AppDateUtils.formatDateShort(date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Class #${session.classNumber}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (session.status == 'submitted')
                          const Icon(Icons.check_circle,
                              size: 16, color: AppColors.success)
                        else
                          const Icon(Icons.pending,
                              size: 16, color: Colors.amber),
                      ],
                    ),
                    if (session.topic != null &&
                        session.topic!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        session.topic!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Record counts
                    StreamBuilder<List<AttendanceRecord>>(
                      stream: db.watchRecordsBySession(session.id),
                      builder: (context, snap) {
                        final records = snap.data ?? [];
                        final present = records
                            .where((r) => r.status == 'P')
                            .length;
                        final absent = records
                            .where((r) => r.status == 'A')
                            .length;
                        final late = records
                            .where((r) => r.status == 'LA')
                            .length;
                        return Row(
                          children: [
                            _MiniChip('P: $present',
                                AppColors.statusPresent),
                            const SizedBox(width: 4),
                            _MiniChip(
                                'A: $absent', AppColors.statusAbsent),
                            const SizedBox(width: 4),
                            _MiniChip(
                                'LA: $late', AppColors.statusLate),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Sync icon
              Icon(
                session.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                size: 20,
                color: session.isSynced ? AppColors.success : Colors.amber,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
