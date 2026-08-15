import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/features/access_control/presentation/widgets/access_state_view.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

class OrganizationUnavailablePage extends StatelessWidget {
  const OrganizationUnavailablePage({super.key});

  @override
  Widget build(BuildContext context) {
    final orgController = context.watch<OrganizationContextController>();
    final state = orgController.state;

    String orgName = 'The organization';
    bool hasOtherOrgs = false;

    if (state is OrganizationUnavailableState) {
      orgName = state.organization.name;
      hasOtherOrgs = state.otherMemberships.isNotEmpty;
    }

    return AccessStateView(
      title: 'Organization Unavailable',
      description:
          '$orgName is currently suspended or undergoing scheduled maintenance. Access to this workspace is temporarily restricted.',
      icon: Icons.domain_disabled_rounded,
      iconColor: AppColors.error,
      primaryActionText:
          hasOtherOrgs ? 'Choose Another Organization' : 'Sign Out',
      onPrimaryAction: () async {
        if (hasOtherOrgs) {
          context.go('/organizations');
        } else {
          await context.read<AuthController>().signOut();
          if (context.mounted) {
            orgController.clear();
            context.go('/welcome');
          }
        }
      },
      secondaryActionText: hasOtherOrgs ? 'Sign Out' : null,
      onSecondaryAction: () async {
        await context.read<AuthController>().signOut();
        if (context.mounted) {
          orgController.clear();
          context.go('/welcome');
        }
      },
    );
  }
}
