import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_form_section_card.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_form_state.dart';

/// "Operational Contact" section: contact name, email and phone.
class OrganizationContactFields extends StatelessWidget {
  const OrganizationContactFields({
    super.key,
    required this.form,
    required this.emailError,
    required this.phoneError,
  });

  final OrganizationFormState form;
  final String? emailError;
  final String? phoneError;

  @override
  Widget build(BuildContext context) {
    return OrganizationFormSectionCard(
      icon: Icons.contact_mail_outlined,
      iconBackground: AppColors.surfaceContainerHigh,
      iconColor: AppColors.onSurface,
      title: '2. Operational Contact',
      subtitle:
          'Designated point of contact for platform notices and coordination',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fields = [
            AppTextField(
              controller: form.contactName,
              label: 'Contact Person Name',
              hintText: 'e.g. Marcus Sterling',
              helperText: 'Regional Director or Ops Lead',
            ),
            AppTextField(
              controller: form.contactEmail,
              label: 'Contact Email',
              hintText: 'operations@example.com',
              errorText: emailError,
              keyboardType: TextInputType.emailAddress,
            ),
            AppTextField(
              controller: form.contactPhone,
              label: 'Contact Phone Number',
              hintText: '+91 98765 43210',
              helperText: 'Include the country code',
              errorText: phoneError,
              keyboardType: TextInputType.phone,
            ),
          ];
          if (constraints.maxWidth < AppBreakpoints.formSplit) {
            return Column(
              children: [
                for (var i = 0; i < fields.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  fields[i],
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: fields[i]),
              ],
            ],
          );
        },
      ),
    );
  }
}
