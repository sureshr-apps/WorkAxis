import 'package:flutter/material.dart';

/// Market Flow M3 Color Palette tokens.
abstract final class AppColors {
  // Primary (Forest Green)
  static const Color primary = Color(0xFF002114);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF003925);
  static const Color onPrimaryContainer = Color(0xFF71A489);
  static const Color primaryFixed = Color(0xFFB9EED1);
  static const Color primaryFixedDim = Color(0xFF9ED2B5);
  static const Color surfaceTint = Color(0xFF376851);

  // Secondary (Clementine)
  static const Color secondary = Color(0xFF7F5600);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFDC56D);
  static const Color onSecondaryContainer = Color(0xFF775000);
  static const Color secondaryFixed = Color(0xFFFFDDAF);
  static const Color secondaryFixedDim = Color(0xFFF4BD65);

  // Tertiary (Pomegranate)
  static const Color tertiary = Color(0xFF420002);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF6A0006);
  static const Color onTertiaryContainer = Color(0xFFF96D61);
  static const Color tertiaryFixed = Color(0xFFFFDAD6);
  static const Color tertiaryFixedDim = Color(0xFFFFB4AB);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Surfaces (Light)
  static const Color surface = Color(0xFFFBF8FF);
  static const Color surfaceBright = Color(0xFFFBF8FF);
  static const Color surfaceDim = Color(0xFFD5D8F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF4F2FF);
  static const Color surfaceContainer = Color(0xFFEDECFF);
  static const Color surfaceContainerHigh = Color(0xFFE5E6FF);
  static const Color surfaceContainerHighest = Color(0xFFDEE0FF);
  static const Color surfaceVariant = Color(0xFFDEE0FF);

  // Surfaces (Dark)
  static const Color darkBackground = Color(0xFF161A32);
  static const Color darkSurface = Color(0xFF161A32);
  static const Color darkSurfaceContainerLowest = Color(0xFF0D1024);
  static const Color darkSurfaceContainerLow = Color(0xFF14172E);
  static const Color darkSurfaceContainer = Color(0xFF1A1D36);
  static const Color darkSurfaceContainerHigh = Color(0xFF212440);
  static const Color darkSurfaceContainerHighest = Color(0xFF282C4B);

  // Neutrals / Typography
  static const Color onSurface = Color(0xFF161A32);
  static const Color onSurfaceVariant = Color(0xFF414943);
  static const Color inverseSurface = Color(0xFF2B2F48);
  static const Color inverseOnSurface = Color(0xFFF0EFFF);
  static const Color inversePrimary = Color(0xFF9ED2B5);

  static const Color outline = Color(0xFF717973);
  static const Color outlineVariant = Color(0xFFC0C9C1);

  // Semantic Status Tokens
  static const Color statusActive = Color(0xFF2C694E);
  static const Color statusRelieved = Color(0xFF95D4B3);
  static const Color statusAbsent = Color(0xFFBA1A1A);
  static const Color statusPending = Color(0xFF7F5600);
  static const Color statusWarning = Color(0xFFF9AD00);
  static const Color statusDisabled = Color(0xFF707973);
  static const Color statusInfo = Color(0xFF404943);
}
