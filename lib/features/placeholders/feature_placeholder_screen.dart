import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';

/// High-fidelity screen for platform console settings, environment configuration,
/// and structured module management.
class FeaturePlaceholderScreen extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;

  const FeaturePlaceholderScreen({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final accessContext = context.watch<AccessController>().accessContext;
    final activeBranch = context.watch<BranchContextController>().activeBranch;
    final user = accessContext?.user;
    final roleName = user?.role.displayName ?? 'Platform Operator';
    final isCompact = context.isCompact;

    final isSettings = title.toLowerCase().contains('setting');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  AppPageHeader(
                    eyebrow: isSettings ? 'Console Configuration' : 'Platform Module',
                    title: title,
                    subtitle: description ??
                        (isSettings
                            ? 'Configure environment parameters, security controls, and enterprise fleet telemetry across India.'
                            : '$title parameters and operational status for WorkAxis.'),
                    action: isSettings
                        ? AppButton.secondary(
                            text: 'Export System Audit',
                            iconData: Icons.download_outlined,
                            isFullWidth: false,
                            onPressed: () {},
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (isSettings) ...[
                    // Telemetry KPI Row
                    ResponsiveKpiSection(
                      cardHeight: 120,
                      cards: [
                        AppKpiCard(
                          title: 'Fleet Deployment',
                          value: 'INDIA',
                          accentColor: const Color(0xFF003366),
                          icon: Icons.public_outlined,
                          iconColor: AppColors.primary,
                          iconBgColor: AppColors.primaryContainer,
                          inlineBadge: AppKpiCard.badge(
                            'Active',
                            backgroundColor: const Color(0xFFDCFCE7),
                            textColor: const Color(0xFF15803D),
                            icon: Icons.check_circle_outline,
                          ),
                          footerDotColor: AppColors.statusActive,
                          footerText: 'IN-CENTRAL-01 (Mumbai Hub)',
                        ),
                        AppKpiCard(
                          title: 'Multi-Tenant Security',
                          value: 'AES-256',
                          valueColor: const Color(0xFF15803D),
                          accentColor: const Color(0xFF16A34A),
                          inlineBadge: AppKpiCard.badge(
                            'Enforced',
                            backgroundColor: const Color(0xFFDCFCE7),
                            textColor: const Color(0xFF15803D),
                            icon: Icons.lock_outline,
                          ),
                          icon: Icons.security_outlined,
                          iconColor: const Color(0xFF16A34A),
                          iconBgColor: const Color(0xFFDCFCE7),
                          footerDotColor: AppColors.statusActive,
                          footerText: 'End-to-end database encryption',
                        ),
                        AppKpiCard(
                          title: 'Console Engine',
                          value: 'v3.4.1',
                          accentColor: const Color(0xFF0284C7),
                          icon: Icons.dns_outlined,
                          iconColor: const Color(0xFF0284C7),
                          iconBgColor: const Color(0xFFE0F2FE),
                          footerIcon: const Icon(
                            Icons.speed_outlined,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          footerText: 'Platform Core Online',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Configuration Panels (2-Column Grid on Desktop)
                    if (!isCompact)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildConfigurationPanel(
                              title: 'Platform Environment',
                              subtitle:
                                  'Core deployment region, network routing, and database persistency.',
                              icon: Icons.cloud_outlined,
                              items: const [
                                _ConfigItem(
                                  label: 'Platform Fleet Region',
                                  value: 'India Fleet (IN-CENTRAL)',
                                  isCode: false,
                                ),
                                _ConfigItem(
                                  label: 'Database Persistence',
                                  value: 'PostgreSQL + Cloud Firestore Hybrid',
                                  isCode: false,
                                ),
                                _ConfigItem(
                                  label: 'Platform Architecture',
                                  value: 'WorkAxis Multi-Tenant Engine v3.4.1',
                                  isCode: true,
                                ),
                                _ConfigItem(
                                  label: 'Audit Log Retention',
                                  value: '365 Days Cryptographic Storage',
                                  isCode: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: _buildConfigurationPanel(
                              title: 'Security & Identity Governance',
                              subtitle:
                                  'Authentication standards, role bindings, and operator sessions.',
                              icon: Icons.shield_outlined,
                              items: [
                                const _ConfigItem(
                                  label: 'Authentication Mode',
                                  value: 'Identifier + Password (Email / Username / Phone)',
                                  isCode: false,
                                ),
                                const _ConfigItem(
                                  label: 'Single Sign-On (SSO)',
                                  value: 'Enterprise Directory SSO Ready',
                                  isCode: false,
                                ),
                                _ConfigItem(
                                  label: 'Active Console Operator',
                                  value: '${user?.name ?? 'Alex Vance'} ($roleName)',
                                  isCode: false,
                                ),
                                const _ConfigItem(
                                  label: 'Voluntary Password Change',
                                  value: 'Permitted in profile settings',
                                  isCode: false,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildConfigurationPanel(
                            title: 'Platform Environment',
                            subtitle:
                                'Core deployment region, network routing, and database persistency.',
                            icon: Icons.cloud_outlined,
                            items: const [
                              _ConfigItem(
                                label: 'Platform Fleet Region',
                                value: 'India Fleet (IN-CENTRAL)',
                                isCode: false,
                              ),
                              _ConfigItem(
                                label: 'Database Persistence',
                                value: 'PostgreSQL + Cloud Firestore Hybrid',
                                isCode: false,
                              ),
                              _ConfigItem(
                                label: 'Platform Architecture',
                                value: 'WorkAxis Multi-Tenant Engine v3.4.1',
                                isCode: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildConfigurationPanel(
                            title: 'Security & Identity Governance',
                            subtitle:
                                'Authentication standards, role bindings, and operator sessions.',
                            icon: Icons.shield_outlined,
                            items: [
                              const _ConfigItem(
                                label: 'Authentication Mode',
                                value: 'Identifier + Password',
                                isCode: false,
                              ),
                              _ConfigItem(
                                label: 'Active Console Operator',
                                value: '${user?.name ?? 'Alex Vance'} ($roleName)',
                                isCode: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                  ] else ...[
                    // Generic Module Card with Executive Styling
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.outlineSubtle),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            offset: Offset(0, 2),
                            blurRadius: 8,
                          ),
                          BoxShadow(
                            color: Color(0x04000000),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 32, color: AppColors.primary),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            description ??
                                '$title operational module is active in the current platform release.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Wrap(
                            spacing: AppSpacing.md,
                            children: [
                              Chip(
                                avatar: const Icon(Icons.badge_outlined, size: 16),
                                label: Text(roleName),
                                backgroundColor: AppColors.surfaceContainerLow,
                              ),
                              if (activeBranch != null)
                                Chip(
                                  avatar: const Icon(Icons.storefront_outlined, size: 16),
                                  label: Text(
                                      '${activeBranch.branchName} (${activeBranch.branchCode})'),
                                  backgroundColor: AppColors.surfaceContainerLow,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildConfigurationPanel({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<_ConfigItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x04000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              item.label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: item.isCode
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.value,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  )
                                : Text(
                                    item.value,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigItem {
  final String label;
  final String value;
  final bool isCode;

  const _ConfigItem({
    required this.label,
    required this.value,
    required this.isCode,
  });
}
