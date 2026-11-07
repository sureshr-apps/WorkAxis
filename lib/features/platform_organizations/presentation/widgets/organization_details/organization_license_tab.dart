import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_details_panel.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_history_panel.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_summary_card.dart';

export 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_empty_state.dart';

/// License tab of the organization details: summary, entitlements and
/// commercial agreement, and the license event history.
class OrganizationLicenseTab extends StatelessWidget {
  const OrganizationLicenseTab({
    super.key,
    required this.license,
    required this.onAction,
    this.now = systemNow,
  });

  final OrganizationLicenseDetails license;
  final ValueChanged<String> onAction;

  /// Source of "today" for the expiry label; inject a fixed clock in tests.
  final Now now;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LicenseSummaryCard(license: license, today: now(), onAction: onAction),
        const SizedBox(height: AppSpacing.md),
        LicenseDetailsPanel(license: license),
        const SizedBox(height: AppSpacing.md),
        LicenseHistoryPanel(license: license),
      ],
    );
  }
}
