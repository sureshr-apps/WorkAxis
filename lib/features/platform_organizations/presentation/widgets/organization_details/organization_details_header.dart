import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';

/// Breadcrumb row: back link, organization name and code.
class OrganizationDetailsBreadcrumb extends StatelessWidget {
  const OrganizationDetailsBreadcrumb({
    super.key,
    required this.organization,
    required this.onBack,
  });

  final CustomerOrganization organization;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: AppSpacing.roundedXs,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Organizations',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Icon(
          Icons.chevron_right,
          size: 16,
          color: AppColors.outlineVariant,
        ),
        Text(
          organization.name,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        _CodeBadge(code: organization.code),
      ],
    );
  }
}

/// Identity, status and actions of the selected organization.
class OrganizationDetailsHeader extends StatelessWidget {
  const OrganizationDetailsHeader({
    super.key,
    required this.organization,
    required this.planName,
    required this.isActionLoading,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onCopyCode,
  });

  final CustomerOrganization organization;

  /// License plan label, or null while unassigned.
  final String? planName;
  final bool isActionLoading;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onCopyCode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.detailsSplit;
        final identity = _Identity(
          organization: organization,
          planName: planName,
          onCopyCode: onCopyCode,
        );
        final actions = _Actions(
          organization: organization,
          isWide: isWide,
          isActionLoading: isActionLoading,
          onEdit: onEdit,
          onToggleStatus: onToggleStatus,
        );
        return _HeaderPanel(
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: AppSpacing.md),
                    actions,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    const SizedBox(height: AppSpacing.md),
                    actions,
                  ],
                ),
        );
      },
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({
    required this.organization,
    required this.planName,
    required this.onCopyCode,
  });

  final CustomerOrganization organization;
  final String? planName;
  final VoidCallback onCopyCode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.tertiaryContainer.withValues(alpha: 0.25),
            ),
            borderRadius: AppSpacing.roundedSm,
          ),
          child: Text(
            organization.initials,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.tertiary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  Text(
                    organization.name,
                    style: context.isCompact
                        ? AppTypography.headlineMedium
                        : AppTypography.headlineLarge,
                  ),
                  _CodeBadge(code: organization.code, onCopy: onCopyCode),
                  StatusChip(
                    label: organization.status.displayName.toUpperCase(),
                    type: organization.isActive
                        ? StatusType.active
                        : StatusType.urgent,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                children: [
                  _Metadata(
                    icon: Icons.calendar_today_outlined,
                    label:
                        'Created ${AppFormatters.formatDate(organization.createdAt)}',
                  ),
                  _Metadata(label: 'Tier: ${planName ?? 'Unassigned'}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.organization,
    required this.isWide,
    required this.isActionLoading,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final CustomerOrganization organization;
  final bool isWide;
  final bool isActionLoading;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final edit = AppButton.outlined(
      text: 'Edit Organization',
      iconData: Icons.edit_outlined,
      onPressed: onEdit,
      isFullWidth: !isWide,
    );
    final status = AppButton.outlined(
      text: organization.isActive ? 'Suspend' : 'Reactivate',
      iconData: organization.isActive
          ? Icons.power_settings_new
          : Icons.refresh,
      onPressed: isActionLoading ? null : onToggleStatus,
      isFullWidth: !isWide,
    );
    if (!isWide) {
      return Row(
        children: [
          Expanded(child: edit),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: status),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        edit,
        const SizedBox(width: AppSpacing.sm),
        status,
      ],
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({this.icon, required this.label});

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.xs),
      ],
      Flexible(
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
        ),
      ),
    ],
  );
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code, this.onCopy});

  final String code;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          border: Border.all(color: AppColors.outlineSubtle),
          borderRadius: AppSpacing.roundedSm,
        ),
        child: Text(code, style: AppTypography.labelMono),
      ),
      if (onCopy != null)
        IconButton(
          tooltip: 'Copy organization code',
          onPressed: onCopy,
          icon: const Icon(
            Icons.copy_outlined,
            size: 16,
            color: AppColors.secondary,
          ),
          constraints: const BoxConstraints(
            minWidth: AppSpacing.minTouchTarget,
            minHeight: AppSpacing.minTouchTarget,
          ),
        ),
    ],
  );
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(context.isCompact ? AppSpacing.md : AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      border: Border.all(color: AppColors.outlineSubtle),
      borderRadius: AppSpacing.roundedMd,
      boxShadow: AppShadows.card,
    ),
    child: child,
  );
}
