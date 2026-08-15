import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/features/access_control/presentation/widgets/access_state_view.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orgController = context.watch<OrganizationContextController>();
    final state = orgController.state;

    String reason = 'Your account is not authorized to access WorkAxis.';
    if (state is AccessDeniedState) {
      reason = state.reason;
    }

    return AccessStateView(
      title: 'Access Denied',
      description: reason,
      icon: Icons.gpp_bad_rounded,
      iconColor: AppColors.error,
      primaryActionText: 'Try Another Account',
      onPrimaryAction: () async {
        await context.read<AuthController>().signOut();
        if (context.mounted) {
          context.read<OrganizationContextController>().clear();
          context.go('/signin/phone');
        }
      },
      secondaryActionText: 'Sign Out',
      onSecondaryAction: () async {
        await context.read<AuthController>().signOut();
        if (context.mounted) {
          context.read<OrganizationContextController>().clear();
          context.go('/welcome');
        }
      },
    );
  }
}
