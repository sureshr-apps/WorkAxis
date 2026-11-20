import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_sliver_page.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';
import 'package:workaxis/features/off_site_work/presentation/controllers/off_site_work_controller.dart';
import 'package:workaxis/features/off_site_work/presentation/widgets/off_site_work_assignment_card.dart';
import 'package:workaxis/features/off_site_work/presentation/widgets/off_site_work_assignment_dialog.dart';

class OffSiteWorkScreen extends StatefulWidget {
  const OffSiteWorkScreen({super.key});

  @override
  State<OffSiteWorkScreen> createState() => _OffSiteWorkScreenState();
}

class _OffSiteWorkScreenState extends State<OffSiteWorkScreen> {
  late final BranchContextController _branchController;
  String? _observedBranchId;

  String? get _activeBranchId =>
      _branchController.activeBranch?.branchId ??
      context.read<AccessController>().accessContext?.activeBranch?.branchId;

  @override
  void initState() {
    super.initState();
    _branchController = context.read<BranchContextController>();
    _observedBranchId = _activeBranchId;
    _branchController.addListener(_onBranchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _branchController.removeListener(_onBranchChanged);
    super.dispose();
  }

  void _onBranchChanged() {
    final id = _activeBranchId;
    if (id == _observedBranchId) return;
    _observedBranchId = id;
    _load();
  }

  Future<void> _load({bool force = false}) async {
    final accessController = context.read<AccessController>();
    await accessController.refreshAccess(force: force);
    if (!mounted) return;
    final access = accessController.accessContext;
    if (access == null) return;
    await context.read<OffSiteWorkController>().load(
      access: access,
      activeBranchId: access.user.role == UserRole.branchManager
          ? _activeBranchId
          : null,
    );
  }

  Future<void> _assign(UserAccessContext access) async {
    final controller = context.read<OffSiteWorkController>()
      ..clearActionError();
    final saved = await showOffSiteWorkAssignmentDialog(
      context: context,
      access: access,
      activeBranchId: _activeBranchId,
      membersRepository: context.read<OrganizationMembersRepository>(),
      onSubmit: (draft) => controller.createAssignment(
        access: access,
        activeBranchId: access.user.role == UserRole.branchManager
            ? _activeBranchId
            : null,
        draft: draft,
      ),
      failureMessage: () => controller.actionErrorMessage,
    );
    if (!mounted || saved != true) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Off-site work assigned.')));
  }

  String _detailsPath(UserRole role, String id) => switch (role) {
    UserRole.orgAdmin => AppRoutes.orgAdminOffSiteWorkDetailsPath(id),
    UserRole.branchManager => AppRoutes.branchManagerOffSiteWorkDetailsPath(id),
    UserRole.employee => AppRoutes.employeeOffSiteWorkDetailsPath(id),
    _ => AppRoutes.orgAdminOffSiteWorkDetailsPath(id),
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OffSiteWorkController>();
    final access = context.watch<AccessController>().accessContext;
    if (access == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final role = access.user.role;
    final isEmployee = role == UserRole.employee;
    final isManager =
        role == UserRole.orgAdmin || role == UserRole.branchManager;
    final branchName = role == UserRole.branchManager
        ? _branchController.activeBranch?.branchName
        : null;
    final items = controller.items;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveSliverPage(
          onRefresh: () => _load(force: true),
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                eyebrow: isEmployee ? 'Self Service' : 'Branch Operations',
                title: isEmployee ? 'My Off-site Work' : 'Off-site Work',
                subtitle: isEmployee
                    ? 'See your assignments and record each work milestone.'
                    : role == UserRole.branchManager
                    ? 'Assign and follow branch work${branchName == null ? '' : ' for $branchName'}.'
                    : 'Assign work and review its milestones across your organization.',
                action: isManager
                    ? AppButton.responsive(
                        text: 'Assign work',
                        iconData: Icons.add,
                        onPressed: () => _assign(access),
                      )
                    : null,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            if (controller.isLoading && items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.errorMessage != null && items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(
                  message: controller.errorMessage!,
                  onRetry: _load,
                ),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.near_me_outlined,
                  title: isEmployee
                      ? 'No off-site assignments'
                      : 'No assignments yet',
                  message: isEmployee
                      ? 'Assignments from your manager will appear here.'
                      : 'Create an assignment for an employee in your authorized branch scope.',
                ),
              )
            else
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.crossAxisExtent < 600
                      ? 1
                      : constraints.crossAxisExtent < 1000
                      ? 2
                      : 3;
                  return SliverList.separated(
                    itemCount: (items.length / columns).ceil(),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, row) {
                      final cells = <Widget>[];
                      for (var column = 0; column < columns; column++) {
                        final index = row * columns + column;
                        if (column > 0) {
                          cells.add(const SizedBox(width: AppSpacing.md));
                        }
                        cells.add(
                          Expanded(
                            child: index < items.length
                                ? OffSiteWorkAssignmentCard(
                                    assignment: items[index],
                                    isEmployee: isEmployee,
                                    onTap: () => context.push(
                                      _detailsPath(role, items[index].id),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }
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
            if (controller.errorMessage != null && items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: ErrorState(message: controller.errorMessage!),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}
