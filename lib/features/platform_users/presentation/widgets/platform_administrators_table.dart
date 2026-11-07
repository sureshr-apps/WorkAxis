import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_shadows.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/core/widgets/table_header_cell.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/administrator_activity_label.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_action_menu.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_avatar.dart';

/// Dense desktop table following the existing WorkAxis Organizations catalog.
class PlatformAdministratorsTable extends StatelessWidget {
  const PlatformAdministratorsTable({
    super.key,
    required this.administrators,
    required this.onSelect,
    this.onAction,
    this.now = systemNow,
  });

  final List<PlatformAdministrator> administrators;
  final ValueChanged<PlatformAdministrator> onSelect;
  final void Function(
    PlatformAdministrator administrator,
    PlatformAdministratorAction action,
  )?
  onAction;

  /// Clock used for the relative "last active" text.
  final Now now;

  static const double _minimumTableWidth = 1060;
  static const double _actionsWidth = 80;

  @override
  Widget build(BuildContext context) {
    final currentTime = now();
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
                  .clamp(_minimumTableWidth, double.infinity)
                  .toDouble()
            : _minimumTableWidth;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.outlineSubtle),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              key: const ValueKey('platform-administrators-table-content'),
              width: tableWidth,
              child: Column(
                children: [
                  const _Header(),
                  for (var i = 0; i < administrators.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.outlineSubtle,
                      ),
                    _Row(
                      administrator: administrators[i],
                      now: currentTime,
                      onTap: () => onSelect(administrators[i]),
                    ),
                  ],
                  _Footer(count: administrators.length),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      color: AppColors.surfaceContainerLow,
      alignment: Alignment.center,
      child: const Row(
        children: [
          TableHeaderCell('USER', flex: 3),
          TableHeaderCell('SIGN-IN IDENTIFIERS', flex: 4),
          TableHeaderCell('STATUS', flex: 2),
          TableHeaderCell('LAST ACTIVE', flex: 2),
          TableHeaderCell('CREATED', flex: 2),
          SizedBox(width: PlatformAdministratorsTable._actionsWidth),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.administrator,
    required this.now,
    required this.onTap,
  });

  final PlatformAdministrator administrator;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusLabel = administrator.status == AccountStatus.active
        ? 'Active'
        : 'Suspended';
    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.surfaceContainerLow,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    PlatformAdministratorAvatar(
                      initials: administrator.initials,
                      size: 38,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            administrator.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Platform Administrator',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      administrator.email.isEmpty ? '—' : administrator.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium,
                    ),
                    Text(
                      '@${administrator.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusChip.fromStatus(statusLabel),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  AdministratorActivityLabel.short(
                    administrator.lastActiveAt,
                    now,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  AppFormatters.formatDate(administrator.createdAt),
                  style: AppTypography.bodySmall,
                ),
              ),
              SizedBox(
                width: PlatformAdministratorsTable._actionsWidth,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Details',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(top: BorderSide(color: AppColors.outlineSubtle)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        'Showing $count platform administrators',
        style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
      ),
    );
  }
}
