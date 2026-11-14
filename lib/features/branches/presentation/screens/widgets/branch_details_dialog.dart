import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/geofence_real_map_view.dart';

/// Read-only branch details with kiosk pairing actions.
class BranchDetailsDialog extends StatefulWidget {
  const BranchDetailsDialog({
    super.key,
    required this.branch,
    required this.managerNames,
    required this.onGenerateToken,
    required this.onCompletePairing,
    required this.readActionError,
  });

  final BranchRecord branch;
  final List<String> managerNames;
  final Future<KioskPairingToken?> Function() onGenerateToken;
  final Future<bool> Function() onCompletePairing;

  /// Latest action error from the owning controller, shown after a failure.
  final String? Function() readActionError;

  @override
  State<BranchDetailsDialog> createState() => _BranchDetailsDialogState();
}

class _BranchDetailsDialogState extends State<BranchDetailsDialog> {
  KioskPairingToken? _token;
  bool _isSaving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final branch = widget.branch;
    final details = _Details(
      branch: branch,
      managerNames: widget.managerNames,
      token: _token,
      error: _error,
    );
    final actions = [
      AppButton.outlined(
        text: 'Close',
        isFullWidth: context.isCompact,
        onPressed: () => Navigator.of(context).pop(),
      ),
      if (_token == null && branch.kioskStatus != KioskPairingStatus.paired)
        AppButton.secondary(
          text: 'Generate pairing code',
          isFullWidth: context.isCompact,
          isLoading: _isSaving,
          onPressed: _generateToken,
        ),
      if (_token != null)
        AppButton.primary(
          text: 'Mark terminal paired',
          isFullWidth: context.isCompact,
          isLoading: _isSaving,
          onPressed: _completePairing,
        ),
    ];

    if (context.isCompact) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: const Text('Branch details')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.name,
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  details,
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.sm,
                children: actions,
              ),
            ),
          ),
        ),
      );
    }
    return AlertDialog(
      title: Text(branch.name),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(child: details),
      ),
      actions: actions,
    );
  }

  Future<void> _generateToken() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final token = await widget.onGenerateToken();
    if (!mounted) return;
    setState(() {
      _token = token;
      _isSaving = false;
      if (token == null) {
        _error =
            widget.readActionError() ??
            'A pairing code could not be generated.';
      }
    });
  }

  Future<void> _completePairing() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final paired = await widget.onCompletePairing();
    if (!mounted) return;
    if (paired) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isSaving = false;
      _error = widget.readActionError() ?? 'The kiosk could not be paired.';
    });
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.branch,
    required this.managerNames,
    required this.token,
    required this.error,
  });

  final BranchRecord branch;
  final List<String> managerNames;
  final KioskPairingToken? token;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final kioskLabel = token != null
        ? 'Pairing in progress'
        : switch (branch.kioskStatus) {
            KioskPairingStatus.paired => 'Paired',
            KioskPairingStatus.pairingPending => 'Pairing in progress',
            KioskPairingStatus.notPaired => 'Not paired',
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _DetailRow(label: 'Branch code', value: branch.code),
        _DetailRow(label: 'Location', value: branch.location),
        _DetailRow(
          label: 'Status',
          value: branch.isActive ? 'Active' : 'Inactive',
        ),
        _DetailRow(
          label: 'Active employees',
          value: '${branch.activeEmployeeCount}',
        ),
        _DetailRow(
          label: 'Geofence radius',
          value: '${branch.geofenceRadiusMeters} metres',
        ),
        _DetailRow(
          label: 'Coordinates',
          value: branch.hasGeofence
              ? '${branch.latitude}, ${branch.longitude}'
              : 'Geofence not configured',
        ),
        if (branch.hasGeofence) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.kpiBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: GeofenceRealMapView(
              latitude: branch.latitude,
              longitude: branch.longitude,
              geofenceRadiusMeters: branch.geofenceRadiusMeters,
              isWithinGeofence: true,
              branchName: branch.name,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _DetailRow(label: 'Kiosk terminal', value: kioskLabel),
        _DetailRow(
          label: 'Branch managers',
          value: managerNames.isEmpty ? 'Unassigned' : managerNames.join(', '),
        ),
        if (token != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.key_outlined,
                  color: AppColors.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SelectableText(
                    token!.value,
                    style: AppTypography.labelMono.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'This pairing code is shown once and is not stored.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: AppSpacing.md),
          ErrorBanner(message: error!),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
