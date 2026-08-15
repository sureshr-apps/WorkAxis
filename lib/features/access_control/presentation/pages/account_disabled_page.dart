import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/features/access_control/presentation/widgets/access_state_view.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

class AccountDisabledPage extends StatelessWidget {
  const AccountDisabledPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessStateView(
      title: 'Account Disabled',
      description:
          'Your WorkAxis account has been deactivated. If you believe this is an error, please contact your organization administrator or WorkAxis Support.',
      icon: Icons.account_circle_outlined,
      iconColor: AppColors.statusDisabled,
      primaryActionText: 'Sign Out',
      onPrimaryAction: () async {
        await context.read<AuthController>().signOut();
        if (context.mounted) {
          context.read<OrganizationContextController>().clear();
          context.go('/welcome');
        }
      },
    );
  }
}
