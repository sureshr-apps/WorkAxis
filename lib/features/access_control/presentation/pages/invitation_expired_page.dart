import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/features/access_control/presentation/widgets/access_state_view.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

class InvitationExpiredPage extends StatelessWidget {
  const InvitationExpiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessStateView(
      title: 'Invitation Expired',
      description:
          'This invitation link has expired. Please contact your organization administrator to receive a new invite link.',
      icon: Icons.history_toggle_off_rounded,
      iconColor: AppColors.statusPending,
      primaryActionText: 'Sign Out',
      onPrimaryAction: () async {
        await context.read<AuthController>().signOut();
        if (context.mounted) {
          context.read<OrganizationContextController>().clear();
          context.go('/welcome');
        }
      },
      secondaryActionText: 'Try Another Account',
      onSecondaryAction: () async {
        await context.read<AuthController>().signOut();
        if (context.mounted) {
          context.read<OrganizationContextController>().clear();
          context.go('/signin/phone');
        }
      },
    );
  }
}
