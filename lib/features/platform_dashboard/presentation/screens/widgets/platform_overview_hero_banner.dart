import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';

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
        color: const Color(0xFF001738),
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
          color: const Color(0xFF1E3A66).withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000A1A),
            offset: Offset(0, 10),
            blurRadius: 28,
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Color(0x1F001738),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ambient background glow & grid
          Positioned.fill(
            child: CustomPaint(
              painter: _BannerBackgroundPainter(),
            ),
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
                color: const Color(0xFF0A2E5C),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color(0xFF1E5296),
                  width: 1,
                ),
              ),
              child: Text(
                'PLATFORM ADMINISTRATION',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF7DD3FC),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Main Title
        Text(
          'Platform Overview',
          style: GoogleFonts.inter(
            fontSize: context.isCompact ? 24 : 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.6,
            height: 1.15,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Subtitle
        Text(
          'System administration and multi-tenant organization monitoring',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF94A3B8),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isCompact = context.isCompact;
    return ElevatedButton.icon(
      onPressed: () => context.push(AppRoutes.platformOrganizationsAdd),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Add Organization'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        minimumSize: Size(
          isCompact ? double.infinity : 0,
          AppSpacing.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedSm,
        ),
      ),
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
          const Color(0xFF0052CC).withValues(alpha: 0.28),
          const Color(0xFF003380).withValues(alpha: 0.12),
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
        colors: [
          const Color(0xFF0284C7).withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), cyanPaint);

    // Geometric micro grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E3A66).withValues(alpha: 0.22)
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
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
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
