import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/member_field.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/policies/member_form_values.dart';

/// Business rules for managing customer-organization accounts. Used by both
/// the mock and the production repository, so they cannot drift apart.
///
/// Mirrors the server authorization matrix (`docs/backend-api.md`); the server
/// remains the enforcement point, the policy gives fast, specific feedback.
class OrganizationMemberPolicy {
  OrganizationMemberPolicy._();

  static const _orgAdminAssignable = {
    UserRole.orgAdmin,
    UserRole.branchManager,
    UserRole.employee,
  };

  /// Organization id of the caller; throws when there is none.
  static String requireOrganizationId(UserAccessContext access) {
    final orgId = access.organization?.id;
    if (orgId == null || orgId.isEmpty) {
      throw const AccessDeniedException('No organization context available.');
    }
    return orgId;
  }

  /// Only Organization Admins and Branch Managers read or manage accounts.
  static void assertCanViewMembers(UserAccessContext access) {
    requireOrganizationId(access);
    final role = access.user.role;
    if (role != UserRole.orgAdmin && role != UserRole.branchManager) {
      throw const AccessDeniedException(
        'Role cannot list organization members',
      );
    }
  }

  /// Branch Managers must work inside one of their active assigned branches.
  /// Returns the branch to scope to (null means organization-wide).
  static String? effectiveBranchId(
    UserAccessContext access,
    String? requested,
  ) {
    if (access.user.role != UserRole.branchManager) {
      if (requested != null &&
          !access.assignedBranches.any((b) => b.id == requested)) {
        throw const BranchAuthorizationException(
          'Branch is outside the caller scope',
        );
      }
      return requested;
    }
    final allowed =
        requested != null &&
        access.assignedBranches.any((b) => b.id == requested && b.isActive);
    if (!allowed) {
      throw ValidationException('Choose an active branch assigned to you.');
    }
    return requested;
  }

  /// Whether a Branch Manager may open [member] while working in [branchId].
  ///
  /// Mirrors their member lists and the backend `GetMemberById` rule: only
  /// employees assigned to that branch, so peer managers' contact details
  /// stay hidden even when their id is typed into a URL.
  static bool isVisibleToBranchManager(
    OrganizationMember member,
    String? branchId,
  ) => member.role == UserRole.employee && member.branchIds.contains(branchId);

  /// Whether [existing] is editable by the caller (used to show Edit).
  static bool canManage(
    UserAccessContext access,
    OrganizationMember existing,
    String? activeBranchId,
  ) {
    try {
      _assertCanManage(access, existing, activeBranchId);
      return true;
    } on AppException {
      return false;
    }
  }

  /// Single source of truth for mandatory fields. The editor derives its
  /// asterisks from this set and enforces it through [validateForSave], so a
  /// label can never disagree with the enforced rule.
  ///
  /// Employees must be created with Aadhaar number and photo, designation and
  /// salary; the functions backend enforces the same rule. Edits only require
  /// what every account always has (an editor may be unable to see private HR
  /// data, so it cannot be demanded on edit).
  static Set<MemberField> requiredFields({
    required UserRole role,
    required bool isCreation,
  }) => {
    MemberField.fullName,
    MemberField.dailyWorkHours,
    MemberField.shiftHours,
    if (role != UserRole.orgAdmin) MemberField.branches,
    if (isCreation) ...{MemberField.username, MemberField.password},
    if (isCreation && role == UserRole.employee) ...{
      MemberField.aadhaarNumber,
      MemberField.aadhaarPhoto,
      MemberField.designation,
      MemberField.salary,
    },
  };

