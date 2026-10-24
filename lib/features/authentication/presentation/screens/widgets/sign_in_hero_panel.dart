import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';

/// Left hero showcase panel for Desktop viewports on the Sign-In screen.
/// Features high-contrast enterprise branding, topology highlight cards,
/// and live operational security trust markers.
class SignInHeroPanel extends StatelessWidget {
  const SignInHeroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF03142F), // Deep navy midnight
            Color(0xFF0A224E), // Rich enterprise cobalt
            Color(0xFF003893), // Royal blue accent
          ],
        ),
      ),
      child: Stack(
        children: [
          // Ambient decorative background mesh
          Positioned.fill(
            child: CustomPaint(
              painter: _HeroBackgroundPainter(),
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Brand Row
                  _buildBrandHeader(),

                  // Center Content: Headline + Subtitle + Feature Highlights
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPillBadge(),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Unified Operations &\nMulti-Branch Governance',
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.25,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Streamline workforce attendance, shift telemetry, and branch compliance across all your customer hubs in real time.',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFC3D2F7),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Feature Highlights Cards
                              _buildFeatureCard(
                                icon: Icons.storefront_outlined,
                                title: 'Multi-Branch Fleet Topology',
                                description:
                                    'Centralized roster synchronization and geofenced terminal check-ins across all locations.',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildFeatureCard(
                                icon: Icons.security_outlined,
                                title: 'Zero-Trust Scoped Access',
                                description:
                                    'Role-governed isolation from platform owners down to frontline operational workers.',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildFeatureCard(
                                icon: Icons.bolt_outlined,
                                title: 'Sub-Second Roster Telemetry',
                                description:
                                    'Live shift tracking, absence exception approvals, and immutable compliance audit trails.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Trust & Status Indicator
                  _buildFooterTrustIndicators(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                offset: Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.hub_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WorkAxis',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'ENTERPRISE PLATFORM',
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8DB6FF),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F326D),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFF26529A),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 14,
            color: Color(0xFF8DB6FF),
          ),
          const SizedBox(width: 6),
          Text(
            'OPERATIONS MANAGEMENT SYSTEM',
            style: GoogleFonts.robotoMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB4C5FF),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF8DB6FF),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFC3D2F7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterTrustIndicators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live system status indicator
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF34D399), // Emerald pulse
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x8034D399),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'System Status: All Services Operational (99.98% Uptime)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFC3D2F7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'SOC2 Type II Certified  •  256-Bit TLS  •  Zero-Trust Architecture',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8DA3D0),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Custom painter rendering ambient background geometry and soft grid lines.
class _HeroBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF0052D4).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    // Large ambient glow in top-right
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.15), 180, paint1);

    // Secondary ambient glow in bottom-left
    final paint2 = Paint()
      ..color = const Color(0xFF003893).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.85), 220, paint2);

    // Subtle decorative node lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // A few subtle connected dots
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (double x = spacing; x < size.width; x += spacing * 2) {
      for (double y = spacing; y < size.height; y += spacing * 2) {
        if (math.sin(x + y) > 0.4) {
          canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
