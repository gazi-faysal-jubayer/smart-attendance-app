import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/errors/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/report_model.dart';
import '../domain/report_provider.dart';
import '../data/report_repository_impl.dart';
import 'export_options_sheet.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final String courseId;

  const ReportScreen({super.key, required this.courseId});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  bool _exporting = false;

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    final repo = ref.read(reportRepositoryProvider);
    final result = await repo.exportCourseReport(widget.courseId);

    if (mounted) {
      result.when(
        success: (path) async {
          if (mounted) setState(() => _exporting = false);
          
          await Share.shareXFiles(
            [XFile(path)],
            text: 'Attendance Report (Excel)',
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report exported successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        failure: (e) {
          if (mounted) setState(() => _exporting = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Export failed: ${e.message}'),
                backgroundColor: AppColors.statusAbsent,
              ),
            );
          }
        },
      );
    } else {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(courseReportProvider(widget.courseId));

    return Scaffold(
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading report: $e'),
          ),
        ),
        data: (report) => _ReportBody(report: report),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exporting
            ? null
            : () => showModalBottomSheet(
                  context: context,
                  builder: (_) => ExportOptionsSheet(
                    onExport: _exportExcel,
                  ),
                ),
        icon: _exporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.download),
        label: Text(_exporting ? 'Exporting...' : 'Export Excel'),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final CourseReport report;

  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final total = report.totalPresent +
        report.totalAbsent +
        report.totalLate +
        report.totalExcused;

    if (total == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No attendance data yet.'),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Course Analytics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Overview',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 60,
                            sections: [
                              PieChartSectionData(
                                color: AppColors.statusPresent,
                                value: report.totalPresent.toDouble(),
                                title: '${(report.totalPresent / total * 100).round()}%',
                                titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                                radius: 25,
                              ),
                              PieChartSectionData(
                                color: AppColors.statusAbsent,
                                value: report.totalAbsent.toDouble(),
                                title: '${(report.totalAbsent / total * 100).round()}%',
                                titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                                radius: 25,
                              ),
                              PieChartSectionData(
                                color: AppColors.statusLate,
                                value: report.totalLate.toDouble(),
                                title: '${(report.totalLate / total * 100).round()}%',
                                titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                                radius: 25,
                              ),
                              if (report.totalExcused > 0)
                                PieChartSectionData(
                                  color: AppColors.statusExcused,
                                  value: report.totalExcused.toDouble(),
                                  title: '${(report.totalExcused / total * 100).round()}%',
                                  titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                  radius: 25,
                                ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${((report.totalPresent + report.totalLate) / total * 100).round()}%',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                            ),
                            Text(
                              'Attendance',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Legend('Present', AppColors.statusPresent,
                          report.totalPresent),
                      _Legend('Absent', AppColors.statusAbsent,
                          report.totalAbsent),
                      _Legend('Late', AppColors.statusLate,
                          report.totalLate),
                      _Legend('Excused', AppColors.statusExcused,
                          report.totalExcused),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Student Attendance Rates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final summary = report.summaries[index];
              final rate = summary.percentage / 100;
              return ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    '${summary.rollNumber}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  summary.name ?? 'Roll ${summary.rollNumber}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: summary.studentId != null &&
                        summary.studentId!.isNotEmpty
                    ? Text(summary.studentId!)
                    : null,
                trailing: SizedBox(
                  width: 120,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: rate,
                            backgroundColor: Colors.grey[200],
                            color: rate >= 0.75
                                ? AppColors.statusPresent
                                : rate >= 0.5
                                    ? AppColors.statusLate
                                    : AppColors.statusAbsent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${summary.percentage.round()}%',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: report.summaries.length,
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  final int count;

  const _Legend(this.label, this.color, this.count);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text('$label ($count)', style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
