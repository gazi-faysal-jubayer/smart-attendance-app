import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand colors
  static const Color primary = Color(0xFF1A3A6B);      // KUET Navy Blue
  static const Color primaryDark = Color(0xFF0F2448);
  static const Color secondary = Color(0xFFC8960C);    // KUET Gold
  static const Color surface = Color(0xFFF4F6FA);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;

  // Semantic colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);

  // Attendance status colors
  static const Color statusPresent = Color(0xFF2E7D32);
  static const Color statusAbsent = Color(0xFFD32F2F);
  static const Color statusLate = Color(0xFFF9A825);
  static const Color statusExcused = Color(0xFF1565C0);

  // Attendance status background colors
  static const Color statusPresentBg = Colors.white;
  static const Color statusAbsentBg = Color(0xFFFFEBEE);
  static const Color statusLateBg = Color(0xFFFFFDE7);
  static const Color statusExcusedBg = Color(0xFFE3F2FD);

  // Excel / Report status cell colors
  static const Color cellPresent = Color(0xFFC8E6C9);
  static const Color cellAbsent = Color(0xFFFFCDD2);
  static const Color cellLate = Color(0xFFFFF9C4);
  static const Color cellExcused = Color(0xFFBBDEFB);

  // Neutral
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color altRow = Color(0xFFF5F5F5);

  // Course type gradients
  static const Color theoryGradientEnd = Color(0xFF0F2448);
  static const Color labGradientStart = Color(0xFF0D7377);
  static const Color labGradientEnd = Color(0xFF094B4E);
}
