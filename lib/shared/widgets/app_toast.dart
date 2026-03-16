import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppToast {
  AppToast._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    final color = isError
        ? AppColors.error
        : isSuccess
            ? AppColors.success
            : AppColors.primary;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
