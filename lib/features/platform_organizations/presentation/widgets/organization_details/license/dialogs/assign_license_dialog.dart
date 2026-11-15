import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_license_rules.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/license_dialog_frame.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/license_form_fields.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// Assigns the first license of an organization. Only active plans can be
/// chosen. Defaults: start today (business date), expiry one year later.
class AssignLicenseDialog extends StatefulWidget {
  const AssignLicenseDialog({
    super.key,
    required this.organizationName,
    required this.activePlans,
    required this.today,
    required this.onSubmit,
  });

  final String organizationName;
  final List<LicensePlan> activePlans;

  /// Business date that the default term starts on.
  final DateTime today;
  final LicenseSubmit<AssignLicenseRequest> onSubmit;

  @override
  State<AssignLicenseDialog> createState() => _AssignLicenseDialogState();
}

class _AssignLicenseDialogState extends State<AssignLicenseDialog> {
  late final List<LicensePlan> _plans =
      OrganizationLicenseRules.assignablePlans(widget.activePlans);
  late String? _planId = _plans.isEmpty ? null : _plans.first.id;
  late DateTime _startDate = widget.today;
  late DateTime _expiryDate = OrganizationLicenseRules.defaultTermExpiry(
    widget.today,
  );
  final TextEditingController _negotiatedPrice = TextEditingController();
  final TextEditingController _maintenancePrice = TextEditingController();

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
    final planId = _planId;
    if (planId == null) errors['plan'] = 'Select an active license plan.';
    final termError = OrganizationLicenseRules.termError(
      _startDate,
      _expiryDate,
    );
    if (termError != null) errors['expiry'] = termError;
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
      AssignLicenseRequest(
        planId: planId!,
        startDate: _startDate,
        expiryDate: _expiryDate,
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
    final selectedPlan = _plans.where((plan) => plan.id == _planId).firstOrNull;
    return LicenseDialogFrame(
      title: 'Assign License',
      submitLabel: 'Assign License',
      isSaving: _isSaving,
      submitError: _submitError,
      submitEnabled: _plans.isNotEmpty,
      onSubmit: _submit,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Provision a license agreement for ${widget.organizationName}.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_plans.isEmpty)
            Text(
              'No active license plans are available. Activate a plan before '
              'assigning a license.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.statusUrgentText,
              ),
            )
          else
            LicensePlanField(
              plans: _plans,
              selectedPlanId: _planId,
              enabled: !_isSaving,
              errorText: _errors['plan'],
              onChanged: (value) => setState(() => _planId = value),
            ),
          if (selectedPlan != null) ...[
            const SizedBox(height: AppSpacing.md),
            LicensePlanEntitlements(plan: selectedPlan),
          ],
          const SizedBox(height: AppSpacing.md),
          LicenseDateField(
            label: 'Start date',
            value: _startDate,
            enabled: !_isSaving,
            onChanged: (value) => setState(() => _startDate = value),
          ),
          const SizedBox(height: AppSpacing.md),
          LicenseDateField(
            label: 'Expiry date',
            value: _expiryDate,
            enabled: !_isSaving,
            errorText: _errors['expiry'],
            onChanged: (value) => setState(() => _expiryDate = value),
          ),
          const SizedBox(height: AppSpacing.md),
          LicenseMoneyField(
            label: 'Negotiated price (one-time, INR)',
            controller: _negotiatedPrice,
            enabled: !_isSaving,
            errorText: _errors['negotiated'],
            helperText: 'Initial purchase price for this agreement.',
          ),
          const SizedBox(height: AppSpacing.md),
          LicenseMoneyField(
            label: 'Annual maintenance price (INR)',
            controller: _maintenancePrice,
            enabled: !_isSaving,
            errorText: _errors['maintenance'],
            helperText: 'Recurring yearly maintenance fee.',
          ),
        ],
      ),
    );
  }
}
