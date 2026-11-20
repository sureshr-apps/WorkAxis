import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/core/widgets/account_card/account_card.dart';
import 'package:workaxis/core/widgets/account_card/account_card_actions.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/administrator_activity_label.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_action_menu.dart';

/// Card for one platform administrator. Uses the same [AccountCard] layout and
/// labelled actions as the organization administrator card.
class PlatformAdministratorCard extends StatelessWidget {
  const PlatformAdministratorCard({
    super.key,
    required this.administrator,
    required this.onTap,
    required this.onAction,
    this.now = systemNow,
  });

  final PlatformAdministrator administrator;
  final VoidCallback onTap;
  final FutureOr<void> Function(PlatformAdministratorAction) onAction;

  /// Clock used for the relative "last active" text.
  final Now now;

  @override
  Widget build(BuildContext context) {
    final isActive = administrator.status == AccountStatus.active;

    return AccountCard(
      initials: administrator.initials,
      name: administrator.fullName,
      username: administrator.username,
      statusChip: StatusChip(
        label: isActive ? 'ACTIVE' : 'SUSPENDED',
        type: isActive ? StatusType.active : StatusType.urgent,
      ),
      details: [
        AccountCardDetail(
          icon: Icons.mail_outline,
          value: administrator.email.isEmpty ? '—' : administrator.email,
        ),
        AccountCardDetail(
          icon: Icons.call_outlined,
          value: administrator.phone ?? '—',
        ),
        AccountCardDetail(
          icon: Icons.schedule_outlined,
          value: AdministratorActivityLabel.sentence(
            administrator.lastActiveAt,
            now(),
          ),
        ),
      ],
      footer: AccountCardActions(
        actions: [
          AccountCardAction(
            label: 'Edit',
            icon: Icons.edit_outlined,
            color: AppColors.secondary,
            onPressed: () => onAction(PlatformAdministratorAction.edit),
          ),
          AccountCardAction(
            label: 'Reset Password',
            icon: Icons.key_outlined,
            color: AppColors.secondary,
            onPressed: () =>
                onAction(PlatformAdministratorAction.resetPassword),
          ),
          if (isActive)
            AccountCardAction(
              label: 'Suspend',
              icon: Icons.person_off_outlined,
              color: AppColors.statusUrgentText,
              onPressed: () => onAction(PlatformAdministratorAction.suspend),
            )
          else
            AccountCardAction(
              label: 'Restore',
              icon: Icons.how_to_reg_outlined,
              color: AppColors.kpiPositive,
              onPressed: () => onAction(PlatformAdministratorAction.restore),
            ),
          AccountCardAction(
            label: 'Delete',
            icon: Icons.delete_outline,
            color: AppColors.statusUrgentText,
            onPressed: () => onAction(PlatformAdministratorAction.delete),
          ),
        ],
      ),
      onTap: onTap,
      onTapLabel: 'View details for ${administrator.fullName}',
    );
  }
}
