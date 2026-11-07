import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/config/backend_config.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/settings/domain/models/platform_settings.dart';
import 'package:workaxis/features/settings/domain/validators/settings_validators.dart';
import 'package:workaxis/features/settings/presentation/controllers/settings_controller.dart';
import 'package:workaxis/features/settings/presentation/widgets/settings_page.dart';
import 'package:workaxis/features/settings/presentation/widgets/settings_section_card.dart';

class PlatformSettingsScreen extends StatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  State<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends State<PlatformSettingsScreen> {
  final _sessionTimeoutController = TextEditingController();
  final _maxAttemptsController = TextEditingController();
  bool _maintenanceMode = PlatformSettings.defaults.maintenanceMode;
  bool _enforceStrongPasswords =
      PlatformSettings.defaults.enforceStrongPasswords;

  /// The loaded settings the form fields were last populated from.
  PlatformSettings? _populatedFrom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    await context.read<SettingsController>().loadPlatform(access: access);
  }

  void _populate(PlatformSettings settings) {
    if (identical(_populatedFrom, settings)) return;
    _populatedFrom = settings;
    _sessionTimeoutController.text = '${settings.sessionTimeoutMinutes}';
    _maxAttemptsController.text = '${settings.maxLoginAttempts}';
    _maintenanceMode = settings.maintenanceMode;
    _enforceStrongPasswords = settings.enforceStrongPasswords;
  }

  /// Unparseable numbers become -1 so validation reports the allowed range.
  PlatformSettings _collect() => PlatformSettings(
    sessionTimeoutMinutes:
        int.tryParse(_sessionTimeoutController.text.trim()) ?? -1,
    maxLoginAttempts: int.tryParse(_maxAttemptsController.text.trim()) ?? -1,
    maintenanceMode: _maintenanceMode,
    enforceStrongPasswords: _enforceStrongPasswords,
  );

  @override
  void dispose() {
    _sessionTimeoutController.dispose();
    _maxAttemptsController.dispose();
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
    final saved = await controller.savePlatform(
      access: access,
      settings: _collect(),
    );
    if (!mounted) return;
    _toast(
      saved
          ? 'Platform configuration saved.'
          : (controller.saveErrorMessage ??
                controller.validationErrors.values.firstOrNull ??
                'Settings could not be saved.'),
      success: saved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final loaded = settings.platformSettings;
    if (loaded != null) _populate(loaded);
    final errors = settings.validationErrors;

    return SettingsPage(
      eyebrow: 'Operations Hub Administration',
      title: 'Platform Settings',
      subtitle: 'Configure platform parameters, security policies, and maintenance mode.',
      controller: settings,
      status: settings.platformStatus,
      hasLoaded: loaded != null,
      loadFallbackMessage: 'Could not load platform settings.',
      onRetry: _load,
      onSave: _saveSettings,
      children: [
        SettingsSectionCard(
          icon: Icons.dns_outlined,
          title: 'Platform Environment & Topology',
          subtitle: 'Active system tier, version build, and tenant isolation parameters',
          child: Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              SettingsReadOnlyValue(
                label: 'Persistence Architecture',
                value: BackendConfig.isFirebase
                    ? 'Firebase & SQL Connect (PostgreSQL)'
                    : 'Mock First · Contract Ready',
              ),
              const SettingsReadOnlyValue(
                label: 'Tenant Isolation',
                value: 'Strict Scoped Authorization',
              ),
              const SettingsReadOnlyValue(
                label: 'Audit System',
                value: 'Active · Server Authoritative',
              ),
            ],
          ),
        ),
        SettingsSectionCard(
          icon: Icons.security_outlined,
          title: 'Authentication & Session Policies',
          subtitle:
              'Configure global session timeouts and password requirements',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsFieldPair(
                first: AppTextField(
                  controller: _sessionTimeoutController,
                  label: 'Session Inactivity Timeout (Minutes)',
                  errorText: errors[SettingsField.sessionTimeout],
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _edited(),
                ),
                second: AppTextField(
                  controller: _maxAttemptsController,
                  label: 'Max Failed Sign-In Attempts Before Lockout',
                  errorText: errors[SettingsField.maxLoginAttempts],
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _edited(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SettingsSwitchTile(
                value: _enforceStrongPasswords,
                onChanged: (v) {
                  setState(() => _enforceStrongPasswords = v);
                  _edited();
                },
                title: 'Enforce Strong Password Complexity',
                subtitle: 'Requires at least 8 characters with numbers and special symbols',
              ),
            ],
          ),
        ),
        SettingsSectionCard(
          icon: Icons.build_circle_outlined,
          title: 'Maintenance Window',
          subtitle: 'Temporarily broadcast maintenance mode across customer organization workspaces',
          child: SettingsSwitchTile(
            value: _maintenanceMode,
            onChanged: (v) {
              setState(() => _maintenanceMode = v);
              _edited();
            },
            title: _maintenanceMode
                ? 'Maintenance Mode Active'
                : 'Maintenance Mode Disabled',
            titleColor: _maintenanceMode ? AppColors.statusUrgentText : null,
            subtitle: 'When enabled, non-platform users see a non-blocking scheduled maintenance banner.',
          ),
        ),
      ],
    );
  }
}
