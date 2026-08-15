import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/core/theme/app_colors.dart';

/// Typography definitions mapping Stitch Market Flow M3 specifications.
abstract final class AppTypography {
  static TextTheme createTextTheme(
      {required Color textColor, required Color secondaryTextColor}) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        height: 64 / 57,
        letterSpacing: -0.25,
        color: textColor,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        height: 52 / 45,
        letterSpacing: 0,
        color: textColor,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 44 / 36,
        letterSpacing: 0,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 40 / 32,
        letterSpacing: 0,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 36 / 28,
        letterSpacing: 0,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: 0,
        color: textColor,
      ),
      titleLarge: GoogleFonts.workSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 28 / 22,
        letterSpacing: 0,
        color: textColor,
      ),
      titleMedium: GoogleFonts.workSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 24 / 16,
        letterSpacing: 0.15,
        color: textColor,
      ),
      titleSmall: GoogleFonts.workSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        letterSpacing: 0.1,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.workSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        letterSpacing: 0.5,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.workSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        letterSpacing: 0.25,
        color: textColor,
      ),
      bodySmall: GoogleFonts.workSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        letterSpacing: 0.4,
        color: secondaryTextColor,
      ),
      labelLarge: GoogleFonts.workSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.1,
        color: textColor,
      ),
      labelMedium: GoogleFonts.workSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.5,
        color: secondaryTextColor,
      ),
      labelSmall: GoogleFonts.workSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 16 / 11,
        letterSpacing: 0.5,
        color: secondaryTextColor,
      ),
    );
  }

  static TextTheme get light => createTextTheme(
        textColor: AppColors.onSurface,
        secondaryTextColor: AppColors.onSurfaceVariant,
      );

  static TextTheme get dark => createTextTheme(
        textColor: AppColors.surface,
        secondaryTextColor: AppColors.surfaceDim,
      );
}
