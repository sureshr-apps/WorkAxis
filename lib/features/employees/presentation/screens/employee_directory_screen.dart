import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/presentation/controllers/organization_members_controller.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/organization_member_editor_dialog.dart';

class EmployeeDirectoryScreen extends StatefulWidget {
  const EmployeeDirectoryScreen({super.key});

  @override
  State<EmployeeDirectoryScreen> createState() =>
      _EmployeeDirectoryScreenState();
}

class _EmployeeDirectoryScreenState extends State<EmployeeDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  UserAccessContext? get _access =>
      context.read<AccessController>().accessContext;
  String? get _activeBranchId =>
      context.read<BranchContextController>().activeBranch?.branchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrganizationMembersController>();
    final access = context.watch<AccessController>().accessContext;
    final branchId = context
        .watch<BranchContextController>()
        .activeBranch
        ?.branchId;
    final isAdmin = access?.user.role == UserRole.orgAdmin;
    final canCreate = isAdmin || access?.user.role == UserRole.branchManager;
    final title = access?.user.role == UserRole.branchManager
        ? 'Branch Employees'
        : 'Employee Directory';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ResponsivePageContent(
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
                                  : () =>
                                        _openEditor(access, branchId: branchId),
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: AppColors.outlineSubtle),
                      ),
                      child: AppTextField.search(
                        controller: _searchController,
                        hintText: 'Search name, username, email, or role',
                        onChanged: (query) {
                          if (access != null) {
                            context
                                .read<OrganizationMembersController>()
                                .setQuery(
                                  access: access,
                                  query: query,
                                  activeBranchId: branchId,
                                );
                          }
                        },
                        onClear: () {
                          _searchController.clear();
                          if (access != null) {
                            context
                                .read<OrganizationMembersController>()
                                .setQuery(
                                  access: access,
                                  query: '',
                                  activeBranchId: branchId,
                                );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (access?.user.role == UserRole.branchManager &&
                        branchId == null)
                      const _DirectoryMessage(
                        icon: Icons.store_outlined,
                        title: 'Select an active branch',
                        detail: 'Choose one of your assigned branches before managing employees.',
                      )
                    else if (controller.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (controller.errorMessage != null)
                      _DirectoryMessage(
                        icon: Icons.cloud_off_outlined,
                        title: 'Accounts are unavailable',
                        detail: controller.errorMessage!,
                        action: AppButton.outlined(
                          text: 'Retry',
                          isFullWidth: false,
                          onPressed: _load,
                        ),
                      )
                    else if (controller.members.isEmpty)
                      _DirectoryMessage(
                        icon: Icons.badge_outlined,
                        title: 'No accounts found',
                        detail: controller.query.isEmpty
                            ? 'Accounts assigned to this scope will appear here.'
                            : 'Try a different name, username, email, or role.',
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = context.isCompact
                              ? 1
                              : context.isMedium
                              ? 2
                              : 3;
                          final gap = AppSpacing.md;
                          final width =
                              (constraints.maxWidth - gap * (columns - 1)) /
                              columns;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final member in controller.members)
                                SizedBox(
                                  width: width,
                                  child: _OrganizationMemberCard(
                                    member: member,
                                    branchNames: _branchNames(member, access),
                                    onView: () =>
                                        _showDetails(member, access, branchId),
                                    onEdit: canCreate
                                        ? () => _openEditor(
                                            access!,
                                            branchId: branchId,
                                            member: member,
                                          )
                                        : null,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
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
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => OrganizationMemberEditorDialog(
        access: access,
        activeBranchId: branchId,
        member: member,
        isSaving: controller.isSaving,
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
      builder: (context) => _MemberDetailsDialog(
        member: scopedMember,
        branchNames: _branchNames(scopedMember, access),
      ),
    );
  }
}

class _OrganizationMemberCard extends StatelessWidget {
  const _OrganizationMemberCard({
    required this.member,
    required this.branchNames,
    required this.onView,
    required this.onEdit,
  });
  final OrganizationMember member;
  final List<String> branchNames;
  final VoidCallback onView;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    child: InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outlineSubtle),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    member.initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        member.role.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip.fromStatus(
                  member.status.name == 'active' ? 'Active' : 'Suspended',
                  width: 96,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _MemberLine(icon: Icons.alternate_email, value: member.username),
            const SizedBox(height: AppSpacing.xs),
            _MemberLine(icon: Icons.mail_outline, value: member.email),
            const SizedBox(height: AppSpacing.sm),
            _MemberLine(
              icon: Icons.store_outlined,
              value: branchNames.isEmpty
                  ? 'No branch assigned'
                  : branchNames.join(', '),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    text: 'View details',
                    iconData: Icons.visibility_outlined,
                    onPressed: onView,
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Tooltip(
                    message: 'Edit account',
                    child: FilledButton(
                      onPressed: onEdit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        minimumSize: const Size(
                          AppSpacing.minTouchTarget,
                          AppSpacing.minTouchTarget,
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                      ),
                      child: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _MemberLine extends StatelessWidget {
  const _MemberLine({required this.icon, required this.value});
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}

class _DirectoryMessage extends StatelessWidget {
  const _DirectoryMessage({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });
  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(color: AppColors.outlineSubtle),
    ),
    child: Column(
      children: [
        Icon(icon, size: 32, color: AppColors.secondary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.onSurfaceVariant),
        ),
        if (action != null) ...[const SizedBox(height: AppSpacing.md), action!],
      ],
    ),
  );
}

class _MemberDetailsDialog extends StatelessWidget {
  const _MemberDetailsDialog({required this.member, required this.branchNames});
  final OrganizationMember member;
  final List<String> branchNames;
  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Detail(label: 'Role', value: member.role.displayName),
        _Detail(label: 'Username', value: member.username),
        _Detail(label: 'Email', value: member.email),
        _Detail(label: 'Phone', value: member.phone ?? 'Not provided'),
        _Detail(
          label: 'Status',
          value: member.status.name == 'active' ? 'Active' : 'Suspended',
        ),
        _Detail(
          label: 'Branches',
          value: branchNames.isEmpty ? 'None' : branchNames.join(', '),
        ),
      ],
    );
    if (context.isCompact) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: const Text('Account details')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  content,
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton.primary(
                text: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      );
    }
    return AlertDialog(
      title: Text(member.fullName),
      content: SizedBox(width: 480, child: content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
