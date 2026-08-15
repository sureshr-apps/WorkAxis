import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/utils/phone_number_formatter.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

class InvitationAcceptancePage extends StatelessWidget {
  const InvitationAcceptancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orgController = context.watch<OrganizationContextController>();
    final state = orgController.state;

    if (state is! PendingInvitationState) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final invite = state.invitation;
    final maskedPhone =
        PhoneNumberFormatter.maskPhoneNumber(invite.invitedPhone);
    final formattedExpiry = DateFormat.yMMMd().format(invite.expiresAt);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Invitation to Join'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.marginMedium),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // Org Brand Badge
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppRadius.borderLg,
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.onPrimaryContainer,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    "You've been invited to join",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    invite.organizationName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Details Card
                  Card(
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderDefault,
                      side:
                          BorderSide(color: AppColors.outlineVariant, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          _DetailRow(
                            label: 'Role',
                            value: invite.invitedRole.displayName,
                            icon: Icons.badge_outlined,
                          ),
                          if (invite.branchName != null) ...[
                            const Divider(height: AppSpacing.md),
                            _DetailRow(
                              label: 'Assigned Branch',
                              value: invite.branchName!,
                              icon: Icons.storefront_outlined,
                            ),
                          ],
                          if (invite.invitedBy != null) ...[
                            const Divider(height: AppSpacing.md),
                            _DetailRow(
                              label: 'Invited By',
                              value: invite.invitedBy!,
                              icon: Icons.person_outline_rounded,
                            ),
                          ],
                          const Divider(height: AppSpacing.md),
                          _DetailRow(
                            label: 'Target Phone',
                            value: maskedPhone,
                            icon: Icons.phone_outlined,
                          ),
                          const Divider(height: AppSpacing.md),
                          _DetailRow(
                            label: 'Expires',
                            value: formattedExpiry,
                            icon: Icons.event_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    text: 'Accept & Join',
                    icon: const Icon(Icons.check_rounded, size: 20),
                    onPressed: () async {
                      await orgController.acceptInvitation(invite.id);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    text: 'Decline Invitation',
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      await orgController.declineInvitation(invite.id);
                      if (context.mounted) {
                        context.go('/access-denied');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
