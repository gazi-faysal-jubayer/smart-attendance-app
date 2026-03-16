import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/providers/drift_db_provider.dart';
import '../../../shared/widgets/roll_card.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String courseId;

  const SessionDetailScreen({
    super.key,
    required this.sessionId,
    required this.courseId,
  });

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState
    extends ConsumerState<SessionDetailScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(driftDbProvider);

    return FutureBuilder<AttendanceSession?>(
      future: db.getSessionById(widget.sessionId),
      builder: (context, sessionSnap) {
        final session = sessionSnap.data;
        final date =
            DateTime.tryParse(session?.date ?? '') ?? DateTime.now();

        return Scaffold(
          appBar: AppBar(
            title: Text(session != null
                ? 'Class #${session.classNumber} - ${AppDateUtils.formatDate(date)}'
                : 'Session Detail'),
          ),
          body: Column(
            children: [
              // Stats header
              StreamBuilder<List<AttendanceRecord>>(
                stream: db.watchRecordsBySession(widget.sessionId),
                builder: (context, snap) {
                  final records = snap.data ?? [];
                  final total = records.length;
                  final present =
                      records.where((r) => r.status == 'P').length;
                  final absent =
                      records.where((r) => r.status == 'A').length;
                  final late =
                      records.where((r) => r.status == 'LA').length;

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _StatCard('Total', total, Colors.grey),
                        _StatCard('Present', present, AppColors.statusPresent),
                        _StatCard('Absent', absent, AppColors.statusAbsent),
                        _StatCard('Late', late, AppColors.statusLate),
                      ],
                    ),
                  );
                },
              ),

              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'P', 'A', 'LA', 'E']
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(f),
                                selected: _filter == f,
                                onSelected: (_) {
                                  setState(() => _filter = f);
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),

              // Records list
              Expanded(
                child: StreamBuilder<List<AttendanceRecord>>(
                  stream: db.watchRecordsBySession(widget.sessionId),
                  builder: (context, snap) {
                    final records = (snap.data ?? []).where((r) =>
                        _filter == 'All' || r.status == _filter);

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records.elementAt(index);
                        return RollCard(
                          rollNumber: record.rollNumber,
                          currentStatus: record.status,
                          comment: record.comment,
                          onStatusChanged: (_) {},
                          onCommentChanged: (_) {},
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                '$value',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
