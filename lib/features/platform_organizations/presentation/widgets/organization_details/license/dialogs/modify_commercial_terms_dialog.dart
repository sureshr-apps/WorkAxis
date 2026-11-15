import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_license_rules.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/license_dialog_frame.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/dialogs/license_form_fields.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_formatters.dart';

/// Changes the two prices only. Plan and dates stay as they are. Saving with no
/// change is refused here; the server would also make it a no-op.
class ModifyCommercialTermsDialog extends StatefulWidget {
  const ModifyCommercialTermsDialog({
    super.key,
    required this.organizationName,
    required this.license,
    required this.onSubmit,
  });

  final String organizationName;
  final OrganizationLicense license;
  final LicenseSubmit<ModifyCommercialTermsRequest> onSubmit;

  @override
  State<ModifyCommercialTermsDialog> createState() =>
      _ModifyCommercialTermsDialogState();
}

class _ModifyCommercialTermsDialogState
    extends State<ModifyCommercialTermsDialog> {
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

    final request = ModifyCommercialTermsRequest(
      negotiatedPrice: OrganizationLicenseRules.parseWholeRupees(
        _negotiatedPrice.text,
      )!,
      maintenancePrice: OrganizationLicenseRules.parseWholeRupees(
        _maintenancePrice.text,
      )!,
    );
    if (request.negotiatedPrice == widget.license.negotiatedPrice &&
        request.maintenancePrice == widget.license.maintenancePrice) {
      setState(() {
        _errors = const {};
        _submitError = 'Change at least one price before saving.';
      });
      return;
    }

    setState(() {
      _errors = const {};
      _submitError = null;
      _isSaving = true;
    });
    final failure = await widget.onSubmit(request);
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
  Widget build(BuildContext context) => LicenseDialogFrame(
    title: 'Modify Commercial Terms',
    submitLabel: 'Save Commercial Terms',
    isSaving: _isSaving,
    submitError: _submitError,
    onSubmit: _submit,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Negotiated pricing for ${widget.organizationName}. Plan and dates '
          'do not change.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        LicenseMoneyField(
          label: 'Negotiated price (one-time, INR)',
          controller: _negotiatedPrice,
          enabled: !_isSaving,
          errorText: _errors['negotiated'],
          helperText:
              'Current: ${LicenseFormatters.money(widget.license.negotiatedPrice)}',
        ),
        const SizedBox(height: AppSpacing.md),
        LicenseMoneyField(
          label: 'Annual maintenance price (INR)',
          controller: _maintenancePrice,
          enabled: !_isSaving,
          errorText: _errors['maintenance'],
          helperText:
              'Current: ${LicenseFormatters.money(widget.license.maintenancePrice)}',
        ),
      ],
    ),
  );
}
