import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/app/theme/app_typography.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/core/widgets/form_action_row.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/member_field.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/policies/member_form_values.dart';
import 'package:workaxis/features/employees/domain/policies/organization_member_policy.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/employee_demographics_section.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/employee_employment_section.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/employee_id_input.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/employee_photo_picker.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/member_form_feedback.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/work_hours_shift_section.dart';

/// Comprehensive Create/Edit dialog for organization accounts & employee profiles.
///
/// Accepts:
/// 1. Employee ID (optional; blank = server auto-assigns the next ID)
/// 2. Employee Name
/// 3. Mobile Number
/// 4. Aadhaar Number + Photo
/// 5. Date of Birth
/// 6. Gender
/// 7. Address
/// 8. Profile Photo
/// 9. Branch assignment
/// 10. Designation
/// 11. Joining Date
/// 12. Relieving Date
/// 13. Salary
/// 14. Status
/// 15. Shift details (daily work hours & shift window)
/// 16. Asset Details
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
  // Core Identity & Login
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late final TextEditingController _employeeCode;

  // Schedule & Work Hours
  late final TextEditingController _workHours;
  late final TextEditingController _shiftHours;

  // Demographics & KYC
  late final TextEditingController _aadhaar;
  late final TextEditingController _address;
  String? _aadhaarPhotoPath;
  String? _profilePhotoPath;
  DateTime? _dateOfBirth;
  String? _gender;

  // Employment & Terms
  late final TextEditingController _designation;
  late final TextEditingController _salary;
  late final TextEditingController _assets;
  DateTime? _joiningDate;
  DateTime? _relievingDate;
  late AccountStatus _status;

  // Access Scope & Role
  late final Set<String> _branches;
  late UserRole _role;

  /// Server/save failure only; validation problems are shown inline.
  String? _error;
  Map<MemberField, String> _fieldErrors = const {};
  final Map<MemberField, GlobalKey> _anchors = {
    for (final field in MemberField.values) field: GlobalKey(),
  };
  bool _saving = false;

  bool get _busy => _saving || widget.isSaving;

  UserRole get _effectiveRole => _isBranchManager ? UserRole.employee : _role;

  MemberFormFeedback get _feedback => MemberFormFeedback(
    required: OrganizationMemberPolicy.requiredFields(
      role: _effectiveRole,
      isCreation: !_editing,
    ),
    errors: _fieldErrors,
    anchors: _anchors,
  );

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
    _employeeCode = TextEditingController(text: member?.employeeCode ?? '');

    final initialHours = member?.dailyWorkHours ?? 8.0;
    _workHours = TextEditingController(
      text: initialHours == initialHours.roundToDouble()
          ? initialHours.toInt().toString()
          : initialHours.toStringAsFixed(1),
    );
    _shiftHours = TextEditingController(
      text: member?.shiftHours ?? '09:00 AM - 05:00 PM',
    );

    _aadhaar = TextEditingController(text: member?.aadhaarNumber ?? '');
    _address = TextEditingController(text: member?.address ?? '');
    _aadhaarPhotoPath = member?.aadhaarPhotoUrl;
    _profilePhotoPath = member?.profilePhotoUrl;
    _dateOfBirth = member?.dateOfBirth;
    _gender = member?.gender;

    _designation = TextEditingController(text: member?.designation ?? '');
    _salary = TextEditingController(
      text: member?.salary != null ? member!.salary!.toStringAsFixed(0) : '',
    );
    _assets = TextEditingController(text: member?.assetDetails ?? '');
    // New accounts default to today; an existing account keeps (or clears) its own.
    _joiningDate = member == null ? DateTime.now() : member.joiningDate;
    _relievingDate = member?.relievingDate;
    _status = member?.status ?? AccountStatus.active;

    _role = _isBranchManager
        ? UserRole.employee
        : (member?.role ?? UserRole.employee);
    _branches = member != null
        ? {...member.branchIds}
        : widget.activeBranchId == null
        ? <String>{}
        : {widget.activeBranchId!};
    if (!_isBranchManager && _role == UserRole.orgAdmin) {
      _branches.clear();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _employeeCode.dispose();
    _workHours.dispose();
    _shiftHours.dispose();
    _aadhaar.dispose();
    _address.dispose();
    _designation.dispose();
    _salary.dispose();
    _assets.dispose();
    super.dispose();
  }

  String get _title {
    if (_editing) {
      if (_isBranchManager) return 'Edit employee account';
      switch (_role) {
        case UserRole.orgAdmin:
          return 'Edit organization admin';
        case UserRole.branchManager:
          return 'Edit branch manager';
        case UserRole.employee:
        default:
          return 'Edit employee account';
      }
    }
    if (_isBranchManager) return 'Add new employee';
    switch (_role) {
      case UserRole.orgAdmin:
        return 'Add organization admin';
      case UserRole.branchManager:
        return 'Add branch manager';
      case UserRole.employee:
      default:
        return 'Add new member';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _title;
    final footer = FormActionRow(
      submitLabel: _editing ? 'Save changes' : 'Create account',
      onCancel: () => Navigator.of(context).pop(false),
      onSubmit: _busy ? null : _save,
      isBusy: _busy,
    );

    // No dismissal (back gesture, barrier tap, Escape) while a save is in flight.
    return PopScope(
      canPop: !_busy,
      child: _buildDialog(context, title, footer),
    );
  }

  Widget _buildDialog(BuildContext context, String title, Widget footer) {
    if (context.isCompact) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SafeArea(child: _buildForm()),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: footer,
            ),
          ),
        ),
      );
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
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
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).pop(false),
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
              child: footer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final hint = AppTypography.bodySmall.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    final feedback = _feedback;

    // A plain scroll view (not a lazy ListView) so every field is built and can
    // be scrolled to when it is invalid.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            ErrorBanner(message: _error!),
            const SizedBox(height: AppSpacing.md),
          ],

          // 1. Profile Photo Picker
          feedback.anchor(
            MemberField.profilePhoto,
            EmployeePhotoPicker.avatar(
              imagePath: _profilePhotoPath,
              onImageChanged: (path) =>
                  setState(() => _profilePhotoPath = path),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Employee ID (Auto / Manual)
          EmployeeIdInput(controller: _employeeCode, enabled: !_editing),
          const SizedBox(height: AppSpacing.md),

          // 3. Name & Sign-in Credentials
          feedback.anchor(
            MemberField.fullName,
            AppTextField(
              controller: _name,
              label: feedback.label('Full Name', MemberField.fullName),
              errorText: feedback.errorFor(MemberField.fullName),
              hintText: 'Enter employee full name',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: feedback.anchor(
                  MemberField.username,
                  AppTextField(
                    controller: _username,
                    label: feedback.label(
                      'Sign-in Username',
                      MemberField.username,
                    ),
                    errorText: feedback.errorFor(MemberField.username),
                    hintText: 'e.g. john.doe',
                    enabled: !_editing,
                    prefixIcon: const Icon(Icons.alternate_email, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: feedback.anchor(
                  MemberField.phone,
                  AppTextField(
                    controller: _phone,
                    label: feedback.label('Mobile Number', MemberField.phone),
                    errorText: feedback.errorFor(MemberField.phone),
                    hintText: 'e.g. +91 98765 43210',
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          feedback.anchor(
            MemberField.email,
            AppTextField(
              controller: _email,
              label: 'Email address (optional)',
              errorText: feedback.errorFor(MemberField.email),
              hintText: 'name@company.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.mail_outline, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (!_editing) ...[
            feedback.anchor(
              MemberField.password,
              AppPasswordField(
                controller: _password,
                label: feedback.label('Initial password', MemberField.password),
                errorText: feedback.errorFor(MemberField.password),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          const Divider(height: 32),

          // 4. KYC & Personal Demographics (Aadhaar, Aadhaar Photo, DOB, Gender, Address)
          EmployeeDemographicsSection(
            aadhaarController: _aadhaar,
            addressController: _address,
            aadhaarPhotoPath: _aadhaarPhotoPath,
            onAadhaarPhotoChanged: (path) =>
                setState(() => _aadhaarPhotoPath = path),
            dateOfBirth: _dateOfBirth,
            onDateOfBirthChanged: (date) => setState(() => _dateOfBirth = date),
            gender: _gender,
            onGenderChanged: (val) => setState(() => _gender = val),
            feedback: feedback,
          ),

          const Divider(height: 32),

          // 5. Employment & Compensation Terms
          EmployeeEmploymentSection(
            designationController: _designation,
            salaryController: _salary,
            assetsController: _assets,
            joiningDate: _joiningDate,
            onJoiningDateChanged: (date) => setState(() => _joiningDate = date),
            relievingDate: _relievingDate,
            onRelievingDateChanged: (date) =>
                setState(() => _relievingDate = date),
            feedback: feedback,
          ),

          const Divider(height: 32),

          // 6. Work Schedule & Shift Details (Bidirectional Sync)
          WorkHoursShiftSection(
            workHoursController: _workHours,
            shiftHoursController: _shiftHours,
            initialWorkHours: widget.member?.dailyWorkHours ?? 8.0,
            initialShiftHours:
                widget.member?.shiftHours ?? '09:00 AM - 05:00 PM',
            feedback: feedback,
          ),
          if (feedback.errorFor(MemberField.shiftHours) case final error?)
            _InlineError(error),

          const Divider(height: 32),

          // 7. Role, Status & Branch Assignment
          Text(
            'Permissions & Branch Scope',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _isBranchManager
                    ? DropdownButtonFormField<UserRole>(
                        isExpanded: true,
                        initialValue: UserRole.employee,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(
                            value: UserRole.employee,
                            child: Text('Employee'),
                          ),
                        ],
                        onChanged: null,
                      )
                    : DropdownButtonFormField<UserRole>(
                        isExpanded: true,
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
                        onChanged: (role) {
                          if (role == null) return;
                          setState(() {
                            _role = role;
                            if (_role == UserRole.orgAdmin) {
                              _branches.clear();
                            }
                          });
                        },
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<AccountStatus>(
                  isExpanded: true,
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Account Status',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: AccountStatus.active,
                      child: Text('Active'),
                    ),
                    DropdownMenuItem(
                      value: AccountStatus.suspended,
                      child: Text('Suspended'),
                    ),
                  ],
                  onChanged: (status) =>
                      setState(() => _status = status ?? AccountStatus.active),
                ),
              ),
            ],
          ),
          if (feedback.errorFor(MemberField.role) case final error?)
            feedback.anchor(MemberField.role, _InlineError(error)),
          if (_isBranchManager) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Branch managers can only add employees.', style: hint),
          ],
          const SizedBox(height: AppSpacing.md),

          if (!_isBranchManager && _role == UserRole.orgAdmin) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(color: AppColors.outlineSubtle),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.business_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Organization Administrators have organization-wide access across all branches.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              _isBranchManager
                  ? 'Active branch'
                  : feedback.label('Branch assignment', MemberField.branches),
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
            if (feedback.errorFor(MemberField.branches) case final error?)
              feedback.anchor(MemberField.branches, _InlineError(error)),
            if (_isBranchManager)
              Text(
                _editing
                    ? 'Branch assignments are preserved when a manager edits an employee.'
                    : 'Branch manager accounts can only create employees in the selected branch.',
                style: hint,
              ),
          ],
        ],
      ),
    );
  }

  /// Scrolls the first invalid field into view and focuses it when editable.
  void _revealFirstError() {
    if (_fieldErrors.isEmpty) return;
    final anchor = _anchors[_fieldErrors.keys.first]?.currentContext;
    if (anchor == null) return;
    Scrollable.ensureVisible(
      anchor,
      alignment: 0.1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    _focusFirstEditable(anchor as Element);
  }

  bool _focusFirstEditable(Element element) {
    if (element is StatefulElement && element.state is EditableTextState) {
      (element.state as EditableTextState).requestKeyboard();
      return true;
    }
    var found = false;
    element.visitChildren((child) {
      if (!found) found = _focusFirstEditable(child);
    });
    return found;
  }

  Future<void> _save() async {
    final organizationId = widget.access.organization?.id;
    if (organizationId == null) {
      setState(() => _error = 'No organization context is available.');
      return;
    }
    final errors = OrganizationMemberPolicy.validateForSave(
      values: MemberFormValues(
        role: _role,
        fullName: _name.text,
        username: _username.text,
        password: _password.text,
        phone: _phone.text,
        email: _email.text,
        aadhaarNumber: _aadhaar.text,
        aadhaarPhotoPath: _aadhaarPhotoPath,
        designation: _designation.text,
        salaryText: _salary.text,
        workHoursText: _workHours.text,
        shiftHours: _shiftHours.text,
        branchIds: _branches,
      ),
      isCreation: !_editing,
      actorIsBranchManager: _isBranchManager,
      activeBranchId: widget.activeBranchId,
    );
    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors = errors;
        _error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revealFirstError();
      });
      return;
    }

    final phone = _phone.text.trim();
    final workHours = double.tryParse(_workHours.text.trim()) ?? 8.0;
    final shiftHours = _shiftHours.text.trim().isEmpty
        ? '09:00 AM - 05:00 PM'
        : _shiftHours.text.trim();
    final salary = double.tryParse(_salary.text.trim());
    final rawAadhaar = _aadhaar.text.replaceAll(RegExp(r'\s+'), '').trim();

    final effectiveRole = _isBranchManager ? UserRole.employee : _role;
    final effectiveBranches = _isBranchManager
        ? (_editing
              ? _branches.toList(growable: false)
              : (widget.activeBranchId != null
                    ? [widget.activeBranchId!]
                    : _branches.toList(growable: false)))
        : (effectiveRole == UserRole.orgAdmin
              ? const <String>[]
              : _branches.toList(growable: false));

    final draft = OrganizationMember(
      id: widget.member?.id ?? '',
      authUid: widget.member?.authUid,
      organizationId: organizationId,
      fullName: _name.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      phone: phone.isEmpty ? null : phone,
      role: effectiveRole,
      branchIds: effectiveBranches,
      status: _status,
      dailyWorkHours: workHours,
      shiftHours: shiftHours,
      employeeCode: _employeeCode.text.trim().isNotEmpty
          ? _employeeCode.text.trim()
          : null,
      aadhaarNumber: rawAadhaar.isNotEmpty ? rawAadhaar : null,
      aadhaarPhotoUrl: _aadhaarPhotoPath,
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      address: _address.text.trim().isNotEmpty ? _address.text.trim() : null,
      profilePhotoUrl: _profilePhotoPath,
      designation: _designation.text.trim().isNotEmpty
          ? _designation.text.trim()
          : null,
      joiningDate: _joiningDate,
      relievingDate: _relievingDate,
      salary: salary,
      assetDetails: _assets.text.trim().isNotEmpty ? _assets.text.trim() : null,
    );

    setState(() {
      _saving = true;
      _error = null;
      _fieldErrors = const {};
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

class _InlineError extends StatelessWidget {
  const _InlineError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Text(
      message,
      style: AppTypography.bodySmall.copyWith(color: AppColors.error),
    ),
  );
}
