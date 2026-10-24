import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';

enum PlatformAdministratorAction { view, edit, suspend, restore }

class PlatformAdministratorActionMenu extends StatelessWidget {
  const PlatformAdministratorActionMenu({
    super.key,
    required this.administrator,
    required this.onSelected,
  });

  final PlatformAdministrator administrator;
  final ValueChanged<PlatformAdministratorAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PlatformAdministratorAction>(
      tooltip: 'Administrator actions',
      onSelected: onSelected,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: PlatformAdministratorAction.view,
          child: Text('View details'),
        ),
        const PopupMenuItem(
          value: PlatformAdministratorAction.edit,
          child: Text('Edit profile'),
        ),
        if (administrator.status == AccountStatus.active)
          const PopupMenuItem(
            value: PlatformAdministratorAction.suspend,
            child: Text(
              'Suspend access',
              style: TextStyle(color: AppColors.statusUrgentText),
            ),
          )
        else
          const PopupMenuItem(
            value: PlatformAdministratorAction.restore,
            child: Text('Restore access'),
          ),
      ],
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.more_vert, semanticLabel: 'Administrator actions'),
      ),
    );
  }
}
