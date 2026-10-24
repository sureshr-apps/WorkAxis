import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';

enum AppKpiIconPosition {
  topRight,
  bottomRight,
}

/// Canonical, reusable KPI Card template adhering strictly to the
/// Stitch design fidelity specification and M3 geometry decomposition.
///
/// Decomposition:
/// - **Top Row**: Title label on left, semantic 36x36 Icon Box on right (or top).
/// - **Middle Row**: High-contrast bold metric value, optional ratio total, and adjacent inline badge.
/// - **Bottom Row**: Status indicator dot/icon + metadata text label, or custom bottom widget.
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
    final iconBoxWidget = customIconBox ??
        (icon != null
            ? Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor ?? effectiveColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 17,
                    color: effectiveColor,
                  ),
                ),
              )
            : const SizedBox.shrink());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color(0x04000000),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (accentColor != null)
            Container(
              height: 3.0,
              width: double.infinity,
              color: accentColor,
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Title on the left, Icon Box on the right (if topRight)
                  Row(
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
                            color: const Color(0xFF475569),
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
                  ),

                  // Middle / Value Row: Big metric value + optional badge (+ icon if bottomRight and no footer)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              value,
                              style: GoogleFonts.inter(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                                letterSpacing: -1.0,
                                color: valueColor ?? const Color(0xFF0F172A),
                              ),
                            ),
                            if (total != null && total!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                total!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
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
                  ),

                  // Bottom Row: Custom widget or (Status indicator dot/icon + supporting text)
                  if (bottomWidget != null)
                    bottomWidget!
                  else if (footerText != null)
                    Row(
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
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
