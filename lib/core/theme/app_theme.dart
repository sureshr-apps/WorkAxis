import 'package:flutter/material.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/theme/app_typography.dart';

/// Custom theme extension for operational status colors defined in Market Flow M3.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.active,
    required this.relieved,
    required this.absent,
    required this.pending,
    required this.disabled,
    required this.warning,
    required this.info,
  });

  final Color active;
  final Color relieved;
  final Color absent;
  final Color pending;
  final Color disabled;
  final Color warning;
  final Color info;

  @override
  StatusColors copyWith({
    Color? active,
    Color? relieved,
    Color? absent,
    Color? pending,
    Color? disabled,
    Color? warning,
    Color? info,
  }) {
    return StatusColors(
      active: active ?? this.active,
      relieved: relieved ?? this.relieved,
      absent: absent ?? this.absent,
      pending: pending ?? this.pending,
      disabled: disabled ?? this.disabled,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      active: Color.lerp(active, other.active, t) ?? active,
      relieved: Color.lerp(relieved, other.relieved, t) ?? relieved,
      absent: Color.lerp(absent, other.absent, t) ?? absent,
      pending: Color.lerp(pending, other.pending, t) ?? pending,
      disabled: Color.lerp(disabled, other.disabled, t) ?? disabled,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
    );
  }

  static const light = StatusColors(
    active: AppColors.statusActive,
    relieved: AppColors.statusRelieved,
    absent: AppColors.statusAbsent,
    pending: AppColors.statusPending,
    disabled: AppColors.statusDisabled,
    warning: AppColors.statusWarning,
    info: AppColors.statusInfo,
  );

  static const dark = StatusColors(
    active: Color(0xFF4E9A75),
    relieved: Color(0xFFAFE0CA),
    absent: Color(0xFFFF6B6B),
    pending: Color(0xFFFFB84D),
    disabled: Color(0xFF8F9893),
    warning: Color(0xFFFFD166),
    info: Color(0xFFA0A8A3),
  );
}

extension StatusColorsExtension on BuildContext {
  StatusColors get statusColors =>
      Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
}

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: AppTypography.light,
      extensions: const [StatusColors.light],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderDefault,
          side: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
          shape:
              const RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
          elevation: 1,
          textStyle: AppTypography.light.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
          side: const BorderSide(color: AppColors.outline, width: 1),
          shape:
              const RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
          textStyle: AppTypography.light.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize:
              const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
          textStyle: AppTypography.light.labelLarge,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant, width: 1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.defaultRadius),
            topRight: Radius.circular(AppRadius.defaultRadius),
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant, width: 1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.defaultRadius),
            topRight: Radius.circular(AppRadius.defaultRadius),
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.defaultRadius),
            topRight: Radius.circular(AppRadius.defaultRadius),
          ),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.defaultRadius),
            topRight: Radius.circular(AppRadius.defaultRadius),
          ),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.defaultRadius),
            topRight: Radius.circular(AppRadius.defaultRadius),
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF9ED2B5),
      onPrimary: Color(0xFF003925),
      primaryContainer: Color(0xFF0F5238),
      onPrimaryContainer: Color(0xFFB9EED1),
      secondary: Color(0xFFFDC56D),
      onSecondary: Color(0xFF422B00),
      secondaryContainer: Color(0xFF614000),
      onSecondaryContainer: Color(0xFFFFDDAF),
      tertiary: Color(0xFFFFB4AB),
      onTertiary: Color(0xFF6A0006),
      tertiaryContainer: Color(0xFF95000D),
      onTertiaryContainer: Color(0xFFFFDAD6),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColors.darkSurface,
      onSurface: Color(0xFFE5E6FF),
      onSurfaceVariant: Color(0xFFC0C9C1),
      outline: Color(0xFF8B938D),
      outlineVariant: Color(0xFF404943),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: AppTypography.dark,
      extensions: const [StatusColors.dark],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Color(0xFFE5E6FF),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkSurfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderDefault,
          side: BorderSide(color: Color(0xFF404943), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9ED2B5),
          foregroundColor: const Color(0xFF003925),
          minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
          shape:
              const RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
          elevation: 1,
          textStyle: AppTypography.dark.labelLarge,
        ),
      ),
    );
  }
}
