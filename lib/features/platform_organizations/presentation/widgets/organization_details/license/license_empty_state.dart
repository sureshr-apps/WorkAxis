import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_shared_widgets.dart';

/// Shown when an organization has no license agreement yet.
class OrganizationLicenseEmptyState extends StatelessWidget {
  const OrganizationLicenseEmptyState({
    super.key,
    required this.onAssignLicense,
  });

  final VoidCallback onAssignLicense;

  @override
  Widget build(BuildContext context) => LicensePanel(
    child: Padding(
      padding: EdgeInsets.all(
        context.isCompact ? AppSpacing.lg : AppSpacing.xxl,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: AppSpacing.roundedSm,
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: EmptyState(
          icon: Icons.vpn_key_outlined,
          title: 'No license assigned',
          message:
              'This organization does not currently have an assigned license '
              'agreement. Platform usage limits (Maximum Stores and Maximum '
              'Users) are not established until a license plan is '
              'provisioned.',
          action: AppButton.responsive(
            text: 'Assign License',
            variant: AppButtonVariant.outlined,
            onPressed: onAssignLicense,
          ),
        ),
      ),
    ),
  );
}
