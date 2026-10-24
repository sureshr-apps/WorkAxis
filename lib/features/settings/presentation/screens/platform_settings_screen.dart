import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';

class PlatformSettingsScreen extends StatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  State<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends State<PlatformSettingsScreen> {
  final _sessionTimeoutController = TextEditingController(text: '60');
  final _maxAttemptsController = TextEditingController(text: '5');
  bool _maintenanceMode = false;
  bool _enforceStrongPasswords = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _sessionTimeoutController.dispose();
    _maxAttemptsController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Platform configuration saved successfully.'),
          backgroundColor: AppColors.statusActive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (context.isCompact) ...[
                  AppPageHeader(
                    eyebrow: 'Operations Hub Administration',
                    title: 'Platform Settings',
                    subtitle: 'Configure platform parameters, security policies, and system audit logs.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton(
                      text: 'Save Changes',
                      iconData: Icons.check,
                      variant: AppButtonVariant.primary,
                      isLoading: _isSaving,
                      onPressed: _saveSettings,
                    ),
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppPageHeader(
                          eyebrow: 'Operations Hub Administration',
                          title: 'Platform Settings',
                          subtitle: 'Configure platform parameters, security policies, and system audit logs.',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      AppButton(
                        text: 'Save Changes',
                        iconData: Icons.check,
                        variant: AppButtonVariant.primary,
                        isLoading: _isSaving,
                        onPressed: _saveSettings,
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.lg),

                // Platform Information & Status
                _buildSystemInfoCard(),
                const SizedBox(height: AppSpacing.lg),

                // Security & Session Rules
                _buildSecurityCard(),
                const SizedBox(height: AppSpacing.lg),

                // Maintenance Mode
                _buildMaintenanceCard(),
                const SizedBox(height: AppSpacing.lg),

                // System Audit Trail
                _buildAuditTrailCard(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dns_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Platform Environment & Topology',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Active system tier, version build, and tenant isolation parameters',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 1, color: AppColors.outlineSubtle),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.md,
              children: [
                _buildInfoItem('Console Version', 'WorkAxis v2.4.0 (Build 412)'),
                _buildInfoItem('Persistence Architecture', 'Mock First · Contract Ready'),
                _buildInfoItem('Tenant Isolation', 'Strict Scoped Authorization'),
                _buildInfoItem('Audit System', 'Active · Server Authoritative'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    final isCompact = context.isCompact;

    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Authentication & Session Policies',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Configure global session timeouts and password requirements',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isCompact) ...[
              AppTextField(
                controller: _sessionTimeoutController,
                label: 'Session Inactivity Timeout (Minutes)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _maxAttemptsController,
                label: 'Max Failed Sign-In Attempts Before Lockout',
                keyboardType: TextInputType.number,
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _sessionTimeoutController,
                      label: 'Session Inactivity Timeout (Minutes)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      controller: _maxAttemptsController,
                      label: 'Max Failed Sign-In Attempts Before Lockout',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _enforceStrongPasswords,
              onChanged: (v) => setState(() => _enforceStrongPasswords = v),
              title: const Text('Enforce Strong Password Complexity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Requires at least 8 characters with numbers and special symbols', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceCard() {
    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build_circle_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Maintenance Window',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Temporarily broadcast maintenance mode across customer organization workspaces',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _maintenanceMode,
              onChanged: (v) => setState(() => _maintenanceMode = v),
              title: Text(
                _maintenanceMode ? 'Maintenance Mode Active' : 'Maintenance Mode Disabled',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _maintenanceMode ? AppColors.statusUrgentText : AppColors.onSurface,
                ),
              ),
              subtitle: const Text(
                'When enabled, non-platform users see a non-blocking scheduled maintenance banner.',
                style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTrailCard() {
    final auditLogs = [
      {'action': 'Organization Created', 'detail': 'FreshGrocer Supermarkets (ORG-001) onboarded', 'time': 'Today, 10:14 AM', 'user': 'Alex Vance'},
      {'action': 'User Role Updated', 'detail': 'Elena Rostova assigned platform management permissions', 'time': 'Yesterday, 4:30 PM', 'user': 'Alex Vance'},
      {'action': 'Branch Terminal Synced', 'detail': 'Downtown Flagship terminal configuration confirmed', 'time': 'Oct 17, 2:15 PM', 'user': 'System Daemon'},
    ];

    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Recent System Audit Trail',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Immutable log of privileged configuration and access changes',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final log in auditLogs) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log['action']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(log['detail']!, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(log['user']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                        Text(log['time']!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              if (log != auditLogs.last)
                const Divider(height: 1, thickness: 1, color: AppColors.outlineSubtle),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
