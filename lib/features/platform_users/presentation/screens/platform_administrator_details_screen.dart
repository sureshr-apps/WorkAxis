import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/formatting/date_time_formatters.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_delete_flow.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_dialogs.dart';
import 'package:workaxis/core/widgets/account_details/account_detail_panels.dart';
import 'package:workaxis/core/widgets/account_details/account_status_panel.dart';

/// Space below the content for the circular edit button: 56dp button, 16dp
/// edge margin and a little breathing room.
const double _floatingButtonClearance = 96;

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
                PageBreadcrumb(
                  backLabel: 'Platform Users',
                  currentLabel: 'Administrator',
                  onBack: () => context.go(AppRoutes.platformUsers),
                ),
                const SizedBox(height: AppSpacing.md),
                ErrorState(
                  message:
                      controller.errorMessage ??
                      'This platform administrator could not be found.',
                  onRetry: _load,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Edit Administrator',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () =>
            context.push(AppRoutes.platformUserEditPath(administrator.id)),
        child: const Icon(Icons.edit_outlined),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageBreadcrumb(
                  backLabel: 'Platform Users',
                  currentLabel: 'Administrator details',
                  onBack: () => context.go(AppRoutes.platformUsers),
                ),
                const SizedBox(height: AppSpacing.md),
                const AppPageHeader(
                  eyebrow: 'Platform Access',
                  title: 'Administrator details',
                  subtitle: 'Profile and sign-in access for this account.',
                ),
                const SizedBox(height: AppSpacing.lg),
                if (controller.actionErrorMessage != null) ...[
                  ErrorBanner(
                    message: controller.actionErrorMessage!,
                    onDismiss: controller.clearActionError,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AccountStatusPanel(
                  isActive: administrator.status == AccountStatus.active,
                  activeMessage: 'This administrator can sign in to the WorkAxis platform.',
                  inactiveMessage: 'This administrator cannot sign in while access is suspended.',
                  isUpdating: controller.isSaving,
                  deleteTooltip: 'Delete administrator',
                  onReset: () => context.push(
                    AppRoutes.platformUserResetPasswordPath(administrator.id),
                  ),
                  onToggleActive: () => _changeStatus(
                    administrator,
                    administrator.status == AccountStatus.active
                        ? AccountStatus.suspended
                        : AccountStatus.active,
                  ),
                  onDelete: () => _deleteAdministrator(administrator),
                ),
                const SizedBox(height: AppSpacing.md),
                AccountDetailsPanel(
                  title: 'Administrator profile',
                  values: _profileValues(administrator),
                ),
                const SizedBox(height: AppSpacing.md),
                AccountDetailsPanel(
                  title: 'Account activity',
                  values: _activityValues(administrator),
                ),
                // Keeps the last panel scrollable above the floating edit button.
                const SizedBox(height: _floatingButtonClearance),
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

  Future<void> _deleteAdministrator(PlatformAdministrator administrator) async {
    final deleted = await confirmAndDeleteAdministrator(
      context,
      context.read<PlatformUsersController>(),
      administrator,
    );
    if (deleted && mounted) context.go(AppRoutes.platformUsers);
  }

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
}

List<(String, String)> _profileValues(PlatformAdministrator administrator) => [
  ('Full name', administrator.fullName),
  ('Role', 'Platform Administrator'),
  ('Work email', administrator.email.isEmpty ? '—' : administrator.email),
  ('Username', administrator.username),
  if (administrator.phone != null) ('Phone number', administrator.phone!),
];

List<(String, String)> _activityValues(PlatformAdministrator administrator) => [
  ('Created', AppFormatters.formatDate(administrator.createdAt)),
  (
    'Last active',
    administrator.lastActiveAt == null
        ? 'Never signed in'
        : AppFormatters.formatDateTime(administrator.lastActiveAt),
  ),
];
