import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/content_width_scope.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/page_sliver_padding.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_action_menu.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_card.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_dialogs.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrators_table.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_users_toolbar.dart';

class PlatformUsersListScreen extends StatefulWidget {
  const PlatformUsersListScreen({super.key, this.now = systemNow});

  /// Clock used for relative "last active" text.
  final Now now;

  @override
  State<PlatformUsersListScreen> createState() =>
      _PlatformUsersListScreenState();
}

class _PlatformUsersListScreenState extends State<PlatformUsersListScreen> {
  late final TextEditingController _searchController;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    final controller = context.read<PlatformUsersController>();
    // The controller outlives this screen, so seed the visible text from the
    // filter that is actually in effect.
    _searchController = TextEditingController(text: controller.searchQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _requested = true);
      controller
        ..clearActionError()
        ..loadAdministrators();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlatformUsersController>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.loadAdministrators,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              PageSliverPadding(
                sliver: SliverToBoxAdapter(child: _buildTop(controller)),
              ),
              ..._buildResultSlivers(controller),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTop(PlatformUsersController controller) {
    return Padding(
      padding: EdgeInsets.only(top: context.responsivePagePadding.top),
      child: ContentWidthProvider(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              eyebrow: 'Platform Access',
              title: 'Platform Users',
              subtitle: 'Manage administrator access to WorkAxis across the India platform fleet.',
              action: AppButton.responsive(
                text: 'Add Platform Administrator',
                iconData: Icons.add,
                onPressed: () => context.push(AppRoutes.platformUsersAdd),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildKpiMetrics(controller),
            const SizedBox(height: AppSpacing.lg),
            PlatformUsersToolbar(
              controller: controller,
              searchController: _searchController,
            ),
            if (controller.actionErrorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              ErrorBanner(
                message: controller.actionErrorMessage!,
                onDismiss: controller.clearActionError,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiMetrics(PlatformUsersController controller) {
    return ResponsiveKpiSection(
      cardHeight: 96,
      cards: [
        AppKpiCard(
          title: 'Total Administrators',
          value: '${controller.totalCount}',
          accentColor: AppColors.primaryDark,
          icon: Icons.admin_panel_settings_outlined,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primaryContainer,
          iconPosition: AppKpiIconPosition.bottomRight,
        ),
        AppKpiCard(
          title: 'Active Access',
          value: '${controller.activeCount}',
          valueColor: AppColors.kpiPositive,
          accentColor: AppColors.kpiPositiveAccent,
          icon: Icons.verified_user_outlined,
          iconColor: AppColors.kpiPositiveAccent,
          iconBgColor: AppColors.kpiPositiveBackground,
          iconPosition: AppKpiIconPosition.bottomRight,
        ),
        AppKpiCard(
          title: 'Suspended Access',
          value: '${controller.suspendedCount}',
          accentColor: AppColors.kpiCritical,
          valueColor: controller.suspendedCount > 0
              ? AppColors.kpiCritical
              : null,
          icon: Icons.pause_circle_outline_rounded,
          iconColor: AppColors.kpiCritical,
          iconBgColor: AppColors.kpiCriticalBackground,
          iconPosition: AppKpiIconPosition.bottomRight,
        ),
      ],
    );
  }

  List<Widget> _buildResultSlivers(PlatformUsersController controller) {
    if (!_requested ||
        (controller.isLoading && controller.administrators.isEmpty)) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }
    if (controller.errorMessage != null) {
      return [
        SliverToBoxAdapter(
          child: ErrorState(
            message: controller.errorMessage!,
            onRetry: controller.loadAdministrators,
          ),
        ),
      ];
    }
    if (controller.administrators.isEmpty) {
      final hasFilters =
          controller.searchQuery.isNotEmpty || controller.statusFilter != null;
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: hasFilters
                ? Icons.search_off
                : Icons.admin_panel_settings_outlined,
            title: hasFilters
                ? 'No platform administrators match these filters.'
                : 'No platform administrators yet.',
            action: hasFilters
                ? AppButton.outlined(
                    text: 'Reset filters',
                    isFullWidth: false,
                    onPressed: () {
                      _searchController.clear();
                      controller
                        ..setSearchQuery('')
                        ..setStatusFilter(null);
                    },
                  )
                : null,
          ),
        ),
      ];
    }

    final administrators = controller.administrators;
    return [
      SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          if (width >= AppBreakpoints.expandedMin) {
            return PageSliverPadding(
              sliver: SliverToBoxAdapter(
                child: PlatformAdministratorsTable(
                  administrators: administrators,
                  onSelect: _openDetails,
                  onAction: _handleAction,
                  now: widget.now,
                ),
              ),
            );
          }
          if (width >= AppBreakpoints.mediumMin) {
            return PageSliverPadding(sliver: _pairedCards(administrators));
          }
          return PageSliverPadding(sliver: _singleCards(administrators));
        },
      ),
      if (controller.hasMore)
        PageSliverPadding(
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Align(
                child: AppButton.outlined(
                  text: 'Load more',
                  isFullWidth: false,
                  isLoading: controller.isLoadingMore,
                  onPressed: controller.loadMore,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _card(PlatformAdministrator administrator) =>
      PlatformAdministratorCard(
        administrator: administrator,
        now: widget.now,
        onTap: () => _openDetails(administrator),
        onAction: (action) => _handleAction(administrator, action),
      );

  Widget _singleCards(List<PlatformAdministrator> administrators) {
    return SliverList.separated(
      itemCount: administrators.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, index) => _card(administrators[index]),
    );
  }

  Widget _pairedCards(List<PlatformAdministrator> administrators) {
    final rows = (administrators.length + 1) ~/ 2;
    return SliverList.separated(
      itemCount: rows,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, row) {
        final first = administrators[row * 2];
        final second = row * 2 + 1 < administrators.length
            ? administrators[row * 2 + 1]
            : null;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _card(first)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: second == null ? const SizedBox() : _card(second)),
          ],
        );
      },
    );
  }

  void _openDetails(PlatformAdministrator administrator) {
    context.push(AppRoutes.platformUserDetailsPath(administrator.id));
  }

  void _handleAction(
    PlatformAdministrator administrator,
    PlatformAdministratorAction action,
  ) {
    switch (action) {
      case PlatformAdministratorAction.view:
        _openDetails(administrator);
      case PlatformAdministratorAction.edit:
        context.push(AppRoutes.platformUserEditPath(administrator.id));
      case PlatformAdministratorAction.resetPassword:
        _resetPassword(administrator);
      case PlatformAdministratorAction.suspend:
        _changeStatus(administrator, AccountStatus.suspended);
      case PlatformAdministratorAction.restore:
        _changeStatus(administrator, AccountStatus.active);
    }
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
    _showResult(
      success: updated != null,
      message: nextStatus == AccountStatus.suspended
          ? '${administrator.fullName} access suspended.'
          : '${administrator.fullName} access restored.',
      controller: controller,
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
    _showResult(
      success: ok,
      message: 'Password reset for ${administrator.fullName}.',
      controller: controller,
    );
  }

  void _showResult({
    required bool success,
    required String message,
    required PlatformUsersController controller,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? message
              : controller.actionErrorMessage ??
                    'The change could not be completed. Try again.',
        ),
      ),
    );
  }
}
