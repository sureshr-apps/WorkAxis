import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';

/// Small caption style used for labels inside license cards.
TextStyle get licenseLabelStyle =>
    AppTypography.labelSmall.copyWith(color: AppColors.secondary);

/// Supporting body text inside license cards.
TextStyle get licenseBodyStyle =>
    AppTypography.labelSmall.copyWith(height: 1.4);

/// Elevated white container used by every license section.
class LicensePanel extends StatelessWidget {
  const LicensePanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      border: Border.all(color: AppColors.outlineSubtle),
      borderRadius: AppSpacing.roundedMd,
      boxShadow: AppShadows.card,
    ),
    child: child,
  );
}

/// Tinted inset card for a single figure.
class LicenseInsetCard extends StatelessWidget {
  const LicenseInsetCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      border: Border.all(color: AppColors.outlineVariant),
      borderRadius: AppSpacing.roundedSm,
    ),
    child: child,
  );
}

/// Uppercase section title.
class LicenseSectionHeading extends StatelessWidget {
  const LicenseSectionHeading({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: AppTypography.labelSmall.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: AppColors.secondary,
    ),
  );
}

/// Compact outlined badge, optionally with an icon or monospaced text.
class LicenseSmallBadge extends StatelessWidget {
  const LicenseSmallBadge({
    super.key,
    required this.label,
    this.icon,
    this.mono = false,
  });

  final String label;
  final IconData? icon;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final base = mono ? AppTypography.labelMono : AppTypography.labelSmall;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: AppSpacing.roundedXs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: base.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
