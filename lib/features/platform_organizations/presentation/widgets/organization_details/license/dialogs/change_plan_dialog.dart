import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_license_rules.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/license_dialog_frame.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/license_form_fields.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_formatters.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_shared_widgets.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// Moves the license to a higher-level active plan. Only plans with a strictly
/// higher level are offered; the term dates are preserved.
class ChangePlanDialog extends StatefulWidget {
  const ChangePlanDialog({
    super.key,
    required this.organizationName,
    required this.license,
    required this.activePlans,
    required this.onSubmit,
  });

  final String organizationName;
  final OrganizationLicense license;
  final List<LicensePlan> activePlans;
  final LicenseSubmit<ChangeLicensePlanRequest> onSubmit;

  @override
  State<ChangePlanDialog> createState() => _ChangePlanDialogState();
}

class _ChangePlanDialogState extends State<ChangePlanDialog> {
  late final List<LicensePlan> _targets =
      OrganizationLicenseRules.changeTargets(
        widget.activePlans,
        widget.license.plan.level,
      );
  late String? _targetId = _targets.isEmpty ? null : _targets.first.id;
  late final TextEditingController _negotiatedPrice = TextEditingController(
    text: widget.license.negotiatedPrice.round().toString(),
  );
  late final TextEditingController _maintenancePrice = TextEditingController(
    text: widget.license.maintenancePrice.round().toString(),
  );

  Map<String, String> _errors = const {};
  String? _submitError;
  bool _isSaving = false;

  @override
  void dispose() {
    _negotiatedPrice.dispose();
    _maintenancePrice.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final errors = <String, String>{};
    final targetId = _targetId;
    if (targetId == null) {
      errors['plan'] = 'Only a higher-level active plan can be selected.';
    }
    final negotiatedError = OrganizationLicenseRules.priceError(
      _negotiatedPrice.text,
      fieldName: 'one-time price',
    );
    if (negotiatedError != null) errors['negotiated'] = negotiatedError;
    final maintenanceError = OrganizationLicenseRules.priceError(
      _maintenancePrice.text,
      fieldName: 'annual maintenance price',
    );
    if (maintenanceError != null) errors['maintenance'] = maintenanceError;

    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _submitError = null;
      });
      return;
    }
    setState(() {
      _errors = const {};
      _submitError = null;
      _isSaving = true;
    });
    final failure = await widget.onSubmit(
      ChangeLicensePlanRequest(
        targetPlanId: targetId!,
        negotiatedPrice: OrganizationLicenseRules.parseWholeRupees(
          _negotiatedPrice.text,
        )!,
        maintenancePrice: OrganizationLicenseRules.parseWholeRupees(
          _maintenancePrice.text,
        )!,
      ),
    );
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSaving = false;
      _submitError = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.license.plan;
    final target = _targets.where((plan) => plan.id == _targetId).firstOrNull;
    return LicenseDialogFrame(
      title: 'Change License Plan',
      submitLabel: 'Confirm Plan Upgrade',
      isSaving: _isSaving,
      submitError: _submitError,
      submitEnabled: _targets.isNotEmpty,
      onSubmit: _submit,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Upgrade the agreement tier for ${widget.organizationName}.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          _PlanBox(
            heading: 'Current plan',
            name: current.name,
            level: current.level,
            maxStores: current.maxStores,
            maxUsers: current.maxUsers,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (target == null)
            _NoHigherPlanNotice(currentPlan: current)
          else
            _PlanBox(
              heading: 'Upgrade to',
              name: target.name,
              level: target.level,
              maxStores: target.maxStores,
              maxUsers: target.maxUsers,
              highlighted: true,
            ),
          if (_targets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            LicensePlanField(
              plans: _targets,
              selectedPlanId: _targetId,
              enabled: !_isSaving,
              errorText: _errors['plan'],
              onChanged: (value) => setState(() => _targetId = value),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Downgrades are not supported. Only higher-level active plans '
              'are listed.',
              style: licenseBodyStyle,
            ),
            const SizedBox(height: AppSpacing.md),
            LicenseMoneyField(
              label: 'New negotiated price (one-time, INR)',
              controller: _negotiatedPrice,
              enabled: !_isSaving,
              errorText: _errors['negotiated'],
              helperText:
                  'Prices are negotiated, not calculated from the plan.',
            ),
            const SizedBox(height: AppSpacing.md),
            LicenseMoneyField(
              label: 'New annual maintenance price (INR)',
              controller: _maintenancePrice,
              enabled: !_isSaving,
              errorText: _errors['maintenance'],
              helperText: 'Recurring yearly maintenance fee for the new plan.',
            ),
            const SizedBox(height: AppSpacing.md),
            LicenseTermRow(
              label: 'Term',
              value:
                  'Preserved (${LicenseFormatters.period(widget.license.startDate, widget.license.expiryDate)})',
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanBox extends StatelessWidget {
  const _PlanBox({
    required this.heading,
    required this.name,
    required this.level,
    required this.maxStores,
    required this.maxUsers,
    this.highlighted = false,
  });

  final String heading;
  final String name;
  final int level;
  final int maxStores;
  final int maxUsers;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => LicenseInsetCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(heading, style: licenseLabelStyle)),
            StatusChip(
              label: 'LEVEL $level',
              type: highlighted ? StatusType.active : StatusType.neutral,
              width: null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          name,
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('$maxStores stores · $maxUsers users', style: licenseBodyStyle),
      ],
    ),
  );
}

class _NoHigherPlanNotice extends StatelessWidget {
  const _NoHigherPlanNotice({required this.currentPlan});

  final OrganizationLicensePlan currentPlan;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      border: Border.all(color: AppColors.outlineVariant),
      borderRadius: AppSpacing.roundedXs,
    ),
    child: Text(
      'No higher active plan is currently available. This organization is on '
      'the highest active plan level (${currentPlan.name}, Level '
      '${currentPlan.level}). Upgrades to the same or a lower level are not '
      'permitted.',
      style: licenseBodyStyle,
    ),
  );
}
