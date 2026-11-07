import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:workaxis/features/employees/presentation/screens/widgets/member_details_dialog.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/organization_member_card.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/organization_member_editor_dialog.dart';

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
                                    text: 'Add Employee',
                                    iconData: Icons.person_add_alt_1,
                                    onPressed: access == null
                                        ? null
                                        : () => _openEditor(
                                            access,
                                            branchId: branchId,
                                          ),
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
            // Card content is fixed-structure; scale the row height with the
            // user's text scale so large text does not overflow.
            final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
            return SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                mainAxisExtent: 212 * (scale < 1 ? 1 : scale),
              ),
              itemCount: members.length,
              itemBuilder: (context, index) =>
                  _cardFor(members[index], access, branchId),
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
    final canEdit =
        access != null &&
        OrganizationMemberPolicy.canManage(access, member, branchId);
    return OrganizationMemberCard(
      member: member,
      branchNames: _branchNames(member, access),
      onView: () => _showDetails(member, access, branchId),
      onEdit: canEdit
          ? () => _openEditor(access, branchId: branchId, member: member)
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

  List<String> _branchNames(
    OrganizationMember member,
    UserAccessContext? access,
  ) =>
      access?.assignedBranches
          .where((branch) => member.branchIds.contains(branch.id))
          .map((branch) => branch.name)
          .toList(growable: false) ??
      const [];

  Future<void> _openEditor(
    UserAccessContext access, {
    required String? branchId,
    OrganizationMember? member,
  }) async {
    final controller = context.read<OrganizationMembersController>();
    controller.clearActionError();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => OrganizationMemberEditorDialog(
        access: access,
        activeBranchId: branchId,
        member: member,
        isSaving: controller.isSaving,
        saveErrorMessage: () => controller.actionErrorMessage,
        onSave: (draft, password) => controller.saveMember(
          access: access,
          member: draft,
          initialPassword: password,
          activeBranchId: branchId,
        ),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _showDetails(
    OrganizationMember member,
    UserAccessContext? access,
    String? branchId,
  ) async {
    if (access == null) return;
    final scopedMember = await context
        .read<OrganizationMembersController>()
        .getMember(
          access: access,
          memberId: member.id,
          activeBranchId: branchId,
        );
    if (scopedMember == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => MemberDetailsDialog(
        member: scopedMember,
        branchNames: _branchNames(scopedMember, access),
      ),
    );
  }
}
