import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';

class PlatformAdministratorDetailsScreen extends StatefulWidget {
  const PlatformAdministratorDetailsScreen({
    super.key,
    required this.administratorId,
  });

  final String administratorId;

  @override
  State<PlatformAdministratorDetailsScreen> createState() =>
      _PlatformAdministratorDetailsScreenState();
}

class _PlatformAdministratorDetailsScreenState
    extends State<PlatformAdministratorDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PlatformUsersController>().loadAdministrator(
          widget.administratorId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlatformUsersController>();
    final administrator = controller.selectedAdministrator;

    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (administrator == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.errorMessage ??
                      'This platform administrator could not be found.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.outlined(
                  text: 'Back to Platform Users',
                  onPressed: () => context.go(AppRoutes.platformUsers),
                  isFullWidth: false,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.platformUsers),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Platform Users'),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size(48, 48),
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppPageHeader(
                    eyebrow: 'Platform Access',
                    title: 'Administrator details',
                    subtitle: 'Profile and sign-in access for this account.',
                    action: AppButton.responsive(
                      text: 'Edit Administrator',
                      iconData: Icons.edit_outlined,
                      onPressed: () => context.push(
                        AppRoutes.platformUserEditPath(administrator.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _StatusPanel(
                    administrator: administrator,
                    isUpdating: controller.isSaving,
                    onStatusChange: _changeStatus,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ProfilePanel(administrator: administrator),
                  const SizedBox(height: AppSpacing.md),
                  _AccountPanel(administrator: administrator),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      );
    }

  Future<void> _changeStatus(
    PlatformAdministrator administrator,
    AccountStatus nextStatus,
  ) async {
    final shouldSuspend = nextStatus == AccountStatus.suspended;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(shouldSuspend ? 'Suspend access?' : 'Restore access?'),
        content: Text(
          shouldSuspend
              ? '${administrator.fullName} will no longer be able to sign in. You can restore access later.'
              : 'Allow ${administrator.fullName} to sign in to WorkAxis again?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(shouldSuspend ? 'Suspend access' : 'Restore access'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final updated = await context.read<PlatformUsersController>().updateStatus(
      administrator.id,
      nextStatus,
    );
    if (!mounted || updated == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shouldSuspend
              ? '${administrator.fullName} access suspended.'
              : '${administrator.fullName} access restored.',
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.administrator,
    required this.isUpdating,
    required this.onStatusChange,
  });

  final PlatformAdministrator administrator;
  final bool isUpdating;
  final void Function(PlatformAdministrator, AccountStatus) onStatusChange;

  @override
  Widget build(BuildContext context) {
    final isActive = administrator.status == AccountStatus.active;
    final isCompact = context.isCompact;

    final actionButton = isActive
        ? TextButton.icon(
            onPressed: isUpdating
                ? null
                : () =>
                      onStatusChange(administrator, AccountStatus.suspended),
            icon: const Icon(Icons.block_outlined, size: 16),
            label: const Text('Suspend access'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.statusUrgentText,
              minimumSize: Size(
                isCompact ? double.infinity : 48,
                AppSpacing.minTouchTarget,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                side: const BorderSide(color: AppColors.statusUrgentBorder),
              ),
            ),
          )
        : AppButton.secondary(
            text: 'Restore access',
            iconData: Icons.check_circle_outline,
            onPressed: isUpdating
                ? null
                : () => onStatusChange(administrator, AccountStatus.active),
            isFullWidth: isCompact,
          );

    final statusInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusChip.fromStatus(
          isActive ? 'Active' : 'Suspended',
          width: 96,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isActive
              ? 'This administrator can sign in to the WorkAxis platform.'
              : 'This administrator cannot sign in while access is suspended.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );

    return _DetailsPanel(
      title: 'Account access',
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                statusInfo,
                const SizedBox(height: AppSpacing.md),
                actionButton,
              ],
            )
          : Row(
              children: [
                Expanded(child: statusInfo),
                const SizedBox(width: AppSpacing.md),
                actionButton,
              ],
            ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.administrator});

  final PlatformAdministrator administrator;

  @override
  Widget build(BuildContext context) {
    return _DetailsPanel(
      title: 'Administrator profile',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = context.isCompact ? 1 : 2;
          final gap = AppSpacing.lg;
          final width = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: AppSpacing.lg,
            children: [
              SizedBox(
                width: width,
                child: _DetailValue(
                  label: 'Full name',
                  value: administrator.fullName,
                ),
              ),
              SizedBox(
                width: width,
                child: _DetailValue(
                  label: 'Role',
                  value: 'Platform Administrator',
                ),
              ),
              SizedBox(
                width: width,
                child: _DetailValue(
                  label: 'Work email',
                  value: administrator.email,
                ),
              ),
              SizedBox(
                width: width,
                child: _DetailValue(
                  label: 'Username',
                  value: administrator.username,
                ),
              ),
              if (administrator.phone != null)
                SizedBox(
                  width: width,
                  child: _DetailValue(
                    label: 'Phone number',
                    value: administrator.phone!,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({required this.administrator});

  final PlatformAdministrator administrator;

  @override
  Widget build(BuildContext context) {
    return _DetailsPanel(
      title: 'Account activity',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = context.isCompact ? 1 : 2;
          final gap = AppSpacing.lg;
          final width = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: AppSpacing.lg,
            children: [
              SizedBox(
                width: width,
                child: _DetailValue(
                  label: 'Created',
                  value: DateFormat('MMMM d, yyyy')
                      .format(administrator.createdAt),
                ),
              ),
              SizedBox(
                width: width,
                child: _DetailValue(
                  label: 'Last active',
                  value: administrator.lastActiveAt == null
                      ? 'Never signed in'
                      : DateFormat('MMMM d, yyyy • h:mm a')
                            .format(administrator.lastActiveAt!),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        context.isCompact ? AppSpacing.md : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x04000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SelectableText(
          value,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
        ),
      ],
    );
  }
}
