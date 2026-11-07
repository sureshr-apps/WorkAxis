import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/branches/domain/branch_geofence_validator.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

/// Create/edit dialog for a branch. Coordinates start empty for new branches;
/// geofence rules (including rejecting 0, 0) live in [BranchGeofenceValidator].
class BranchEditorDialog extends StatefulWidget {
  const BranchEditorDialog({
    super.key,
    required this.organizationId,
    required this.managerOptions,
    required this.isSaving,
    required this.onSave,
    this.readActionError,
    this.branch,
  });

  final BranchRecord? branch;
  final String organizationId;
  final List<BranchManagerOption> managerOptions;
  final bool isSaving;
  final Future<BranchRecord?> Function(BranchRecord branch) onSave;

  /// Latest action error from the owning controller, shown when saving fails.
  final String? Function()? readActionError;

  @override
  State<BranchEditorDialog> createState() => _BranchEditorDialogState();
}

class _BranchEditorDialogState extends State<BranchEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _locationController;
  late final TextEditingController _radiusController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final Set<String> _selectedManagers;
  late bool _isActive;
  String? _error;
  bool _saving = false;

  bool get _editing => widget.branch != null;

  @override
  void initState() {
    super.initState();
    final branch = widget.branch;
    _nameController = TextEditingController(text: branch?.name ?? '');
    _codeController = TextEditingController(text: branch?.code ?? '');
    _locationController = TextEditingController(text: branch?.location ?? '');
    _radiusController = TextEditingController(
      text:
          '${branch?.geofenceRadiusMeters ?? BranchGeofenceValidator.defaultRadiusMeters}',
    );
    _latitudeController = TextEditingController(
      text: branch?.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: branch?.longitude?.toString() ?? '',
    );
    _selectedManagers = {...?branch?.managerIds};
    _isActive = branch?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _locationController.dispose();
    _radiusController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _nameController,
          label: 'Branch name',
          hintText: 'e.g. Downtown Flagship',
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _codeController,
          label: 'Branch code',
          hintText: 'Auto-generated when left blank',
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _locationController,
          label: 'District or address',
          hintText: 'e.g. Metro Central',
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _radiusController,
          label: 'Geofence radius (metres)',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        _CoordinatesRow(
          latitude: _latitudeController,
          longitude: _longitudeController,
        ),
        if (widget.managerOptions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Branch managers',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final manager in widget.managerOptions)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _selectedManagers.contains(manager.id),
              title: Text(manager.name),
              onChanged: (selected) => setState(() {
                if (selected == true) {
                  _selectedManagers.add(manager.id);
                } else {
                  _selectedManagers.remove(manager.id);
                }
              }),
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _isActive,
          title: const Text('Branch is active'),
          onChanged: (value) => setState(() => _isActive = value),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ErrorBanner(message: _error!),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _editing ? 'Edit branch' : 'Add branch';
    final cancel = AppButton.outlined(
      text: 'Cancel',
      isFullWidth: context.isCompact,
      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
    );
    final save = AppButton.primary(
      text: _editing ? 'Save changes' : 'Create branch',
      isFullWidth: context.isCompact,
      isLoading: _saving || widget.isSaving,
      onPressed: _save,
    );

    if (context.isCompact) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildForm(),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(child: cancel),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: save),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildForm(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  cancel,
                  const SizedBox(width: AppSpacing.sm),
                  save,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    if (name.isEmpty || location.isEmpty) {
      setState(() => _error = 'Enter a branch name and location.');
      return;
    }
    final radius = int.tryParse(_radiusController.text.trim());
    if (radius == null) {
      setState(() => _error = 'Enter the geofence radius in whole metres.');
      return;
    }
    final latText = _latitudeController.text.trim();
    final lngText = _longitudeController.text.trim();
    final latitude = latText.isEmpty ? null : double.tryParse(latText);
    final longitude = lngText.isEmpty ? null : double.tryParse(lngText);
    if ((latText.isNotEmpty && latitude == null) ||
        (lngText.isNotEmpty && longitude == null)) {
      setState(() => _error = 'Enter valid geofence coordinates.');
      return;
    }
    try {
      BranchGeofenceValidator.validate(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radius,
      );
    } on ValidationException catch (e) {
      setState(() => _error = e.userMessage);
      return;
    }

    final previous = widget.branch;
    final draft = BranchRecord(
      summary: BranchSummary(
        id: previous?.id ?? '',
        organizationId: previous?.organizationId ?? widget.organizationId,
        name: name,
        code: _codeController.text.trim(),
        location: location,
        activeEmployeeCount: previous?.activeEmployeeCount ?? 0,
        isActive: _isActive,
      ),
      geofenceRadiusMeters: radius,
      latitude: latitude,
      longitude: longitude,
      isMainBranch: previous?.isMainBranch ?? false,
      managerIds: _selectedManagers.toList(growable: false),
      kioskStatus: previous?.kioskStatus ?? KioskPairingStatus.notPaired,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.onSave(draft);
    if (!mounted) return;
    if (saved == null) {
      setState(() {
        _saving = false;
        _error =
            widget.readActionError?.call() ??
            'Could not save this branch. Try again.';
      });
    } else {
      Navigator.of(context).pop(true);
    }
  }
}

class _CoordinatesRow extends StatelessWidget {
  const _CoordinatesRow({required this.latitude, required this.longitude});

  final TextEditingController latitude;
  final TextEditingController longitude;

  static const _keyboard = TextInputType.numberWithOptions(
    decimal: true,
    signed: true,
  );

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: AppTextField(
          controller: latitude,
          label: 'Latitude',
          keyboardType: _keyboard,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: AppTextField(
          controller: longitude,
          label: 'Longitude',
          keyboardType: _keyboard,
        ),
      ),
    ],
  );
}
