import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_dialogs.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_users_panel.dart';

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
  /// True once this screen's own load has finished, so a previously selected
  /// administrator or stale error is never shown on the first frame.
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant PlatformAdministratorDetailsScreen old) {
    super.didUpdateWidget(old);
    if (old.administratorId != widget.administratorId) {
      setState(() => _loaded = false);
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    final controller = context.read<PlatformUsersController>()
      ..clearActionError();
    await controller.loadAdministrator(widget.administratorId);
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlatformUsersController>();
    final selected = controller.selectedAdministrator;
    final administrator = selected?.id == widget.administratorId
        ? selected
        : null;

    if (!_loaded || (controller.isLoading && administrator == null)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (administrator == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ErrorState(
                  message:
                      controller.errorMessage ??
                      'This platform administrator could not be found.',
                  onRetry: _load,
                ),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton.outlined(
                    text: 'Platform Users',
                    iconData: Icons.arrow_back,
                    isFullWidth: false,
                    onPressed: () => context.go(AppRoutes.platformUsers),
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
                if (controller.actionErrorMessage != null) ...[
                  ErrorBanner(
                    message: controller.actionErrorMessage!,
                    onDismiss: controller.clearActionError,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _StatusPanel(
                  administrator: administrator,
                  isUpdating: controller.isSaving,
                  onStatusChange: _changeStatus,
                  onResetPassword: _resetPassword,
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

  void _toast(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _changeStatus(
    PlatformAdministrator administrator,
    AccountStatus nextStatus,
  ) async {
    final controller = context.read<PlatformUsersController>();
    final confirmed = await confirmAdministratorStatusChange(
      context,
      administrator: administrator,
      nextStatus: nextStatus,
    );
    if (!confirmed || !mounted) return;
    controller.clearActionError();
    final updated = await controller.updateStatus(administrator.id, nextStatus);
    if (!mounted) return;
    _toast(
      updated == null
          ? controller.actionErrorMessage ??
                'The change could not be completed. Try again.'
          : nextStatus == AccountStatus.suspended
          ? '${administrator.fullName} access suspended.'
          : '${administrator.fullName} access restored.',
    );
  }

  Future<void> _resetPassword(PlatformAdministrator administrator) async {
    final controller = context.read<PlatformUsersController>();
    final password = await promptAdministratorPasswordReset(
      context,
      administrator: administrator,
    );
    if (password == null || !mounted) return;
    controller.clearActionError();
    final ok = await controller.resetPassword(
      id: administrator.id,
      newPassword: password,
    );
    if (!mounted) return;
    _toast(
      ok
          ? 'Password reset for ${administrator.fullName}.'
          : controller.actionErrorMessage ??
                'The password could not be reset. Try again.',
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.administrator,
    required this.isUpdating,
    required this.onStatusChange,
    required this.onResetPassword,
  });

  final PlatformAdministrator administrator;
  final bool isUpdating;
  final void Function(PlatformAdministrator, AccountStatus) onStatusChange;
  final ValueChanged<PlatformAdministrator> onResetPassword;

  @override
  Widget build(BuildContext context) {
    final isActive = administrator.status == AccountStatus.active;
    final isCompact = context.isCompact;

    final actionButton = isActive
        ? AppButton.outlined(
            text: 'Suspend access',
            iconData: Icons.block_outlined,
            isFullWidth: isCompact,
            onPressed: isUpdating
                ? null
                : () => onStatusChange(administrator, AccountStatus.suspended),
          )
        : AppButton.secondary(
            text: 'Restore access',
            iconData: Icons.check_circle_outline,
            isFullWidth: isCompact,
            onPressed: isUpdating
                ? null
                : () => onStatusChange(administrator, AccountStatus.active),
          );
    final resetButton = AppButton.outlined(
      text: 'Reset password',
      iconData: Icons.key_outlined,
      isFullWidth: isCompact,
      onPressed: isUpdating ? null : () => onResetPassword(administrator),
    );

    final statusInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusChip.fromStatus(isActive ? 'Active' : 'Suspended'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isActive
              ? 'This administrator can sign in to the WorkAxis platform.'
              : 'This administrator cannot sign in while access is suspended.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );

    return PlatformUsersPanel(
      title: 'Account access',
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                statusInfo,
                const SizedBox(height: AppSpacing.md),
                resetButton,
                const SizedBox(height: AppSpacing.sm),
                actionButton,
              ],
            )
          : Row(
              children: [
                Expanded(child: statusInfo),
                const SizedBox(width: AppSpacing.md),
                resetButton,
                const SizedBox(width: AppSpacing.sm),
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
    return PlatformUsersPanel(
      title: 'Administrator profile',
      child: _DetailGrid(
        values: [
          ('Full name', administrator.fullName),
          ('Role', 'Platform Administrator'),
          (
            'Work email',
            administrator.email.isEmpty ? '—' : administrator.email,
          ),
          ('Username', administrator.username),
          if (administrator.phone != null)
            ('Phone number', administrator.phone!),
        ],
      ),
    );
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({required this.administrator});

  final PlatformAdministrator administrator;

  @override
  Widget build(BuildContext context) {
    return PlatformUsersPanel(
      title: 'Account activity',
      child: _DetailGrid(
        values: [
          ('Created', AppFormatters.formatDate(administrator.createdAt)),
          (
            'Last active',
            administrator.lastActiveAt == null
                ? 'Never signed in'
                : AppFormatters.formatDateTime(administrator.lastActiveAt),
          ),
        ],
      ),
    );
  }
}

/// Label/value pairs laid out in one or two columns by available width.
class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.values});

  final List<(String, String)> values;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.lg;
        final twoColumns = constraints.maxWidth >= AppBreakpoints.formSplit;
        final width = twoColumns
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: AppSpacing.lg,
          children: [
            for (final (label, value) in values)
              SizedBox(
                width: width,
                child: _DetailValue(label: label, value: value),
              ),
          ],
        );
      },
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
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SelectableText(value, style: AppTypography.bodyMedium),
      ],
    );
  }
}
