import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/settings/domain/models/organization_settings.dart';
import 'package:workaxis/features/settings/domain/validators/settings_validators.dart';
import 'package:workaxis/features/settings/presentation/controllers/settings_controller.dart';
import 'package:workaxis/features/settings/presentation/widgets/settings_page.dart';
import 'package:workaxis/features/settings/presentation/widgets/settings_section_card.dart';

class OrganizationSettingsScreen extends StatefulWidget {
  const OrganizationSettingsScreen({super.key});

  @override
  State<OrganizationSettingsScreen> createState() =>
      _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState
    extends State<OrganizationSettingsScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _geofenceRadiusController = TextEditingController();
  final _gracePeriodController = TextEditingController();

  bool _allowBreaks = OrganizationSettings.defaults.allowBreaks;
  bool _requireGeolocation = OrganizationSettings.defaults.requireGeolocation;
  bool _dailyDigest = OrganizationSettings.defaults.dailyDigest;
  bool _returnAlerts = OrganizationSettings.defaults.returnAlerts;

  /// The loaded settings the form fields were last populated from.
  OrganizationSettings? _populatedFrom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    await context.read<SettingsController>().loadOrganization(access: access);
  }

  void _populate(OrganizationSettings settings) {
    if (identical(_populatedFrom, settings)) return;
    _populatedFrom = settings;
    _emailController.text = settings.operationsEmail ?? '';
    _phoneController.text = settings.emergencyPhone ?? '';
    _geofenceRadiusController.text = '${settings.geofenceRadiusMeters}';
    _gracePeriodController.text = '${settings.gracePeriodMinutes}';
    _allowBreaks = settings.allowBreaks;
    _requireGeolocation = settings.requireGeolocation;
    _dailyDigest = settings.dailyDigest;
    _returnAlerts = settings.returnAlerts;
  }

  /// Unparseable numbers become -1 so validation reports the allowed range.
  OrganizationSettings _collect() => OrganizationSettings(
    geofenceRadiusMeters:
        int.tryParse(_geofenceRadiusController.text.trim()) ?? -1,
    gracePeriodMinutes: int.tryParse(_gracePeriodController.text.trim()) ?? -1,
    allowBreaks: _allowBreaks,
    requireGeolocation: _requireGeolocation,
    dailyDigest: _dailyDigest,
    returnAlerts: _returnAlerts,
    operationsEmail: _blankToNull(_emailController.text),
    emergencyPhone: _blankToNull(_phoneController.text),
  );

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _geofenceRadiusController.dispose();
    _gracePeriodController.dispose();
    super.dispose();
  }

  void _edited() => context.read<SettingsController>().clearSaveState();

  void _toast(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? AppColors.statusActive
            : AppColors.statusUrgent,
      ),
    );
  }

  Future<void> _saveSettings() async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) {
      _toast('Sign in again to save settings.', success: false);
      return;
    }
    final controller = context.read<SettingsController>();
    final saved = await controller.saveOrganization(
      access: access,
      settings: _collect(),
    );
    if (!mounted) return;
    _toast(
      saved
          ? 'Organization operational settings saved.'
          : (controller.saveErrorMessage ??
                controller.validationErrors.values.firstOrNull ??
                'Settings could not be saved.'),
      success: saved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AccessController>().accessContext;
    final settings = context.watch<SettingsController>();
    final org = access?.organization;
    final loaded = settings.organizationSettings;
    if (loaded != null) _populate(loaded);
    final errors = settings.validationErrors;

    return SettingsPage(
      eyebrow: 'Enterprise Administration',
      title: 'Organization Settings',
      subtitle: 'Manage operational parameters, geofence radius defaults, and notification digests.',
      notice: 'Policy controls are read-only until these features are available. You can update the operations contact details.',
      controller: settings,
      status: settings.organizationStatus,
      hasLoaded: loaded != null,
      loadFallbackMessage: 'Could not load organization settings.',
      onRetry: _load,
      onSave: _saveSettings,
      children: [
        SettingsSectionCard(
          icon: Icons.business_outlined,
          title: 'Organization Information',
          subtitle: 'Identity and primary administrative contact coordinates',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsFieldPair(
                first: SettingsReadOnlyValue(
                  label: 'Organization Name',
                  value: org?.name ?? '—',
                ),
                second: SettingsReadOnlyValue(
                  label: 'Identifier Code',
                  value: org?.code ?? '—',
                  mono: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.outlineSubtle,
              ),
              const SizedBox(height: AppSpacing.md),
              SettingsFieldPair(
                first: AppTextField(
                  controller: _emailController,
                  label: 'Operations Contact Email',
                  errorText: errors[SettingsField.operationsEmail],
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => _edited(),
                ),
                second: AppTextField(
                  controller: _phoneController,
                  label: 'Emergency Support Phone',
                  errorText: errors[SettingsField.emergencyPhone],
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => _edited(),
                ),
              ),
            ],
          ),
        ),
        SettingsSectionCard(
          icon: Icons.pin_drop_outlined,
          title: 'Attendance & Geofencing Policies',
          subtitle:
              'Enforce branch perimeter thresholds and punch grace intervals',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsFieldPair(
                first: AppTextField(
                  controller: _geofenceRadiusController,
                  enabled: false,
                  label: 'Default Geofence Radius (Meters)',
                  errorText: errors[SettingsField.geofenceRadius],
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _edited(),
                ),
                second: AppTextField(
                  controller: _gracePeriodController,
                  enabled: false,
                  label: 'Check-in Grace Period (Minutes)',
                  errorText: errors[SettingsField.gracePeriod],
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _edited(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SettingsSwitchTile(
                value: _requireGeolocation,
                onChanged: null,
                title: 'Require Device GPS Fix for Check-in',
                subtitle: 'Rejects punches when employee device is outside designated branch boundary',
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.outlineSubtle,
              ),
              SettingsSwitchTile(
                value: _allowBreaks,
                onChanged: null,
                title: 'Allow Mid-Shift Break Recording',
                subtitle: 'Enables breakfast, tea, and meal break logs in the employee app',
              ),
            ],
          ),
        ),
        SettingsSectionCard(
          icon: Icons.notifications_active_outlined,
          title: 'Automated Operational Digests',
          subtitle: 'Select which automated operational alerts are dispatched to branch leadership',
          child: Column(
            children: [
              SettingsSwitchTile(
                value: _dailyDigest,
                onChanged: null,
                title: 'Daily Morning Attendance Digest',
                subtitle: 'Summarizes shift roster, late arrivals, and absent staff at 09:00 AM',
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.outlineSubtle,
              ),
              SettingsSwitchTile(
                value: _returnAlerts,
                onChanged: null,
                title: 'High-Value Product Return Alerts',
                subtitle: 'Immediate alert when a return request exceeds standard batch limits',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
