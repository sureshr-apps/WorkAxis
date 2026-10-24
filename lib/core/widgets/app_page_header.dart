import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';

/// Canonical, responsive Page Header template.
///
/// Implements the approved Stitch enterprise header specification:
/// - Eyebrow tag: Small, bold uppercase tracking tag (e.g., 'PLATFORM ADMINISTRATION').
/// - Title: Adaptive typography (24px on compact smartphone, 32px on tablet & desktop).
/// - Subtitle: Optional explanatory text in `AppColors.onSurfaceVariant`.
/// - Action(s): Adaptive placement:
///   - Tablet / Desktop: Placed inline on the right of the header row.
///   - Smartphone (<600dp): Placed below the header, spanning 100% width for touch ergonomics.
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? action;
  final List<Widget>? actions;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.action,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    final effectiveActions = <Widget>[?action, ...?actions];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null && eyebrow!.isNotEmpty) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: isCompact ? 24 : 32,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.5,
                      color: AppColors.onSurface,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isCompact && effectiveActions.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.lg),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: effectiveActions
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: w,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        if (isCompact && effectiveActions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: effectiveActions
                .map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: w,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
