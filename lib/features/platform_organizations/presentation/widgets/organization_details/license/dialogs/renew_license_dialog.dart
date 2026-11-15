import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_license_rules.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/license_dialog_frame.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/license_form_fields.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_formatters.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_shared_widgets.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// Starts a new term after the current expiry. Defaults: start the day after
/// the current expiry, end one year later. Plans may keep the current level or
/// move up, never down.
class RenewLicenseDialog extends StatefulWidget {
  const RenewLicenseDialog({
    super.key,
    required this.organizationName,
    required this.license,
    required this.activePlans,
    required this.onSubmit,
  });

  final String organizationName;
  final OrganizationLicense license;
  final List<LicensePlan> activePlans;
  final LicenseSubmit<RenewLicenseRequest> onSubmit;

  @override
  State<RenewLicenseDialog> createState() => _RenewLicenseDialogState();
}

class _RenewLicenseDialogState extends State<RenewLicenseDialog> {
  late final List<LicensePlan> _plans = OrganizationLicenseRules.renewalPlans(
    widget.activePlans,
    widget.license.plan.level,
  );
  late String? _planId = _initialPlanId();
  late DateTime _startDate = OrganizationLicenseRules.defaultRenewalStart(
    widget.license.expiryDate,
  );
  late DateTime _expiryDate = OrganizationLicenseRules.defaultTermExpiry(
    _startDate,
  );
  late final TextEditingController _negotiatedPrice = TextEditingController(
    text: widget.license.negotiatedPrice.round().toString(),
  );
  late final TextEditingController _maintenancePrice = TextEditingController(
    text: widget.license.maintenancePrice.round().toString(),
  );

  Map<String, String> _errors = const {};
  String? _submitError;
  bool _isSaving = false;

  String? _initialPlanId() {
    final current = widget.license.plan.id;
    if (_plans.any((plan) => plan.id == current)) return current;
    return _plans.isEmpty ? null : _plans.first.id;
  }

  @override
  void dispose() {
    _negotiatedPrice.dispose();
    _maintenancePrice.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final errors = <String, String>{};
    final planId = _planId;
    if (planId == null) {
      errors['plan'] = 'Select a license plan for renewal.';
    }
    final termError = OrganizationLicenseRules.renewalTermError(
      currentExpiry: widget.license.expiryDate,
      newStart: _startDate,
      newExpiry: _expiryDate,
    );
    if (termError != null) {
      if (_startDate.isAfter(widget.license.expiryDate)) {
        errors['expiry'] = termError;
      } else {
        errors['start'] = termError;
      }
    }
    final negotiatedError = OrganizationLicenseRules.priceError(
      _negotiatedPrice.text,
      fieldName: 'renewal price',
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
      RenewLicenseRequest(
        planId: planId!,
        newStartDate: _startDate,
        newExpiryDate: _expiryDate,
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
    final license = widget.license;
    final selectedPlan = _plans.where((plan) => plan.id == _planId).firstOrNull;
    final continues = OrganizationLicenseRules.continuesRunningTerm(
      license,
      _startDate,
    );
    return LicenseDialogFrame(
      title: 'Renew License Agreement',
      submitLabel: 'Confirm Renewal',
      isSaving: _isSaving,
      submitError: _submitError,
      submitEnabled: _plans.isNotEmpty,
      onSubmit: _submit,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Provision a new period for ${widget.organizationName}.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          LicenseInsetCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Current plan: ${license.plan.name}',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    'Expires ${LicenseFormatters.date(license.expiryDate)}',
                    textAlign: TextAlign.end,
                    style: AppTypography.labelMono,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_plans.isEmpty)
            Text(
              'No active plan at or above the current level is available for '
              'renewal.',
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
            label: 'New start date',
            value: _startDate,
            enabled: !_isSaving,
            errorText: _errors['start'],
            helperText: 'Defaults to the day after the current expiry.',
            onChanged: (value) => setState(() => _startDate = value),
          ),
          const SizedBox(height: AppSpacing.md),
          LicenseDateField(
            label: 'New expiry date',
            value: _expiryDate,
            enabled: !_isSaving,
            errorText: _errors['expiry'],
            helperText: 'Must be after the new start date.',
            onChanged: (value) => setState(() => _expiryDate = value),
          ),
          if (continues) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This continues the running term: the current start date is kept '
              'and the expiry is extended.',
              style: licenseBodyStyle,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          LicenseMoneyField(
            label: 'Negotiated renewal price (one-time, INR)',
            controller: _negotiatedPrice,
            enabled: !_isSaving,
            errorText: _errors['negotiated'],
          ),
          const SizedBox(height: AppSpacing.md),
          LicenseMoneyField(
            label: 'Annual maintenance price (INR)',
            controller: _maintenancePrice,
            enabled: !_isSaving,
            errorText: _errors['maintenance'],
            helperText:
                'Recurring yearly maintenance fee for the renewed term.',
          ),
        ],
      ),
    );
  }
}
