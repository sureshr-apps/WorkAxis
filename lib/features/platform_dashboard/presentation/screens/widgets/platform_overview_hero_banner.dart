import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';

/// Executive hero banner for the Platform Overview screen.
/// Features high-contrast deep navy styling, ambient illumination,
/// real-time platform telemetry indicators, and primary console actions.
class PlatformOverviewHeroBanner extends StatelessWidget {
  const PlatformOverviewHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    return Container(
      decoration: BoxDecoration(
        color: _Hero.navy,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
          color: _Hero.navyLine.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _Hero.shadowA,
            offset: Offset(0, 10),
            blurRadius: 28,
            spreadRadius: -4,
          ),
          BoxShadow(color: _Hero.shadowB, offset: Offset(0, 2), blurRadius: 8),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ambient background glow & grid
          Positioned.fill(
            child: CustomPaint(painter: _BannerBackgroundPainter()),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? AppSpacing.lg : AppSpacing.xxl,
              vertical: isCompact ? AppSpacing.lg : AppSpacing.xl,
            ),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderContent(context),
                      const SizedBox(height: AppSpacing.lg),
                      _buildActionButtons(context),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildHeaderContent(context)),
                      const SizedBox(width: AppSpacing.xl),
                      _buildActionButtons(context),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kicker & Telemetry Row
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _Hero.navyChip,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _Hero.navyChipLine, width: 1),
              ),
              child: Text(
                'PLATFORM ADMINISTRATION',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: _Hero.skyText,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Main Title
        Text(
          'Platform Overview',
          style:
              (context.isCompact
                      ? AppTypography.headlineLarge
                      : AppTypography.displayLarge)
                  .copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Subtitle
        Text(
          'System administration and multi-tenant organization monitoring',
          style: AppTypography.bodyMedium.copyWith(color: _Hero.slateText),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return AppButton.responsive(
      text: 'Add Organization',
      iconData: Icons.add_rounded,
      onPressed: () => context.push(AppRoutes.platformOrganizationsAdd),
    );
  }
}

class _BannerBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-right cobalt radial glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.6),
        radius: 0.95,
        colors: [
          _Hero.glowBlue.withValues(alpha: 0.28),
          _Hero.glowDeep.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    // Subtle bottom-left cyan accent glow
    final cyanPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, 0.9),
        radius: 0.7,
        colors: [_Hero.glowCyan.withValues(alpha: 0.14), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), cyanPaint);

    // Geometric micro grid lines
    final gridPaint = Paint()
      ..color = _Hero.navyLine.withValues(alpha: 0.22)
      ..strokeWidth = 0.8;

    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // High-tech decorative micro telemetry circles
    final dotPaint = Paint()
      ..color = _Hero.dot.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final cx = size.width - 50.0 - (i * 24.0);
      final cy = 28.0 + math.sin(i * 1.2) * 8.0;
      canvas.drawCircle(Offset(cx, cy), 2.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Banner-specific dark palette. The hero is the only dark surface in the
/// platform console, so these are intentionally not global tokens.
abstract final class _Hero {
  static const Color navy = Color(0xFF001738);
  static const Color navyLine = Color(0xFF1E3A66);
  static const Color navyChip = Color(0xFF0A2E5C);
  static const Color navyChipLine = Color(0xFF1E5296);
  static const Color skyText = Color(0xFF7DD3FC);
  static const Color slateText = Color(0xFF94A3B8);
  static const Color glowBlue = Color(0xFF0052CC);
  static const Color glowDeep = Color(0xFF003380);
  static const Color glowCyan = Color(0xFF0284C7);
  static const Color dot = Color(0xFF38BDF8);
  static const Color shadowA = Color(0x33000A1A);
  static const Color shadowB = Color(0x1F001738);
}
