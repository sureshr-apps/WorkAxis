import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

class BranchEditorDialog extends StatefulWidget {
  const BranchEditorDialog({
    super.key,
    required this.organizationId,
    required this.managerOptions,
    required this.isSaving,
    required this.onSave,
    this.branch,
  });

  final BranchRecord? branch;
  final String organizationId;
  final List<BranchManagerOption> managerOptions;
  final bool isSaving;
  final Future<BranchRecord?> Function(BranchRecord branch) onSave;

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
      text: '${branch?.geofenceRadiusMeters ?? 150}',
    );
    _latitudeController = TextEditingController(
      text: '${branch?.latitude ?? 0.0}',
    );
    _longitudeController = TextEditingController(
      text: '${branch?.longitude ?? 0.0}',
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

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(AppSpacing.md),
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
          const Text(
            'Branch managers',
            style: TextStyle(fontWeight: FontWeight.w600),
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
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
      ],
    );
    final actions = [
      AppButton.outlined(
        text: 'Cancel',
        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
      ),
      AppButton.primary(
        text: _editing ? 'Save changes' : 'Create branch',
        isLoading: _saving || widget.isSaving,
        onPressed: _save,
      ),
    ];
    if (context.isCompact) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: Text(_editing ? 'Edit branch' : 'Add branch')),
          body: SafeArea(child: content),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(child: actions.first),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: actions.last),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Dialog(
      child: SizedBox(
        width: 680,
        height: 680,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _editing ? 'Edit branch' : 'Add branch',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: content),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  actions.first,
                  const SizedBox(width: AppSpacing.sm),
                  actions.last,
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
    final radius = int.tryParse(_radiusController.text.trim());
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    if (name.isEmpty ||
        location.isEmpty ||
        radius == null ||
        radius < 25 ||
        latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      setState(
        () => _error = 'Enter a name, location, radius of at least 25 metres, and valid coordinates.',
      );
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
        _error = 'Could not save this branch. Try again.';
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

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AppTextField(
          controller: latitude,
          label: 'Latitude',
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: AppTextField(
          controller: longitude,
          label: 'Longitude',
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
        ),
      ),
    ],
  );
}