  /// Field-level errors for the editor, in form order (empty = valid).
  static Map<MemberField, String> validateForSave({
    required MemberFormValues values,
    required bool isCreation,
    required bool actorIsBranchManager,
    String? activeBranchId,
  }) {
    final role = actorIsBranchManager ? UserRole.employee : values.role;
    final required = requiredFields(role: role, isCreation: isCreation);
    final found = <MemberField, String>{};
    bool blank(String v) => v.trim().isEmpty;

    if (blank(values.fullName)) {
      found[MemberField.fullName] = 'Enter the full name.';
    }
    if (isCreation) {
      final usernameError = ContactValidators.username(values.username);
      if (usernameError != null) found[MemberField.username] = usernameError;
      final passwordError = ContactValidators.password(values.password);
      if (passwordError != null) found[MemberField.password] = passwordError;
    }
    final emailError = ContactValidators.optionalEmail(values.email);
    if (emailError != null) found[MemberField.email] = emailError;
    final phoneError = ContactValidators.optionalPhone(values.phone);
    if (phoneError != null) found[MemberField.phone] = phoneError;

    final rawAadhaar = values.aadhaarNumber
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
    if (rawAadhaar.isEmpty) {
      if (required.contains(MemberField.aadhaarNumber)) {
        found[MemberField.aadhaarNumber] = 'Enter the 12-digit Aadhaar number.';
      }
    } else if (!RegExp(r'^\d{12}$').hasMatch(rawAadhaar)) {
      found[MemberField.aadhaarNumber] =
          'Aadhaar number must be exactly 12 digits.';
    }
    if (required.contains(MemberField.aadhaarPhoto) &&
        blank(values.aadhaarPhotoPath ?? '')) {
      found[MemberField.aadhaarPhoto] =
          'Attach the Aadhaar card document photo.';
    }
    if (required.contains(MemberField.designation) &&
        blank(values.designation)) {
      found[MemberField.designation] = 'Enter the employee designation.';
    }

    final salaryText = values.salaryText.trim();
    if (salaryText.isEmpty) {
      if (required.contains(MemberField.salary)) {
        found[MemberField.salary] = 'Enter the monthly salary.';
      }
    } else {
      final salary = double.tryParse(salaryText);
      if (salary == null || salary < 0) {
        found[MemberField.salary] = 'Salary must be a valid positive amount.';
      }
    }

    final hours = double.tryParse(values.workHoursText.trim());
    if (hours == null || hours < 0.5 || hours > 24) {
      found[MemberField.dailyWorkHours] =
          'Daily work hours must be between 0.5 and 24 hours.';
    }
    if (blank(values.shiftHours)) {
      found[MemberField.shiftHours] = 'Enter a shift window range.';
    }

    if (actorIsBranchManager) {
      if (activeBranchId == null && values.branchIds.isEmpty) {
        found[MemberField.branches] =
            'Choose an active branch to create an employee.';
      }
    } else if (values.role.isPlatformLevel) {
      found[MemberField.role] =
          'Platform accounts cannot be created in an organization.';
    } else if (required.contains(MemberField.branches) &&
        values.branchIds.isEmpty) {
      found[MemberField.branches] =
          'Select at least one branch for this ${values.role.displayName.toLowerCase()}.';
    }

    return {
      for (final field in MemberField.values)
        if (found.containsKey(field)) field: found[field]!,
    };
  }

  /// Validates and normalizes a new account.
  static OrganizationMember prepareCreate({
    required UserAccessContext access,
    required OrganizationMember draft,
    required String initialPassword,
    String? activeBranchId,
  }) {
    final orgId = requireOrganizationId(access);
    final actor = access.user.role;
    if (draft.organizationId != orgId) {
      throw ValidationException('This account is outside your organization.');
    }
    _validateIdentity(draft, requireUsername: true);
    final passwordError = ContactValidators.password(initialPassword);
    if (passwordError != null) throw ValidationException(passwordError);

    final List<String> branchIds;
    if (actor == UserRole.branchManager) {
      final branch = effectiveBranchId(access, activeBranchId);
      if (draft.role != UserRole.employee) {
        throw const AccessDeniedException(
          'Branch Managers may only create Employees.',
          'Branch Managers can only create Employee accounts.',
        );
      }
      if (draft.branchIds.length != 1 || draft.branchIds.single != branch) {
        throw ValidationException(
          'Employees must be created in your active branch.',
        );
      }
      branchIds = [branch!];
    } else if (actor == UserRole.orgAdmin) {
      if (!_orgAdminAssignable.contains(draft.role)) {
        throw ValidationException(
          'Platform accounts cannot be created in an organization.',
        );
      }
      branchIds = _scopedBranches(access, draft);
    } else {
      throw const AccessDeniedException('Role cannot create accounts');
    }
    return _normalized(
      draft,
      branchIds: branchIds,
      status: AccountStatus.active,
    );
  }

