import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_icon_button.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';

/// Text scale above which the two header buttons stack instead of sharing a row.
const double _stackButtonsTextScale = 1.15;

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
    this.onDelete,
  });

  final CustomerOrganization organization;

  /// License plan label, or null while unassigned.
  final String? planName;
  final bool isActionLoading;
  final VoidCallback onEdit;
  final FutureOr<void> Function() onToggleStatus;
  final FutureOr<void> Function() onCopyCode;
  final FutureOr<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.detailsSplit;
        if (!isWide) {
          return _HeaderPanel(
            child: _StackedHeader(
              organization: organization,
              planName: planName,
              isActionLoading: isActionLoading,
              onEdit: onEdit,
              onToggleStatus: onToggleStatus,
              onCopyCode: onCopyCode,
              onDelete: onDelete,
            ),
          );
        }
        return _HeaderPanel(
          child: Row(
            children: [
              Expanded(
                child: _Identity(
                  organization: organization,
                  planName: planName,
                  onCopyCode: onCopyCode,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _Actions(
                organization: organization,
                isActionLoading: isActionLoading,
                onEdit: onEdit,
                onToggleStatus: onToggleStatus,
                onDelete: onDelete,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Phone and narrow-tablet layout.
///
/// Identity on top (avatar, name, status) with the delete icon in the corner;
/// code, created date and tier in a quiet strip; the two everyday actions as
/// equal-width buttons along the bottom.
class _StackedHeader extends StatelessWidget {
  const _StackedHeader({
    required this.organization,
    required this.planName,
    required this.isActionLoading,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onCopyCode,
    this.onDelete,
  });

  final CustomerOrganization organization;
  final String? planName;
  final bool isActionLoading;
  final VoidCallback onEdit;
  final FutureOr<void> Function() onToggleStatus;
  final FutureOr<void> Function() onCopyCode;
  final FutureOr<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final edit = AppButton.outlined(
      // Short label on phones: two equal buttons share the width.
      text: context.isCompact ? 'Edit' : 'Edit Organization',
      iconData: Icons.edit_outlined,
      onPressed: onEdit,
    );
    final status = AppButton.outlined(
      text: organization.isActive ? 'Suspend' : 'Reactivate',
      iconData: organization.isActive
          ? Icons.power_settings_new
          : Icons.refresh,
      onPressed: isActionLoading ? null : onToggleStatus,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(initials: organization.initials),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    organization.name,
                    style: AppTypography.headlineMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  _CopyableCode(code: organization.code, onCopy: onCopyCode),
                ],
              ),
            ),
            if (onDelete != null)
              _DeleteIconButton(
                organizationName: organization.name,
                onPressed: isActionLoading ? null : onDelete,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _MetadataStrip(
          createdAt: AppFormatters.formatDate(organization.createdAt),
          tier: planName ?? 'Unassigned',
        ),
        const SizedBox(height: AppSpacing.md),
        // Two equal buttons side by side; with large text they do not fit, so
        // they stack full width instead of squeezing their labels.
        if (MediaQuery.textScalerOf(context).scale(1) > _stackButtonsTextScale)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              edit,
              const SizedBox(height: AppSpacing.sm),
              status,
            ],
          )
        else
          Row(
            children: [
              Expanded(child: edit),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: status),
            ],
          ),
      ],
    );
  }
}

/// Delete shortcut in the top-right corner of the header. The action asks for
/// confirmation in a dialog before anything is removed.
class _DeleteIconButton extends StatelessWidget {
  const _DeleteIconButton({
    required this.organizationName,
    required this.onPressed,
  });

  final String organizationName;
  final FutureOr<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      tooltip: 'Delete $organizationName',
      onPressed: onPressed,
      icon: Icons.delete_outline,
      color: AppColors.statusUrgentText,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTouchTarget,
        minHeight: AppSpacing.minTouchTarget,
      ),
    );
  }
}

/// License tier on the left and created date right-aligned, as one quiet strip.
/// The wrap only breaks onto two lines when large text leaves no room.
class _MetadataStrip extends StatelessWidget {
  const _MetadataStrip({required this.createdAt, required this.tier});

  final String createdAt;
  final String tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(
          color: AppColors.outlineSubtle.withValues(alpha: 0.6),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Metadata(
            icon: Icons.workspace_premium_outlined,
            label: 'Tier: $tier',
          ),
          _Metadata(
            icon: Icons.calendar_today_outlined,
            label: 'Created $createdAt',
          ),
        ],
      ),
    );
  }
}

/// Organization code that copies itself when tapped.
class _CopyableCode extends StatelessWidget {
  const _CopyableCode({required this.code, required this.onCopy});

  final String code;
  final FutureOr<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Copy organization code',
      child: InkWell(
        onTap: onCopy,
        borderRadius: AppSpacing.roundedXs,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMono.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.copy_outlined,
                size: 14,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        initials,
        style: AppTypography.titleLarge.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.tertiary,
        ),
      ),
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
  final FutureOr<void> Function() onCopyCode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(initials: organization.initials),
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

/// Wide layout actions: edit, status and delete in one row.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.organization,
    required this.isActionLoading,
    required this.onEdit,
    required this.onToggleStatus,
    this.onDelete,
  });

  final CustomerOrganization organization;
  final bool isActionLoading;
  final VoidCallback onEdit;
  final FutureOr<void> Function() onToggleStatus;
  final FutureOr<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final edit = AppButton.outlined(
      text: 'Edit Organization',
      iconData: Icons.edit_outlined,
      onPressed: onEdit,
      isFullWidth: false,
    );
    final status = AppButton.outlined(
      text: organization.isActive ? 'Suspend' : 'Reactivate',
      iconData: organization.isActive
          ? Icons.power_settings_new
          : Icons.refresh,
      onPressed: isActionLoading ? null : onToggleStatus,
      isFullWidth: false,
    );
    final delete = onDelete != null
        ? AppIconButton(
            tooltip: 'Delete ${organization.name}',
            icon: Icons.delete_outline,
            color: AppColors.statusUrgentText,
            constraints: const BoxConstraints(
              minWidth: AppSpacing.minTouchTarget,
              minHeight: AppSpacing.minTouchTarget,
            ),
            onPressed: isActionLoading ? null : onDelete,
          )
        : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        edit,
        const SizedBox(width: AppSpacing.sm),
        status,
        if (delete != null) ...[const SizedBox(width: AppSpacing.xs), delete],
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
  final FutureOr<void> Function()? onCopy;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Flexible so a long code shrinks (with an ellipsis) instead of
      // overflowing in narrow columns or at large text sizes.
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border.all(color: AppColors.outlineSubtle),
            borderRadius: AppSpacing.roundedSm,
          ),
          child: Text(
            code,
            style: AppTypography.labelMono,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      if (onCopy != null)
        AppIconButton(
          tooltip: 'Copy organization code',
          onPressed: onCopy,
          icon: Icons.copy_outlined,
          color: AppColors.secondary,
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
