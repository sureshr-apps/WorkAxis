import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_form_section_card.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_form_state.dart';

/// "Organization Profile" section: name, tax id, address and summary.
class OrganizationProfileFields extends StatelessWidget {
  const OrganizationProfileFields({
    super.key,
    required this.form,
    required this.nameError,
    required this.onNameChanged,
  });

  static const int descriptionMaxLength = 300;
  static const int nameMaxLength = 100;

  final OrganizationFormState form;
  final String? nameError;
  final ValueChanged<String> onNameChanged;

  @override
  Widget build(BuildContext context) {
    return OrganizationFormSectionCard(
      icon: Icons.business_outlined,
      title: '1. Organization Profile',
      subtitle: 'Core identification identifiers for platform-wide operations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final nameField = AppTextField(
                controller: form.name,
                label: 'Organization Name *',
                hintText: 'e.g. Apex Global Logistics',
                errorText: nameError,
                maxLength: nameMaxLength,
                counterText: '',
                onChanged: onNameChanged,
              );
              final taxField = AppTextField(
                controller: form.taxIdentification,
                label: 'Tax Identification (Optional)',
                hintText: 'e.g. EIN, GSTIN, or VAT number',
                helperText:
                    'Optional tax registration identifier for invoicing and '
                    'legal compliance.',
                maxLength: 100,
                counterText: '',
              );
              if (constraints.maxWidth < AppBreakpoints.formSplit) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    nameField,
                    const SizedBox(height: AppSpacing.md),
                    taxField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: nameField),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(flex: 2, child: taxField),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: form.address,
            label: 'Headquarters Address',
            hintText: 'e.g. 742 Evergreen Logistics Blvd, Chicago, IL 60611',
            helperText: 'Primary operational center or corporate headquarters.',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Organization Scope & Summary (Optional)',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: form.description,
                builder: (context, value, _) => Text(
                  '${value.text.length} / $descriptionMaxLength',
                  style: AppTypography.labelMono.copyWith(
                    fontSize: 12,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            controller: form.description,
            hintText:
                'Brief summary of operational scope, regional coverage, or '
                'primary corridors...',
            maxLines: 3,
            maxLength: descriptionMaxLength,
            counterText: '',
          ),
        ],
      ),
    );
  }
}
