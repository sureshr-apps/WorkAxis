import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

class VerifyingAccessPage extends StatefulWidget {
  const VerifyingAccessPage({super.key});

  @override
  State<VerifyingAccessPage> createState() => _VerifyingAccessPageState();
}

class _VerifyingAccessPageState extends State<VerifyingAccessPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startResolution();
    });
  }

  Future<void> _startResolution() async {
    final authController = context.read<AuthController>();
    final orgController = context.read<OrganizationContextController>();

    final user = authController.currentUser;
    if (user != null) {
      await orgController.resolveAccess(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMedium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppRadius.borderLg,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.onPrimaryContainer,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Verifying Access',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Checking your credentials, organization memberships, and role assignments...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
