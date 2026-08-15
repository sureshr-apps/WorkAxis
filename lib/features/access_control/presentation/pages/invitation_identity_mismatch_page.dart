import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/utils/phone_number_formatter.dart';
import 'package:workaxis/features/access_control/presentation/widgets/access_state_view.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

class InvitationIdentityMismatchPage extends StatelessWidget {
  const InvitationIdentityMismatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orgController = context.watch<OrganizationContextController>();
    final state = orgController.state;

    String currentPhone = '';
    String invitedPhone = '';

    if (state is InvitationMismatchState) {
      currentPhone =
          PhoneNumberFormatter.maskPhoneNumber(state.authenticatedPhone);
      invitedPhone =
          PhoneNumberFormatter.maskPhoneNumber(state.invitation.invitedPhone);
    }

    return AccessStateView(
      title: 'Identity Mismatch',
      description:
          'You are currently signed in with $currentPhone, but this invitation was sent to $invitedPhone. Please sign in with the invited mobile number to proceed.',
      icon: Icons.person_off_rounded,
      iconColor: AppColors.error,
      primaryActionText: 'Switch Account',
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