  /// Validates an edit and returns the member to persist. Role and branch
  /// assignments are preserved unless the caller is allowed to change them.
  static OrganizationMember prepareUpdate({
    required UserAccessContext access,
    required OrganizationMember existing,
    required OrganizationMember draft,
    String? activeBranchId,
  }) {
    final orgId = requireOrganizationId(access);
    if (existing.organizationId != orgId || draft.id != existing.id) {
      throw ValidationException('This account is outside your organization.');
    }
    _assertCanManage(access, existing, activeBranchId);
    _validateIdentity(draft, requireUsername: false);

    final isSelf = _isSelf(access, existing);
    var role = existing.role;
    var branchIds = existing.branchIds;
    if (access.user.role == UserRole.orgAdmin && !isSelf) {
      role = draft.role;
      if (!_orgAdminAssignable.contains(role)) {
        throw ValidationException(
          'Platform accounts cannot be created in an organization.',
        );
      }
      branchIds = _scopedBranches(access, draft.copyWith(role: role));
    }
    return _normalized(
      existing.copyWith(
        // copyWith keeps nulls, so emptied optional fields are cleared explicitly.
        clear: _emptiedFields(draft),
        fullName: draft.fullName,
        email: draft.email,
        phone: draft.phone,
        clearPhone: (draft.phone ?? '').trim().isEmpty,
        role: role,
        branchIds: branchIds,
        status: existing.status,
        dailyWorkHours: draft.dailyWorkHours,
        shiftHours: draft.shiftHours,
        employeeCode: draft.employeeCode,
        aadhaarNumber: draft.aadhaarNumber,
        aadhaarPhotoUrl: draft.aadhaarPhotoUrl,
        dateOfBirth: draft.dateOfBirth,
        gender: draft.gender,
        address: draft.address,
        profilePhotoUrl: draft.profilePhotoUrl,
        designation: draft.designation,
        joiningDate: draft.joiningDate,
        relievingDate: draft.relievingDate,
        clearRelievingDate: draft.relievingDate == null,
        salary: draft.salary,
        assetDetails: draft.assetDetails,
      ),
      branchIds: branchIds,
      status: existing.status,
    );
  }

  /// Validates a delete: the caller must manage the account and it must not be
  /// the caller's own.
  static void assertCanDelete({
    required UserAccessContext access,
    required OrganizationMember existing,
    String? activeBranchId,
  }) {
    final orgId = requireOrganizationId(access);
    if (existing.organizationId != orgId) {
      throw ValidationException('This account is outside your organization.');
    }
    _assertCanManage(access, existing, activeBranchId);
    if (_isSelf(access, existing)) {
      throw ValidationException('You cannot delete your own account.');
    }
  }

  /// Validates a status change (suspend / restore) target.
  static void assertCanChangeStatus({
    required UserAccessContext access,
    required OrganizationMember existing,
    String? activeBranchId,
  }) {
    final orgId = requireOrganizationId(access);
    if (existing.organizationId != orgId) {
      throw ValidationException('This account is outside your organization.');
    }
    _assertCanManage(access, existing, activeBranchId);
    if (_isSelf(access, existing)) {
      throw ValidationException('You cannot suspend your own account here.');
    }
  }

  /// Validates a password reset. Organization Admins may reset their own
  /// password from the member directory; self-status changes stay prohibited.
  static void assertCanResetPassword({
    required UserAccessContext access,
    required OrganizationMember existing,
    String? activeBranchId,
  }) {
    final orgId = requireOrganizationId(access);
    if (existing.organizationId != orgId) {
      throw ValidationException('This account is outside your organization.');
    }
    _assertCanManage(access, existing, activeBranchId);
    if (_isSelf(access, existing) && access.user.role != UserRole.orgAdmin) {
      throw ValidationException(
        'You cannot reset the password of your own account here.',
      );
    }
  }

  static void _assertCanManage(
    UserAccessContext access,
    OrganizationMember existing,
    String? activeBranchId,
  ) {
    final actor = access.user.role;
    if (actor == UserRole.orgAdmin) {
      if (existing.role.isPlatformLevel) {
        throw const AccessDeniedException('Cannot manage platform accounts');
      }
      return;
    }
    if (actor == UserRole.branchManager) {
      final branch = effectiveBranchId(access, activeBranchId);
      if (existing.role != UserRole.employee ||
          !existing.branchIds.contains(branch)) {
        throw const AccessDeniedException(
          'Branch Managers may only manage Employees in their active branch.',
          'You can only manage employees assigned to your active branch.',
        );
      }
      return;
    }
    throw const AccessDeniedException('Role cannot manage accounts');
  }

