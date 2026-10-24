import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';

class OrganizationSettingsScreen extends StatefulWidget {
  const OrganizationSettingsScreen({super.key});

  @override
  State<OrganizationSettingsScreen> createState() =>
      _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState extends State<OrganizationSettingsScreen> {
  final _emailController = TextEditingController(text: 'ops@freshgrocer.internal');
  final _phoneController = TextEditingController(text: '+1 (555) 392-1084');
  final _geofenceRadiusController = TextEditingController(text: '150');
  final _gracePeriodController = TextEditingController(text: '15');

  bool _allowBreaks = true;
  bool _requireGeolocation = true;
  bool _dailyDigest = true;
  bool _returnAlerts = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _geofenceRadiusController.dispose();
    _gracePeriodController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Organization operational settings saved successfully.'),
          backgroundColor: AppColors.statusActive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AccessController>().accessContext;
    final org = access?.organization;
    final orgName = org?.name ?? 'FreshGrocer Supermarkets';
    final orgCode = org?.code ?? 'ORG-001';

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
                    eyebrow: 'Enterprise Administration',
                    title: 'Organization Settings',
                    subtitle: 'Manage operational parameters, geofence radius defaults, and notification digests.',
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
                          eyebrow: 'Enterprise Administration',
                          title: 'Organization Settings',
                          subtitle: 'Manage operational parameters, geofence radius defaults, and notification digests.',
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

                // Organization Profile Card
                _buildProfileCard(context, orgName, orgCode),
                const SizedBox(height: AppSpacing.lg),

                // Attendance Policy Card
                _buildAttendancePolicyCard(context),
                const SizedBox(height: AppSpacing.lg),

                // Notifications Digest Card
                _buildNotificationsCard(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, String orgName, String orgCode) {
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
                const Icon(Icons.business_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Organization Information',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Identity and primary administrative contact coordinates',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Organization Name', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(orgName, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Identifier Code', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(orgCode, style: AppTypography.labelMono.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 1, color: AppColors.outlineSubtle),
            const SizedBox(height: AppSpacing.md),
            if (isCompact) ...[
              AppTextField(
                controller: _emailController,
                label: 'Operations Contact Email',
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _phoneController,
                label: 'Emergency Support Phone',
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _emailController,
                      label: 'Operations Contact Email',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      controller: _phoneController,
                      label: 'Emergency Support Phone',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendancePolicyCard(BuildContext context) {
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
                const Icon(Icons.pin_drop_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Attendance & Geofencing Policies',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Enforce branch perimeter thresholds and punch grace intervals',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isCompact) ...[
              AppTextField(
                controller: _geofenceRadiusController,
                label: 'Default Geofence Radius (Meters)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _gracePeriodController,
                label: 'Check-in Grace Period (Minutes)',
                keyboardType: TextInputType.number,
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _geofenceRadiusController,
                      label: 'Default Geofence Radius (Meters)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      controller: _gracePeriodController,
                      label: 'Check-in Grace Period (Minutes)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _requireGeolocation,
              onChanged: (v) => setState(() => _requireGeolocation = v),
              title: const Text('Require Device GPS Fix for Check-in', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Rejects punches when employee device is outside designated branch boundary', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.outlineSubtle),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _allowBreaks,
              onChanged: (v) => setState(() => _allowBreaks = v),
              title: const Text('Allow Mid-Shift Break Recording', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Enables breakfast, tea, and meal break logs in the employee app', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
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
                const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Automated Operational Digests',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select which automated operational alerts are dispatched to branch leadership',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _dailyDigest,
              onChanged: (v) => setState(() => _dailyDigest = v),
              title: const Text('Daily Morning Attendance Digest', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Summarizes shift roster, late arrivals, and absent staff at 09:00 AM', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.outlineSubtle),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _returnAlerts,
              onChanged: (v) => setState(() => _returnAlerts = v),
              title: const Text('High-Value Product Return Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Immediate alert when a return request exceeds standard batch limits', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}
