import 'package:flutter/material.dart';
import 'package:workaxis/core/widgets/account_card/account_card.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_action_buttons.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/administrators/administrator_parts.dart';

/// Phone and tablet card for one administrator: identity and status, contact
/// details, then a labelled action row. Shares its layout with the platform
/// administrator card through [AccountCard].
class AdministratorCard extends StatelessWidget {
  const AdministratorCard({
    super.key,
    required this.administrator,
    required this.onAction,
    required this.canSuspend,
    required this.enabled,
  });

  final OrganizationAdminUser administrator;
  final AdministratorActionCallback onAction;
  final bool canSuspend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AccountCard(
      initials: administrator.initials,
      name: administrator.name,
      username: administrator.displayUsername,
      statusChip: AdministratorStatusChip(status: administrator.status),
      details: [
        AccountCardDetail(
          icon: Icons.mail_outline,
          value: orDash(administrator.email),
        ),
        AccountCardDetail(
          icon: Icons.call_outlined,
          value: orDash(administrator.phone),
        ),
        AccountCardDetail(
          icon: Icons.schedule_outlined,
          value: 'Last login: ${administrator.lastLogin ?? '—'}',
        ),
      ],
      footer: AdministratorActionButtons(
        administrator: administrator,
        onAction: onAction,
        canSuspend: canSuspend,
        enabled: enabled,
        labelled: true,
      ),
    );
  }
}
