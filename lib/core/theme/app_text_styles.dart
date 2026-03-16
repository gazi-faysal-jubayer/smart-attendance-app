import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings — Poppins
  static TextStyle get displayLarge => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleSmall => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  // Body — Inter
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  // Labels — Inter
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );
}
