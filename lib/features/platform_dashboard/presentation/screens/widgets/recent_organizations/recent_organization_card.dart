import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/widgets/organization_metrics_row.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/widgets/recent_organizations/recent_organization_parts.dart';

/// Tablet card for one recent organization. Mirrors the Organizations tab card:
/// name with its code beneath and status at the top right, then the metrics
/// strip. The whole card opens the organization's details.
class RecentOrganizationCard extends StatelessWidget {
  const RecentOrganizationCard({super.key, required this.org});

  final RecentOrganizationSummary org;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppSpacing.roundedMd,
          onTap: () =>
              context.push(AppRoutes.platformOrganizationDetailsPath(org.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            org.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          OrganizationCodeBadge(code: org.code),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OrganizationStatusBadge(org: org),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                OrganizationMetricsRow(
                  hubCount: org.branchCount,
                  staffCount: org.employeeCount,
                  onboardedOn: org.createdAt,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Align(
                  alignment: Alignment.centerRight,
                  child: OrganizationDetailsLink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
