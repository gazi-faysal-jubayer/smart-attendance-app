import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RollCard extends StatelessWidget {
  final int rollNumber;
  final String? studentId;
  final String? studentName;
  final String currentStatus;
  final String? comment;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onCommentChanged;

  const RollCard({
    super.key,
    required this.rollNumber,
    this.studentId,
    this.studentName,
    required this.currentStatus,
    this.comment,
    required this.onStatusChanged,
    required this.onCommentChanged,
  });

  Color get _backgroundColor => switch (currentStatus) {
        'A' => AppColors.statusAbsentBg,
        'LA' => AppColors.statusLateBg,
        'E' => AppColors.statusExcusedBg,
        _ => AppColors.statusPresentBg,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showCommentSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Roll badge
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rollNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Student info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (studentId != null)
                      Text(
                        studentId!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    Text(
                      studentName ?? 'Student $rollNumber',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (comment != null && comment!.isNotEmpty)
                      Text(
                        comment!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                      ),
                  ],
                ),
              ),

              // Status toggle buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: ['P', 'A', 'LA', 'E']
                    .map((s) => _StatusButton(
                          label: s,
                          isSelected: currentStatus == s,
                          color: _statusColor(s),
                          onTap: () {
                            if (currentStatus == s) {
                              onStatusChanged('P');
                            } else {
                              onStatusChanged(s);
                            }
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'P' => AppColors.statusPresent,
        'A' => AppColors.statusAbsent,
        'LA' => AppColors.statusLate,
        'E' => AppColors.statusExcused,
        _ => Colors.grey,
      };

  void _showCommentSheet(BuildContext context) {
    final controller = TextEditingController(text: comment);
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
              'Comment for Student $rollNumber',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                onCommentChanged(controller.text);
                Navigator.pop(ctx);
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

class _StatusButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey[400]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
