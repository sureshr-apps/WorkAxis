import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

class OrganizationMemberEditorDialog extends StatefulWidget {
  const OrganizationMemberEditorDialog({
    super.key,
    required this.access,
    required this.activeBranchId,
    required this.isSaving,
    required this.onSave,
    this.member,
  });

  final UserAccessContext access;
  final String? activeBranchId;
  final OrganizationMember? member;
  final bool isSaving;
  final Future<OrganizationMember?> Function(OrganizationMember, String) onSave;

  @override
  State<OrganizationMemberEditorDialog> createState() =>
      _OrganizationMemberEditorDialogState();
}

class _OrganizationMemberEditorDialogState
    extends State<OrganizationMemberEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late final Set<String> _branches;
  late UserRole _role;
  late AccountStatus _status;
  String? _error;
  bool _saving = false;

  bool get _editing => widget.member != null;
  bool get _isBranchManager =>
      widget.access.user.role == UserRole.branchManager;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _name = TextEditingController(text: member?.fullName ?? '');
    _username = TextEditingController(text: member?.username ?? '');
    _email = TextEditingController(text: member?.email ?? '');
    _phone = TextEditingController(text: member?.phone ?? '');
    _password = TextEditingController();
    _role = _isBranchManager
        ? UserRole.employee
        : member?.role ?? UserRole.employee;
    _status = member?.status ?? AccountStatus.active;
    _branches = member != null
        ? {...member.branchIds}
        : widget.activeBranchId == null
        ? <String>{}
        : {widget.activeBranchId!};
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppTextField(
          controller: _name,
          label: 'Full name',
          hintText: 'Enter the account holder name',
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _username,
          label: 'Username',
          hintText: 'Unique sign-in username',
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _email,
          label: 'Email address',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _phone,
          label: 'Phone number',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.md),
        if (!_editing) ...[
          AppPasswordField(controller: _password, label: 'Initial password'),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'This mock pass does not save credentials or enable sign-in.',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!_isBranchManager) ...[
          DropdownButtonFormField<UserRole>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items:
                const [
                      UserRole.orgAdmin,
                      UserRole.branchManager,
                      UserRole.employee,
                    ]
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.displayName),
                      ),
                    )
                    .toList(growable: false),
            onChanged: (role) =>
                setState(() => _role = role ?? UserRole.employee),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_editing) ...[
          DropdownButtonFormField<AccountStatus>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Account status'),
            items: AccountStatus.values
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(
                      status.name == 'active' ? 'Active' : 'Suspended',
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (status) =>
                setState(() => _status = status ?? AccountStatus.active),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          _isBranchManager ? 'Active branch' : 'Branch assignment',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final branch in widget.access.activeAssignedBranches)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _branches.contains(branch.id),
            title: Text(branch.name),
            subtitle: Text(branch.code),
            onChanged: _isBranchManager
                ? null
                : (selected) => setState(() {
                    if (selected == true) {
                      _branches.add(branch.id);
                    } else {
                      _branches.remove(branch.id);
                    }
                  }),
          ),
        if (_isBranchManager)
          const Text(
            'Branch manager accounts can only create employees in the selected branch.',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
      ],
    );
    final actions = [
      AppButton.outlined(
        text: 'Cancel',
        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
      ),
      AppButton.primary(
        text: _editing ? 'Save changes' : 'Create account',
        isLoading: _saving || widget.isSaving,
        onPressed: _save,
      ),
    ];
    if (context.isCompact) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(_editing ? 'Edit account' : 'Add employee'),
          ),
          body: SafeArea(child: content),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(child: actions.first),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: actions.last),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Dialog(
      child: SizedBox(
        width: 620,
        height: 700,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _editing ? 'Edit account' : 'Add employee',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: content),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  actions.first,
                  const SizedBox(width: AppSpacing.sm),
                  actions.last,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final username = _username.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (name.isEmpty ||
        username.isEmpty ||
        !email.contains('@') ||
        (!_editing && password.length < 8)) {
      setState(
        () => _error = 'Enter a name, username, valid email, and an initial password of at least 8 characters.',
      );
      return;
    }
    if (_branches.isEmpty) {
      setState(
        () => _error = 'Assign this account to at least one active branch.',
      );
      return;
    }
    if (_isBranchManager && widget.activeBranchId != null) {
      _branches
        ..clear()
        ..add(widget.activeBranchId!);
    }
    final previous = widget.member;
    final draft = OrganizationMember(
      id: previous?.id ?? '',
      organizationId: widget.access.organization!.id,
      fullName: name,
      username: username,
      email: email,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      role: _role,
      branchIds: _branches.toList(growable: false),
      status: _status,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.onSave(draft, password);
    if (!mounted) return;
    if (saved == null) {
      setState(() {
        _saving = false;
        _error = 'Could not save the account. Check your scope and try again.';
      });
    } else {
      Navigator.of(context).pop(true);
    }
  }
}
