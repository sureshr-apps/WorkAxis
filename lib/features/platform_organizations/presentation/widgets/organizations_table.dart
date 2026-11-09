import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/core/widgets/table_header_cell.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';

const double _rowHorizontalPadding = AppSpacing.lg;

/// Sliver table of customer organizations for wide layouts.
///
/// Rows are built lazily. The footer reports how many rows are loaded and
/// offers "Load more" when the server has further pages. Must be placed in a
/// `CustomScrollView`.
class OrganizationsTable extends StatelessWidget {
  const OrganizationsTable({
    super.key,
    required this.organizations,
    required this.onSelect,
    required this.onEdit,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final List<CustomerOrganization> organizations;
  final ValueChanged<CustomerOrganization> onSelect;
  final ValueChanged<CustomerOrganization> onEdit;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return DecoratedSliver(
      decoration: BoxDecoration(
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppShadows.card,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          const SliverToBoxAdapter(child: _TableHeader()),
          SliverList.builder(
            itemCount: organizations.length,
            itemBuilder: (context, index) => _OrganizationRow(
              organization: organizations[index],
              onSelect: () => onSelect(organizations[index]),
              onEdit: () => onEdit(organizations[index]),
            ),
          ),
          SliverToBoxAdapter(
            child: _TableFooter(
              loadedCount: organizations.length,
              hasMore: hasMore,
              isLoadingMore: isLoadingMore,
              onLoadMore: onLoadMore,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: _rowHorizontalPadding),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusMd),
          topRight: Radius.circular(AppSpacing.radiusMd),
        ),
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.outlineSubtle),
        ),
      ),
      child: const Row(
        children: [
          TableHeaderCell('ORGANIZATION', flex: 3),
          TableHeaderCell('CODE', flex: 2),
          TableHeaderCell('STATUS', flex: 2),
          TableHeaderCell('BRANCHES', flex: 2),
          TableHeaderCell('EMPLOYEES', flex: 2),
          TableHeaderCell('ONBOARDED', flex: 2),
          TableHeaderCell('ACTIONS', flex: 3, alignment: Alignment.centerRight),
        ],
      ),
    );
  }
}

class _OrganizationRow extends StatelessWidget {
  const _OrganizationRow({
    required this.organization,
    required this.onSelect,
    required this.onEdit,
  });

  final CustomerOrganization organization;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final org = organization;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          left: BorderSide(color: AppColors.outlineSubtle),
          right: BorderSide(color: AppColors.outlineSubtle),
          bottom: BorderSide(color: AppColors.outlineSubtle),
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        hoverColor: AppColors.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _rowHorizontalPadding,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  org.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _CodeBadge(code: org.code),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusChip.fromStatus(
                    org.status.displayName,
                    width: 96,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: _CountCell(count: org.branchCount, unit: 'hubs'),
              ),
              Expanded(
                flex: 2,
                child: _CountCell(count: org.employeeCount, unit: 'staff'),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  AppFormatters.formatDate(org.createdAt),
                  style: AppTypography.bodySmall,
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Edit ${org.name}',
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      onPressed: onEdit,
                    ),
                    Text(
                      'Details',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Text(
        code,
        style: AppTypography.labelMono.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CountCell extends StatelessWidget {
  const _CountCell({required this.count, required this.unit});

  final int? count;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTypography.bodyMedium,
        children: [
          TextSpan(
            text: count == null ? '—' : AppFormatters.formatNumber(count!),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: ' $unit',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableFooter extends StatelessWidget {
  const _TableFooter({
    required this.loadedCount,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final int loadedCount;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _rowHorizontalPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusMd),
          bottomRight: Radius.circular(AppSpacing.radiusMd),
        ),
        border: Border(
          left: BorderSide(color: AppColors.outlineSubtle),
          right: BorderSide(color: AppColors.outlineSubtle),
          bottom: BorderSide(color: AppColors.outlineSubtle),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $loadedCount organizations${hasMore ? ' (more available)' : ''}',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.secondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasMore)
            AppButton.outlined(
              text: 'Load more',
              isFullWidth: false,
              isLoading: isLoadingMore,
              onPressed: onLoadMore,
            ),
        ],
      ),
    );
  }
}
