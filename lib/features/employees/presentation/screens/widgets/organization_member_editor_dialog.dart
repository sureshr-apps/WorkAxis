import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// Create/edit dialog for organization accounts.
///
/// Business rules (who may change role/branches, scope checks) live in
/// `OrganizationMemberPolicy`; this widget only collects input, runs field
/// format checks and surfaces the failure message reported by the controller.
/// The dialog pops with `true` only after a successful save.
class OrganizationMemberEditorDialog extends StatefulWidget {
  const OrganizationMemberEditorDialog({
    super.key,
    required this.access,
    required this.activeBranchId,
    required this.isSaving,
    required this.onSave,
    this.saveErrorMessage,
    this.member,
  });

  final UserAccessContext access;
  final String? activeBranchId;
  final OrganizationMember? member;
  final bool isSaving;
  final Future<OrganizationMember?> Function(OrganizationMember, String) onSave;

  /// Reads the controller's latest action failure after [onSave] returns null.
  final String? Function()? saveErrorMessage;

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
    _email = TextEditingController(text: LoginEmail.displayable(member?.email));
    _phone = TextEditingController(text: member?.phone ?? '');
    _password = TextEditingController();
    // Editing preserves the account's current role; only creation by a
    // Branch Manager is forced to Employee.
    _role = member?.role ?? UserRole.employee;
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
    final title = _editing ? 'Edit account' : 'Add employee';
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
          appBar: AppBar(title: Text(title)),
          body: SafeArea(child: _buildForm()),
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: context.screenHeight * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    child: Text(title, style: AppTypography.headlineMedium),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(child: _buildForm()),
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

  Widget _buildForm() {
    // Role and branch assignment are chosen only when creating an account or
    // when the caller is an Organization Admin editing someone else.
    final canChooseRole = !_isBranchManager;
    final hint = AppTypography.bodySmall.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (_error != null) ...[
          ErrorBanner(message: _error!),
          const SizedBox(height: AppSpacing.md),
        ],
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
          enabled: !_editing,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _email,
          label: 'Email address (optional)',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _phone,
          label: 'Phone number (optional)',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.md),
        if (!_editing) ...[
          AppPasswordField(controller: _password, label: 'Initial password'),
          const SizedBox(height: AppSpacing.md),
        ],
        if (canChooseRole) ...[
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
        Text(
          _isBranchManager ? 'Active branch' : 'Branch assignment',
          style: AppTypography.labelLarge,
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
          Text(
            _editing
                ? 'Branch assignments are preserved when a manager edits an employee.'
                : 'Branch manager accounts can only create employees in the selected branch.',
            style: hint,
          ),
      ],
    );
  }

  String? _validateInput() {
    if (_name.text.trim().isEmpty) return 'Enter the full name.';
    if (!_editing) {
      final usernameError = ContactValidators.username(_username.text);
      if (usernameError != null) return usernameError;
      final passwordError = ContactValidators.password(_password.text);
      if (passwordError != null) return passwordError;
    }
    return ContactValidators.optionalEmail(_email.text) ??
        ContactValidators.optionalPhone(_phone.text);
  }

  Future<void> _save() async {
    final organizationId = widget.access.organization?.id;
    if (organizationId == null) {
      setState(() => _error = 'No organization context is available.');
      return;
    }
    final inputError = _validateInput();
    if (inputError != null) {
      setState(() => _error = inputError);
      return;
    }
    final phone = _phone.text.trim();
    final draft = OrganizationMember(
      id: widget.member?.id ?? '',
      authUid: widget.member?.authUid,
      organizationId: organizationId,
      fullName: _name.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      phone: phone.isEmpty ? null : phone,
      role: _role,
      branchIds: _branches.toList(growable: false),
      status: widget.member?.status ?? AccountStatus.active,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.onSave(draft, _password.text);
    if (!mounted) return;
    if (saved == null) {
      setState(() {
        _saving = false;
        _error =
            widget.saveErrorMessage?.call() ??
            'The account could not be saved. Try again.';
      });
      return;
    }
    Navigator.of(context).pop(true);
  }
}
