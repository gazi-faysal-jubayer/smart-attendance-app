import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusBadge({
    super.key,
    required this.status,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label) = _getStatusInfo(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, String) _getStatusInfo(String status) {
    return switch (status) {
      'P' => (AppColors.statusPresent, 'Present'),
      'A' => (AppColors.statusAbsent, 'Absent'),
      'LA' => (AppColors.statusLate, 'Late'),
      'E' => (AppColors.statusExcused, 'Excused'),
      _ => (Colors.grey, status),
    };
  }
}
