import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_action_menu.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrator_card.dart';
import 'package:workaxis/features/platform_users/presentation/widgets/platform_administrators_table.dart';

class PlatformUsersListScreen extends StatefulWidget {
  const PlatformUsersListScreen({super.key});

  @override
  State<PlatformUsersListScreen> createState() =>
      _PlatformUsersListScreenState();
}

class _PlatformUsersListScreenState extends State<PlatformUsersListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PlatformUsersController>().loadAdministrators();
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
    final isCompact = context.isCompact;
    final isMedium = context.isMedium;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.loadAdministrators,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsivePageContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppPageHeader(
                    eyebrow: 'Platform Access',
                    title: 'Platform Users',
                    subtitle:
                        'Manage administrator access to WorkAxis across the India platform fleet.',
                    action: AppButton.responsive(
                      text: 'Add Platform Administrator',
                      iconData: Icons.add,
                      onPressed: () =>
                          context.push(AppRoutes.platformUsersAdd),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildKpiMetrics(context, controller),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSearchAndFilters(controller, isCompact, isMedium),
                  const SizedBox(height: AppSpacing.lg),
                  _buildResults(controller, isCompact, isMedium),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiMetrics(
    BuildContext context,
    PlatformUsersController controller,
  ) {
    return ResponsiveKpiSection(
      cardHeight: 96,
      cards: [
        AppKpiCard(
          title: 'Total Administrators',
          value: '${controller.totalCount}',
          accentColor: const Color(0xFF003366),
          icon: Icons.admin_panel_settings_outlined,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primaryContainer,
          iconPosition: AppKpiIconPosition.bottomRight,
        ),
        AppKpiCard(
          title: 'Active Access',
          value: '${controller.activeCount}',
          valueColor: const Color(0xFF15803D),
          accentColor: const Color(0xFF16A34A),
          icon: Icons.verified_user_outlined,
          iconColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFFDCFCE7),
          iconPosition: AppKpiIconPosition.bottomRight,
        ),
        AppKpiCard(
          title: 'Suspended Access',
          value: '${controller.suspendedCount}',
          accentColor: const Color(0xFFDC2626),
          valueColor: controller.suspendedCount > 0
              ? const Color(0xFFDC2626)
              : null,
          icon: Icons.pause_circle_outline_rounded,
          iconColor: const Color(0xFFDC2626),
          iconBgColor: const Color(0xFFFEE2E2),
          iconPosition: AppKpiIconPosition.bottomRight,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(
    PlatformUsersController controller,
    bool isCompact,
    bool isMedium,
  ) {
    final search = _buildSearchField(controller);
    final filters = _StatusFilters(controller: controller);
    final stackControls = isCompact;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: stackControls
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: filters,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: AppSpacing.md),
                filters,
              ],
            ),
    );
  }

  Widget _buildSearchField(PlatformUsersController controller) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          controller.setSearchQuery(val);
          setState(() {});
        },
        style: GoogleFonts.inter(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search name, username, email, or phone',
          hintStyle: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 16,
            color: AppColors.secondary,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? InkWell(
                  onTap: () {
                    _searchController.clear();
                    controller.setSearchQuery('');
                    setState(() {});
                  },
                  child: const Icon(
                    Icons.clear,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(
              color: AppColors.outlineSubtle,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(
              color: AppColors.outlineSubtle,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(
    PlatformUsersController controller,
    bool isCompact,
    bool isMedium,
  ) {
    if (controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.errorMessage != null) {
      return _ErrorState(
        message: controller.errorMessage!,
        onRetry: controller.loadAdministrators,
      );
    }
    if (controller.administrators.isEmpty) {
      return _EmptyState(
        hasFilters:
            controller.searchQuery.isNotEmpty ||
            controller.statusFilter != null,
        onReset: () {
          _searchController.clear();
          controller.setSearchQuery('');
          controller.setStatusFilter(null);
        },
      );
    }
    if (isCompact) {
      return Column(
        children: [
          for (final administrator in controller.administrators) ...[
            PlatformAdministratorCard(
              administrator: administrator,
              onTap: () => _openDetails(administrator),
              onAction: (action) => _handleAction(administrator, action),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      );
    }
    if (isMedium) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - AppSpacing.md) / 2;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final administrator in controller.administrators)
                SizedBox(
                  width: cardWidth,
                  child: PlatformAdministratorCard(
                    administrator: administrator,
                    onTap: () => _openDetails(administrator),
                    onAction: (action) => _handleAction(administrator, action),
                  ),
                ),
            ],
          );
        },
      );
    }
    return PlatformAdministratorsTable(
      administrators: controller.administrators,
      onSelect: _openDetails,
      onAction: _handleAction,
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
        break;
      case PlatformAdministratorAction.edit:
        context.push(AppRoutes.platformUserEditPath(administrator.id));
        break;
      case PlatformAdministratorAction.suspend:
        _confirmStatusChange(administrator, AccountStatus.suspended);
        break;
      case PlatformAdministratorAction.restore:
        context.read<PlatformUsersController>().updateStatus(
          administrator.id,
          AccountStatus.active,
        );
        break;
    }
  }

  Future<void> _confirmStatusChange(
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
            child: Text(
              shouldSuspend ? 'Suspend access' : 'Restore access',
              style: TextStyle(
                color: shouldSuspend
                    ? AppColors.statusUrgentText
                    : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<PlatformUsersController>().updateStatus(
      administrator.id,
      nextStatus,
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.controller});

  final PlatformUsersController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Status:',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatusFilterButton(
          label: 'All (${controller.totalCount})',
          selected: controller.statusFilter == null,
          onTap: () => controller.setStatusFilter(null),
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatusFilterButton(
          label: 'Active (${controller.activeCount})',
          dotColor: AppColors.statusActive,
          selected: controller.statusFilter == AccountStatus.active,
          onTap: () => controller.setStatusFilter(AccountStatus.active),
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatusFilterButton(
          label: 'Suspended (${controller.suspendedCount})',
          dotColor: AppColors.statusUrgent,
          selected: controller.statusFilter == AccountStatus.suspended,
          onTap: () => controller.setStatusFilter(AccountStatus.suspended),
        ),
      ],
    );
  }
}

class _StatusFilterButton extends StatelessWidget {
  const _StatusFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outlineSubtle,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? Colors.white : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters, required this.onReset});

  final bool hasFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.lg,
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
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.admin_panel_settings_outlined,
            size: 32,
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            hasFilters
                ? 'No platform administrators match these filters.'
                : 'No platform administrators yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton.outlined(
              text: 'Reset filters',
              onPressed: onReset,
              isFullWidth: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.statusUrgentContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.statusUrgentBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.statusUrgent),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
