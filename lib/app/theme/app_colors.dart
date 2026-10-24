import 'package:flutter/material.dart';

/// Centralized color palette from the Operations Enterprise M3 design system.
abstract final class AppColors {
  // Brand & Primary
  static const Color primary = Color(0xFF004AC6);
  static const Color primaryDark = Color(0xFF003594);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD9E2FF);
  static const Color onPrimaryContainer = Color(0xFF001945);

  // Secondary
  static const Color secondary = Color(0xFF515F74);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD2E1FA);
  static const Color onSecondaryContainer = Color(0xFF556379);

  // Tertiary
  static const Color tertiary = Color(0xFF0E453F);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF2B5D56);
  static const Color onTertiaryContainer = Color(0xFFA0D4CB);

  // Surfaces & Backgrounds
  static const Color surface = Color(0xFFF8F9FC);
  static const Color surfaceDim = Color(0xFFD8DADD);
  static const Color surfaceBright = Color(0xFFF8F9FC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE7E8EB);
  static const Color surfaceContainerHighest = Color(0xFFE1E2E5);

  // Text & Content
  static const Color onSurface = Color(0xFF191C20);
  static const Color onSurfaceVariant = Color(0xFF43474E);
  static const Color textMuted = Color(0xFF737685);

  // Outlines & Borders
  static const Color outline = Color(0xFF737685);
  static const Color outlineVariant = Color(0xFFC3C6D6);
  static const Color outlineSubtle = Color(0xFFE2E5EB);

  // Operational Status Tokens
  // Active / Success
  static const Color statusActiveText = Color(0xFF0F8B4D);
  static const Color statusActiveContainer = Color(0xFFE6F7EE);
  static const Color statusActiveBorder = Color(0xFFA7F3D0);

  // Pending / Caution
  static const Color statusPendingText = Color(0xFFB26200);
  static const Color statusPendingContainer = Color(0xFFFFF4E5);
  static const Color statusPendingBorder = Color(0xFFFDE68A);

  // Urgent / Danger
  static const Color error = Color(0xFFBA1A1A);
  static const Color statusUrgentText = Color(0xFFBA1A1A);
  static const Color statusUrgentContainer = Color(0xFFFFDAD6);
  static const Color statusUrgentBorder = Color(0xFFFECACA);

  // Draft / Neutral / Disabled
  static const Color statusNeutralText = Color(0xFF565F6D);
  static const Color statusNeutralContainer = Color(0xFFEFF1F5);
  static const Color statusNeutralBorder = Color(0xFFE5E7EB);

  // Operational Status Aliases
  static const Color statusActive = statusActiveText;
  static const Color statusPending = statusPendingText;
  static const Color statusUrgent = statusUrgentText;
  static const Color statusNeutral = statusNeutralText;
}
