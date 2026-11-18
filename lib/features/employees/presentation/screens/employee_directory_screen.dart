import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/constants/app_breakpoints.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/policies/organization_member_policy.dart';
import 'package:workaxis/features/employees/presentation/controllers/organization_members_controller.dart';
import 'package:workaxis/features/employees/presentation/member_branch_names.dart';
import 'package:workaxis/features/employees/presentation/member_account_actions.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/organization_member_card.dart';

class EmployeeDirectoryScreen extends StatefulWidget {
  const EmployeeDirectoryScreen({super.key});

  @override
  State<EmployeeDirectoryScreen> createState() =>
      _EmployeeDirectoryScreenState();
}

class _EmployeeDirectoryScreenState extends State<EmployeeDirectoryScreen> {
  late final TextEditingController _searchController;

  UserAccessContext? get _access =>
      context.read<AccessController>().accessContext;
  String? get _activeBranchId =>
      context.read<BranchContextController>().activeBranch?.branchId;

  @override
  void initState() {
    super.initState();
    // Seed from the controller so the visible text always matches the filter
    // that is actually applied.
    _searchController = TextEditingController(
      text: context.read<OrganizationMembersController>().searchQuery,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await context.read<AccessController>().refreshAccess();
    if (!mounted) return;
    final access = _access;
    if (access != null) {
      await context.read<OrganizationMembersController>().loadMembers(
        access: access,
        activeBranchId: _activeBranchId,
      );
    }
  }

  void _search(String query) {
    final access = _access;
    if (access == null) return;
    context.read<OrganizationMembersController>().setQuery(
      access: access,
      query: query,
      activeBranchId: _activeBranchId,
    );
  }

  void _loadMore() {
    final access = _access;
    if (access == null) return;
    context.read<OrganizationMembersController>().loadMore(
      access: access,
      activeBranchId: _activeBranchId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrganizationMembersController>();
    final access = context.watch<AccessController>().accessContext;
    final branchId = context
        .watch<BranchContextController>()
        .activeBranch
        ?.branchId;
    final role = access?.user.role;
    final isAdmin = role == UserRole.orgAdmin;
    final canCreate = isAdmin || role == UserRole.branchManager;
    final needsBranch = role == UserRole.branchManager && branchId == null;
    final title = role == UserRole.branchManager
        ? 'Branch Employees'
        : 'Employee Directory';
    final padding = context.responsivePagePadding;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxPageWidth,
              ),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: padding.copyWith(bottom: 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppPageHeader(
                            eyebrow: isAdmin
                                ? 'Organization Operations'
                                : 'Branch Operations',
                            title: title,
                            subtitle: isAdmin
                                ? 'Review account profiles and branch assignments.'
                                : 'Manage employees assigned to the active branch.',
                            action: canCreate
                                ? AppButton.responsive(
                                    text: isAdmin
                                        ? 'Add Member'
                                        : 'Add Employee',
                                    iconData: Icons.person_add_alt_1,
                                    onPressed: (access == null || needsBranch)
                                        ? null
                                        : () => _openEditor(access),
                                  )
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField.search(
                            controller: _searchController,
                            hintText: 'Search name, username, email, or role',
                            onChanged: _search,
                            onClear: () {
                              _searchController.clear();
                              _search('');
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (controller.actionErrorMessage != null) ...[
                            ErrorBanner(
                              message: controller.actionErrorMessage!,
                              onDismiss: controller.clearActionError,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
                    ),
                  ),
                  ..._bodySlivers(
                    controller: controller,
                    access: access,
                    branchId: branchId,
                    needsBranch: needsBranch,
                    canCreate: canCreate,
                    padding: padding,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _bodySlivers({
    required OrganizationMembersController controller,
    required UserAccessContext? access,
    required String? branchId,
    required bool needsBranch,
    required bool canCreate,
    required EdgeInsets padding,
  }) {
    final sidePadding = EdgeInsets.symmetric(
      horizontal: padding.horizontal / 2,
    );
    Widget message(Widget child) => SliverPadding(
      padding: sidePadding,
      sliver: SliverToBoxAdapter(child: child),
    );

    if (needsBranch) {
      return [
        message(
          const EmptyState(
            icon: Icons.store_outlined,
            title: 'Select an active branch',
            message: 'Choose one of your assigned branches before managing employees.',
          ),
        ),
      ];
    }
    if (controller.isLoading) {
      return [
        message(
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }
    if (controller.errorMessage != null) {
      return [
        message(ErrorState(message: controller.errorMessage!, onRetry: _load)),
      ];
    }
    if (controller.members.isEmpty) {
      return [
        message(
          EmptyState(
            icon: Icons.badge_outlined,
            title: 'No accounts found',
            message: controller.searchQuery.isEmpty
                ? 'Accounts assigned to this scope will appear here.'
                : 'Try a different name, username, email, or role.',
          ),
        ),
      ];
    }
    final members = controller.members;
    return [
      SliverPadding(
        padding: sidePadding,
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.crossAxisExtent;
            final columns = width < AppBreakpoints.mediumMin
                ? 1
                : width < AppBreakpoints.expandedMin
                ? 2
                : 3;
            return SliverList.separated(
              itemCount: (members.length / columns).ceil(),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, row) {
                final cells = <Widget>[];
                for (var col = 0; col < columns; col++) {
                  final index = row * columns + col;
                  if (col > 0) cells.add(const SizedBox(width: AppSpacing.md));
                  cells.add(
                    Expanded(
                      child: index < members.length
                          ? _cardFor(members[index], access, branchId)
                          : const SizedBox.shrink(),
                    ),
                  );
                }
                // Each row is as tall as its tallest card, so cards never leave
                // unused space below their actions.
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: cells,
                  ),
                );
              },
            );
          },
        ),
      ),
      SliverPadding(
        padding: sidePadding.copyWith(bottom: AppSpacing.xxl),
        sliver: SliverToBoxAdapter(child: _footer(controller)),
      ),
    ];
  }

  Widget _cardFor(
    OrganizationMember member,
    UserAccessContext? access,
    String? branchId,
  ) {
    final canManage =
        access != null &&
        OrganizationMemberPolicy.canManage(access, member, branchId);
    // Nobody suspends, resets or deletes their own account here.
    final isSelf =
        access != null &&
        (member.id == access.user.id || member.authUid == access.user.id);
    final canAct = canManage && !isSelf;
    return OrganizationMemberCard(
      member: member,
      branchNames: memberBranchNames(member, access),
      onOpen: () => _openDetails(member, access),
      onEdit: canManage ? () => _openEditor(access, member: member) : null,
      onResetPassword: canAct
          ? () => resetMemberPassword(
              context,
              access: access,
              member: member,
              activeBranchId: _activeBranchId,
            )
          : null,
      onToggleStatus: canAct
          ? () => toggleMemberStatus(
              context,
              access: access,
              member: member,
              activeBranchId: _activeBranchId,
            )
          : null,
      onDelete: canAct
          ? () => deleteMember(
              context,
              access: access,
              member: member,
              activeBranchId: _activeBranchId,
            )
          : null,
    );
  }

  Widget _footer(OrganizationMembersController controller) {
    return Column(
      children: [
        Text(
          'Showing ${controller.members.length} of ${controller.totalCount}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        if (controller.hasMore) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton.outlined(
            text: 'Load more',
            isFullWidth: false,
            isLoading: controller.isLoadingMore,
            onPressed: _loadMore,
          ),
        ],
      ],
    );
  }

  /// Add and edit are routed pages; the directory reloads when it is shown again.
  void _openEditor(UserAccessContext access, {OrganizationMember? member}) =>
      context.push(
        member == null ? _addPath(access) : _editPath(access, member.id),
      );

  String _addPath(UserAccessContext access) =>
      access.user.role == UserRole.branchManager
      ? AppRoutes.branchManagerEmployeeAddPath
      : AppRoutes.orgAdminEmployeeAddPath;

  String _editPath(UserAccessContext access, String memberId) =>
      access.user.role == UserRole.branchManager
      ? AppRoutes.branchManagerEmployeeEditPath(memberId)
      : AppRoutes.orgAdminEmployeeEditPath(memberId);

  void _openDetails(OrganizationMember member, UserAccessContext? access) {
    if (access == null) return;
    context.push(_detailsPath(access, member.id));
  }

  /// Branch managers get the branch-scoped details route, so the back link
  /// returns them to their branch employee list.
  String _detailsPath(UserAccessContext access, String memberId) =>
      access.user.role == UserRole.branchManager
      ? AppRoutes.branchManagerEmployeeDetailsPath(memberId)
      : AppRoutes.orgAdminEmployeeDetailsPath(memberId);
}
