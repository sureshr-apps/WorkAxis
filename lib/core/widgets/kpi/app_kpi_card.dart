import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';

enum AppKpiIconPosition { topRight, bottomRight }

/// Canonical, reusable KPI Card template adhering strictly to the
/// Stitch design fidelity specification and M3 geometry decomposition.
///
/// Decomposition:
/// - **Top Row**: Title label on left, semantic 36x36 Icon Box on right (or top).
/// - **Middle Row**: High-contrast bold metric value, optional ratio total, and adjacent inline badge.
/// - **Bottom Row**: Status indicator dot/icon + metadata text label, or custom bottom widget.
///
/// The card has a minimum height ([minHeight]) rather than a fixed one, so it
/// grows with larger text scales instead of overflowing. The metric value scales
/// down to fit narrow cards.
class AppKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? total;
  final Color? valueColor;
  final Widget? inlineBadge;
  final IconData? icon;
  final Widget? customIconBox;
  final Color? iconColor;
  final Color? iconBgColor;
  final Widget? footerIcon;
  final Color? footerDotColor;
  final String? footerText;
  final Widget? bottomWidget;
  final Color? accentColor;
  final AppKpiIconPosition iconPosition;

  const AppKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.total,
    this.valueColor,
    this.inlineBadge,
    this.icon,
    this.customIconBox,
    this.iconColor,
    this.iconBgColor,
    this.footerIcon,
    this.footerDotColor,
    this.footerText,
    this.bottomWidget,
    this.accentColor,
    this.iconPosition = AppKpiIconPosition.bottomRight,
  });

  /// Minimum card height. The card grows beyond this with larger text scales.
  static const double minHeight = 96;

  static const double _accentHeight = 3.0;

  /// Factory helper for creating an inline badge widget matching Stitch geometry.
  static Widget badge(
    String text, {
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: textColor ?? AppColors.primary),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: textColor ?? AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = iconColor ?? accentColor ?? AppColors.primary;
    final iconBoxWidget =
        customIconBox ??
        (icon != null
            ? Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor ?? effectiveColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(icon, size: 17, color: effectiveColor),
                ),
              )
            : const SizedBox.shrink());

    return Container(
      constraints: const BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.kpiBorder, width: 1.0),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        // Pass the parent's constraints through so the content column fills a
        // tight height (carousel) or grows from the min height (grids).
        fit: StackFit.passthrough,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm + 4 + (accentColor != null ? _accentHeight : 0),
              AppSpacing.md,
              AppSpacing.sm + 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTopRow(iconBoxWidget),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: _buildValueRow(iconBoxWidget),
                ),
                ?_buildBottomRow(),
              ],
            ),
          ),
          if (accentColor != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _accentHeight,
              child: ColoredBox(color: accentColor!),
            ),
        ],
      ),
    );
  }

  Widget _buildTopRow(Widget iconBoxWidget) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: AppColors.kpiLabel,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (iconPosition == AppKpiIconPosition.topRight) ...[
          const SizedBox(width: AppSpacing.xs),
          iconBoxWidget,
        ],
      ],
    );
  }

  Widget _buildValueRow(Widget iconBoxWidget) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -1.0,
                      color: valueColor ?? AppColors.kpiValue,
                    ),
                  ),
                ),
              ),
              if (total != null && total!.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  total!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kpiMuted,
                  ),
                ),
              ],
              if (inlineBadge != null) ...[
                const SizedBox(width: AppSpacing.xs + 2),
                Flexible(child: inlineBadge!),
              ],
            ],
          ),
        ),
        if (iconPosition == AppKpiIconPosition.bottomRight) ...[
          const SizedBox(width: AppSpacing.xs),
          iconBoxWidget,
        ],
      ],
    );
  }

  /// Custom widget or (status indicator dot/icon + supporting text).
  Widget? _buildBottomRow() {
    if (bottomWidget != null) return bottomWidget;
    if (footerText == null) return null;
    return Row(
      children: [
        if (footerDotColor != null) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: footerDotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ] else if (footerIcon != null) ...[
          footerIcon!,
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            footerText!,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.kpiMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
