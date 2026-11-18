import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/account_details/account_detail_panels.dart';
import 'package:workaxis/core/widgets/account_details/account_status_panel.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/core/widgets/record_not_found_page.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/policies/organization_member_policy.dart';
import 'package:workaxis/features/employees/presentation/controllers/organization_members_controller.dart';
import 'package:workaxis/features/employees/presentation/member_account_actions.dart';
import 'package:workaxis/features/employees/presentation/member_branch_names.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/member_details_view.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// Space below the content for the floating edit button: 56dp button, 16dp
/// edge margin and a little breathing room.
const double _floatingButtonClearance = 96;

/// Full page for one organization account, reached from the employee directory.
/// [listRoute] and [listLabel] name the directory it came from, so the back
/// breadcrumb returns to the same scope (organization or branch). The layout
/// matches the platform administrator details page.
class EmployeeDetailsScreen extends StatefulWidget {
  const EmployeeDetailsScreen({
    super.key,
    required this.memberId,
    required this.listRoute,
    required this.listLabel,
  });

  final String memberId;
  final String listRoute;
  final String listLabel;

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  OrganizationMember? _member;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(covariant EmployeeDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberId != widget.memberId) _load();
  }

  String? get _activeBranchId =>
      context.read<BranchContextController>().activeBranch?.branchId;

  Future<void> _load() async {
    setState(() => _loading = true);
    final access = context.read<AccessController>().accessContext;
    final member = access == null
        ? null
        : await context.read<OrganizationMembersController>().getMember(
            access: access,
            memberId: widget.memberId,
            activeBranchId: _activeBranchId,
          );
    if (!mounted) return;
    setState(() {
      _member = member;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final member = _member;
    if (member == null) return _notFound();

    final access = context.watch<AccessController>().accessContext;
    final canManage =
        access != null &&
        OrganizationMemberPolicy.canManage(access, member, _activeBranchId);
    // Nobody suspends, resets or deletes their own account here.
    final isSelf =
        access != null &&
        (member.id == access.user.id || member.authUid == access.user.id);
    final canAct = canManage && !isSelf;
    final branchNames = memberBranchNames(member, access);

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: canManage
          ? FloatingActionButton(
              tooltip: 'Edit Employee',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              onPressed: () => context.push(_editPath(access, member.id)),
              child: const Icon(Icons.edit_outlined),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageBreadcrumb(
                  backLabel: widget.listLabel,
                  currentLabel: member.fullName,
                  onBack: () => context.go(widget.listRoute),
                ),
                const SizedBox(height: AppSpacing.md),
                const AppPageHeader(
                  eyebrow: 'Employee Records',
                  title: 'Employee details',
                  subtitle: 'Profile and account access for this employee.',
                ),
                const SizedBox(height: AppSpacing.lg),
                AccountStatusPanel(
                  isActive: member.status == AccountStatus.active,
                  activeMessage:
                      'This employee can sign in and record attendance.',
                  inactiveMessage:
                      'This employee cannot sign in while access is suspended.',
                  deleteTooltip: 'Delete ${member.fullName}',
                  onReset: canAct ? () => _resetPassword(access, member) : null,
                  onToggleActive: canAct
                      ? () => _toggleStatus(access, member)
                      : null,
                  onDelete: canAct ? () => _delete(access, member) : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AccountDetailsPanel(
                  title: 'Employee profile',
                  values: _profileValues(member, branchNames),
                ),
                const SizedBox(height: AppSpacing.md),
                AccountDetailsPanel(
                  title: 'Employment',
                  values: _employmentValues(member),
                ),
                const SizedBox(height: AppSpacing.md),
                DashboardSurfaceCard(
                  child: MemberDetailsView(
                    member: member,
                    branchNames: branchNames,
                  ),
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

  Future<void> _resetPassword(
    UserAccessContext access,
    OrganizationMember member,
  ) async {
    await resetMemberPassword(
      context,
      access: access,
      member: member,
      activeBranchId: _activeBranchId,
    );
  }

  Future<void> _toggleStatus(
    UserAccessContext access,
    OrganizationMember member,
  ) async {
    final saved = await toggleMemberStatus(
      context,
      access: access,
      member: member,
      activeBranchId: _activeBranchId,
    );
    if (saved != null) await _load();
  }

  Future<void> _delete(
    UserAccessContext access,
    OrganizationMember member,
  ) async {
    final deleted = await deleteMember(
      context,
      access: access,
      member: member,
      activeBranchId: _activeBranchId,
    );
    if (deleted && mounted) context.go(widget.listRoute);
  }

  /// Branch managers edit through the branch-scoped route.
  String _editPath(UserAccessContext access, String memberId) =>
      access.user.role == UserRole.branchManager
      ? AppRoutes.branchManagerEmployeeEditPath(memberId)
      : AppRoutes.orgAdminEmployeeEditPath(memberId);

  List<(String, String)> _profileValues(
    OrganizationMember member,
    List<String> branchNames,
  ) => [
    ('Full name', member.fullName),
    ('Role', member.role.displayName),
    ('Work email', member.email.isEmpty ? '—' : member.email),
    ('Username', member.username),
    if (member.phone != null && member.phone!.isNotEmpty)
      ('Phone number', member.phone!),
    ('Employee code', _orNotSet(member.employeeCode)),
    if (member.designation != null && member.designation!.isNotEmpty)
      ('Designation', member.designation!),
    ('Branches', branchNames.isEmpty ? 'None' : branchNames.join(', ')),
  ];

  List<(String, String)> _employmentValues(OrganizationMember member) => [
    ('Daily work hours', '${member.dailyWorkHours} h'),
    ('Shift hours', _orNotSet(member.shiftHours)),
  ];

  static String _orNotSet(String? value) =>
      value == null || value.isEmpty ? 'Not set' : value;

  Widget _notFound() => RecordNotFoundPage(
    backLabel: widget.listLabel,
    currentLabel: 'Employee',
    onBack: () => context.go(widget.listRoute),
    message: 'This account could not be found.',
    onRetry: _load,
  );
}
