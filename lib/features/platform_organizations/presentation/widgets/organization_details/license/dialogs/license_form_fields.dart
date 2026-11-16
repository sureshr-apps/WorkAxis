import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/time/calendar_date.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/app_date_picker_field.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_formatters.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_shared_widgets.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

/// Saves a license request; resolves to a message to show, or null on success.
typedef LicenseSubmit<T> = Future<String?> Function(T request);

/// Plan picker over the given plans (already filtered by the caller).
class LicensePlanField extends StatelessWidget {
  const LicensePlanField({
    super.key,
    required this.plans,
    required this.selectedPlanId,
    required this.onChanged,
    required this.enabled,
    this.errorText,
  });

  final List<LicensePlan> plans;
  final String? selectedPlanId;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final selected = plans.any((plan) => plan.id == selectedPlanId)
        ? selectedPlanId
        : null;
    return DropdownButtonFormField<String>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'License plan',
        errorText: errorText,
      ),
      items: [
        for (final plan in plans)
          DropdownMenuItem(
            value: plan.id,
            child: Text(
              '${plan.name} · Level ${plan.level} · ${plan.maxStores} stores · '
              '${plan.maxUsers} users',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: enabled && plans.isNotEmpty ? onChanged : null,
    );
  }
}

/// Read-only entitlements of the selected plan.
class LicensePlanEntitlements extends StatelessWidget {
  const LicensePlanEntitlements({super.key, required this.plan});

  final LicensePlan plan;

  @override
  Widget build(BuildContext context) => LicenseInsetCard(
    child: Row(
      children: [
        Expanded(
          child: _Entitlement(
            label: 'Maximum Stores',
            value: '${plan.maxStores}',
            icon: Icons.storefront_outlined,
          ),
        ),
        Expanded(
          child: _Entitlement(
            label: 'Maximum Users',
            value: '${plan.maxUsers}',
            icon: Icons.people_outline,
          ),
        ),
      ],
    ),
  );
}

class _Entitlement extends StatelessWidget {
  const _Entitlement({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: AppSpacing.sm),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: licenseLabelStyle),
            Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Calendar-date field. Shows and returns `yyyy-MM-dd` calendar dates.
class LicenseDateField extends StatelessWidget {
  const LicenseDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.enabled,
    this.errorText,
    this.helperText,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      AppPickerField(
        label: label,
        valueText: LicenseFormatters.date(value),
        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        enabled: enabled,
        errorText: errorText,
        onTap: () => _pick(context),
      ),
      if (helperText != null && errorText == null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(helperText!, style: licenseBodyStyle),
      ],
    ],
  );

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onChanged(CalendarDate.of(picked));
  }
}

/// Whole-rupee amount field.
class LicenseMoneyField extends StatelessWidget {
  const LicenseMoneyField({
    super.key,
    required this.label,
    required this.controller,
    required this.enabled,
    this.errorText,
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) => AppTextField(
    controller: controller,
    label: label,
    hintText: 'e.g. 75000',
    helperText: errorText == null ? helperText : null,
    errorText: errorText,
    enabled: enabled,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    prefixText: '₹ ',
  );
}

/// Label/value line used in the dialogs' comparison blocks.
class LicenseTermRow extends StatelessWidget {
  const LicenseTermRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label, style: licenseBodyStyle)),
        // Flexible lets long values (periods at large text) wrap, not overflow.
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    ),
  );
}