  static Set<MemberField> _emptiedFields(OrganizationMember d) {
    bool blank(String? v) => v == null || v.trim().isEmpty;
    return {
      if (blank(d.aadhaarNumber)) MemberField.aadhaarNumber,
      if (blank(d.aadhaarPhotoUrl)) MemberField.aadhaarPhoto,
      if (blank(d.profilePhotoUrl)) MemberField.profilePhoto,
      if (blank(d.gender)) MemberField.gender,
      if (blank(d.address)) MemberField.address,
      if (blank(d.designation)) MemberField.designation,
      if (blank(d.assetDetails)) MemberField.assetDetails,
      if (d.dateOfBirth == null) MemberField.dateOfBirth,
      if (d.joiningDate == null) MemberField.joiningDate,
      if (d.salary == null) MemberField.salary,
    };
  }

  static bool _isSelf(UserAccessContext access, OrganizationMember member) =>
      member.id == access.user.id || member.authUid == access.user.id;

  static void _validateIdentity(
    OrganizationMember draft, {
    required bool requireUsername,
  }) {
    if (draft.fullName.trim().isEmpty) {
      throw ValidationException('Enter the full name.');
    }
    if (requireUsername) {
      final error = ContactValidators.username(draft.username);
      if (error != null) throw ValidationException(error);
    }
    final email = ContactValidators.optionalEmail(draft.email);
    if (email != null) throw ValidationException(email);
    final phone = ContactValidators.optionalPhone(draft.phone);
    if (phone != null) throw ValidationException(phone);
  }

  static List<String> _scopedBranches(
    UserAccessContext access,
    OrganizationMember draft,
  ) {
    if (draft.role == UserRole.orgAdmin) return const [];
    final ids = draft.branchIds.toSet().toList();
    if (ids.isEmpty) {
      throw ValidationException('Select at least one branch.');
    }
    final allowed = access.assignedBranches.map((b) => b.id).toSet();
    if (ids.any((id) => !allowed.contains(id))) {
      throw ValidationException(
        'Select branches within your authorized organization.',
      );
    }
    return ids;
  }

  static String? _blankToNull(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  static OrganizationMember _normalized(
    OrganizationMember member, {
    required List<String> branchIds,
    required AccountStatus status,
  }) {
    if (member.dailyWorkHours <= 0 || member.dailyWorkHours > 24) {
      throw ValidationException('Work hours must be between 0.5 and 24 hours.');
    }
    final rawAadhaar = member.aadhaarNumber
        ?.replaceAll(RegExp(r'\s+'), '')
        .trim();
    if (rawAadhaar != null && rawAadhaar.isNotEmpty) {
      if (!RegExp(r'^\d{12}$').hasMatch(rawAadhaar)) {
        throw ValidationException('Aadhaar number must be exactly 12 digits.');
      }
    }
    if (member.salary != null && member.salary! < 0) {
      throw ValidationException('Salary cannot be negative.');
    }
    final phone = ContactValidators.normalizePhone(member.phone);
    return OrganizationMember(
      id: member.id,
      authUid: member.authUid,
      organizationId: member.organizationId,
      fullName: member.fullName.trim(),
      username: member.username.trim().toLowerCase(),
      email: member.email.trim().toLowerCase(),
      phone: phone,
      role: member.role,
      branchIds: List.unmodifiable(branchIds),
      status: status,
      dailyWorkHours: member.dailyWorkHours,
      shiftHours: member.shiftHours?.trim(),
      employeeCode: _blankToNull(member.employeeCode),
      aadhaarNumber: rawAadhaar,
      aadhaarPhotoUrl: _blankToNull(member.aadhaarPhotoUrl),
      dateOfBirth: member.dateOfBirth,
      gender: _blankToNull(member.gender),
      address: _blankToNull(member.address),
      profilePhotoUrl: _blankToNull(member.profilePhotoUrl),
      designation: _blankToNull(member.designation),
      joiningDate: member.joiningDate,
      relievingDate: member.relievingDate,
      salary: member.salary,
      assetDetails: _blankToNull(member.assetDetails),
    );
  }
}
