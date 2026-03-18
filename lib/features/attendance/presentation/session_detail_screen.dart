import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/providers/drift_db_provider.dart';

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
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── Header ───────────────────────────────────
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F2448), AppColors.primary],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (session != null) ...[
                              Text(
                                'Class #${session.classNumber}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _HeaderChip(
                                      Icons.calendar_today_rounded,
                                      AppDateUtils.formatDate(date)),
                                  if (session.topic != null &&
                                      session.topic!.isNotEmpty)
                                    _HeaderChip(Icons.topic_rounded,
                                        session.topic!),
                                ],
                              ),
                            ] else
                              Text(
                                'Session Detail',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Stat Cards ────────────────────────────────
              SliverToBoxAdapter(
                child: StreamBuilder<List<AttendanceRecord>>(
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
                    final excused =
                        records.where((r) => r.status == 'E').length;
                    final percentage = total > 0
                        ? ((present + late) / total * 100).round()
                        : 0;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        children: [
                          // Main percentage card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.1),
                                  AppColors.primary.withValues(alpha: 0.03),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Stack(
                                    children: [
                                      CircularProgressIndicator(
                                        value: total > 0
                                            ? (present + late) / total
                                            : 0,
                                        strokeWidth: 6,
                                        backgroundColor:
                                            Colors.grey.withValues(alpha: 0.2),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                AppColors.statusPresent),
                                      ),
                                      Center(
                                        child: Text(
                                          '$percentage%',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Attendance Rate',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$total students total',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Mini stat cards
                          Row(
                            children: [
                              _StatCard(
                                  'Present', present, AppColors.statusPresent),
                              const SizedBox(width: 8),
                              _StatCard(
                                  'Absent', absent, AppColors.statusAbsent),
                              const SizedBox(width: 8),
                              _StatCard('Late', late, AppColors.statusLate),
                              const SizedBox(width: 8),
                              _StatCard(
                                  'Excused', excused, AppColors.statusExcused),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ─── Filter Chips ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'P', 'A', 'LA', 'E']
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(
                                    f == 'All'
                                        ? 'All'
                                        : f == 'P'
                                            ? 'Present'
                                            : f == 'A'
                                                ? 'Absent'
                                                : f == 'LA'
                                                    ? 'Late'
                                                    : 'Excused',
                                  ),
                                  selected: _filter == f,
                                  selectedColor:
                                      AppColors.primary.withValues(alpha: 0.15),
                                  checkmarkColor: AppColors.primary,
                                  onSelected: (_) {
                                    setState(() => _filter = f);
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),

              // ─── Records List ──────────────────────────────
              StreamBuilder<List<AttendanceRecord>>(
                stream: db.watchRecordsBySession(widget.sessionId),
                builder: (context, snap) {
                  final records = (snap.data ?? [])
                      .where(
                          (r) => _filter == 'All' || r.status == _filter)
                      .toList();

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final record = records[index];
                        return _RecordTile(record: record);
                      },
                      childCount: records.length,
                    ),
                  );
                },
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        );
      },
    );
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

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final AttendanceRecord record;
  const _RecordTile({required this.record});

  Color get _statusColor => switch (record.status) {
        'P' => AppColors.statusPresent,
        'A' => AppColors.statusAbsent,
        'LA' => AppColors.statusLate,
        'E' => AppColors.statusExcused,
        _ => Colors.grey,
      };

  String get _statusLabel => switch (record.status) {
        'P' => 'Present',
        'A' => 'Absent',
        'LA' => 'Late',
        'E' => 'Excused',
        _ => record.status,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${record.rollNumber}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student #${record.rollNumber}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (record.comment != null && record.comment!.isNotEmpty)
                  Text(
                    record.comment!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500,
                        ),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
