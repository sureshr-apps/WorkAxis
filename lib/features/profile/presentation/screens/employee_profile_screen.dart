import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/session/session_controller.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/features/profile/presentation/screens/widgets/change_password_card.dart';
import 'package:workaxis/features/profile/presentation/screens/widgets/profile_identity_card.dart';
import 'package:workaxis/features/profile/presentation/screens/widgets/profile_section_card.dart';

/// Profile of the signed-in user. Every value comes from the resolved access
/// context; nothing is invented for fields the backend does not provide.
class EmployeeProfileScreen extends StatelessWidget {
  const EmployeeProfileScreen({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      // A plain Dialog (not AlertDialog): AlertDialog lays its content out
      // with intrinsic sizing, which AppButton's LayoutBuilder cannot support.
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sign Out', style: AppTypography.headlineMedium),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Are you sure you want to end your current session?',
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outlined(
                        text: 'Cancel',
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton.primary(
                        text: 'Sign Out',
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<SessionController>().signOut();
      if (context.mounted) context.go(AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AccessController>().accessContext;
    final user = access?.user;
    final signOut = AppButton.responsive(
      text: 'Sign Out',
      iconData: Icons.logout,
      variant: AppButtonVariant.outlined,
      onPressed: () => _handleSignOut(context),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPageHeader(
                  eyebrow: 'Workforce Profile',
                  title: 'My Profile & Credentials',
                  subtitle: 'Review your account details, assignments, and manage your password.',
                  action: signOut,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (user == null)
                  const EmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'Profile unavailable',
                    message: 'Your account details are not loaded yet.',
                  )
                else ...[
                  ProfileIdentityCard(
                    name: user.name.isEmpty ? user.username : user.name,
                    roleLabel: user.role.displayName,
                    isActive: user.status == AccountStatus.active,
                    organizationName: access?.organization?.name,
                    branchNames: [
                      for (final b in access!.assignedBranches) b.name,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ProfileSectionCard(
                    icon: Icons.person_pin_outlined,
                    title: 'Account Information',
                    child: _details(user.username, user.email, user.phone),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                const ChangePasswordCard(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _details(String username, String? email, String? phone) {
    final displayEmail = LoginEmail.displayable(email);
    return Wrap(
      spacing: AppSpacing.xxl,
      runSpacing: AppSpacing.md,
      children: [
        ProfileInfoColumn(label: 'Username', value: username),
        if (displayEmail.isNotEmpty)
          ProfileInfoColumn(label: 'Email', value: displayEmail),
        if (phone != null && phone.isNotEmpty)
          ProfileInfoColumn(label: 'Phone', value: phone),
      ],
    );
  }
}
