import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/table_header_cell.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/widgets/recent_organizations/recent_organization_parts.dart';

const double _actionsWidth = 80;

/// Header row for the desktop table.
class RecentOrganizationsTableHeader extends StatelessWidget {
  const RecentOrganizationsTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          const TableHeaderCell('ORGANIZATION', flex: 3),
          const TableHeaderCell('CODE', flex: 2),
          const TableHeaderCell('STATUS', flex: 2),
          const TableHeaderCell('BRANCHES', flex: 2),
          const TableHeaderCell('STAFF', flex: 2),
          const TableHeaderCell('ADMIN CONTACT', flex: 3),
          SizedBox(
            width: _actionsWidth,
            child: Text(
              'ACTIONS',
              textAlign: TextAlign.right,
              maxLines: 1,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _rowDivider(bool isLast) => BoxDecoration(
  border: isLast
      ? null
      : const Border(bottom: BorderSide(color: AppColors.outlineSubtle)),
);

/// Desktop table row.
class RecentOrganizationDesktopRow extends StatelessWidget {
  const RecentOrganizationDesktopRow({
    super.key,
    required this.org,
    required this.isLast,
  });

  final RecentOrganizationSummary org;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          context.push(AppRoutes.platformOrganizationDetailsPath(org.id)),
      child: Container(
        decoration: _rowDivider(isLast),
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Created ${AppFormatters.formatDate(org.createdAt)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: OrganizationCodeBadge(code: org.code),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: OrganizationStatusBadge(org: org),
              ),
            ),
            Expanded(
              flex: 2,
              child: _CountCell(
                icon: Icons.storefront_outlined,
                count: org.branchCount,
                unit: 'branches',
              ),
            ),
            Expanded(
              flex: 2,
              child: _CountCell(
                icon: Icons.people_outline,
                count: org.employeeCount,
                unit: 'staff',
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  const Icon(
                    Icons.mail_outline,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      org.adminEmail ?? '—',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: _actionsWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: OrganizationDetailsLink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountCell extends StatelessWidget {
  const _CountCell({
    required this.icon,
    required this.count,
    required this.unit,
  });

  final IconData icon;
  final int count;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text.rich(
            TextSpan(
              text: '$count',
              style: AppTypography.labelMono.copyWith(
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: ' $unit',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Phone row.
class RecentOrganizationCompactRow extends StatelessWidget {
  const RecentOrganizationCompactRow({
    super.key,
    required this.org,
    required this.isLast,
  });

  final RecentOrganizationSummary org;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          context.push(AppRoutes.platformOrganizationDetailsPath(org.id)),
      child: Container(
        decoration: _rowDivider(isLast),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OrganizationCodeBadge(code: org.code),
                OrganizationStatusBadge(org: org),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              org.name,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            OrganizationCountsText(org: org),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    org.adminEmail ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const OrganizationDetailsLink(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
