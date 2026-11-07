import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

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
        fullName: draft.fullName,
        email: draft.email,
        phone: draft.phone,
        clearPhone: (draft.phone ?? '').trim().isEmpty,
        role: role,
        branchIds: branchIds,
        status: existing.status,
      ),
      branchIds: branchIds,
      status: existing.status,
    );
  }

  /// Validates a status change (suspend / restore) or password reset target.
  static void assertCanChangeCredentialsOrStatus({
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
      throw ValidationException(
        'You cannot suspend or reset the password of your own account here.',
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

  static OrganizationMember _normalized(
    OrganizationMember member, {
    required List<String> branchIds,
    required AccountStatus status,
  }) {
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
    );
  }
}
