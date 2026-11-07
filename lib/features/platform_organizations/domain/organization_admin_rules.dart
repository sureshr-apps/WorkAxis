import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_draft.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';

/// A validation failure that carries one message per form field.
class OrganizationAdminValidationException extends ValidationException {
  OrganizationAdminValidationException(this.fieldErrors)
    : super(fieldErrors.values.first);

  /// Keys: `name`, `username`, `email`, `phone`, `password`.
  final Map<String, String> fieldErrors;
}

/// Business rules for Organization Administrators, shared by the controller
/// and both repository implementations.
class OrganizationAdminRules {
  OrganizationAdminRules._();

  static const String lastActiveAdminMessage =
      'An organization must keep at least one active administrator. '
      'Add or reactivate another administrator first.';

  /// Per-field errors for [draft]; empty when valid. Email and phone are
  /// optional login aliases and are only checked when provided.
  static Map<String, String> fieldErrors(
    OrganizationAdminDraft draft, {
    required bool isCreate,
  }) {
    final errors = <String, String>{};
    if (draft.name.trim().isEmpty) errors['name'] = 'Enter the full name.';
    if (isCreate) {
      final username = ContactValidators.username(draft.username);
      if (username != null) errors['username'] = username;
      final password = ContactValidators.password(draft.initialPassword);
      if (password != null) errors['password'] = password;
    }
    final email = ContactValidators.optionalEmail(draft.email);
    if (email != null) errors['email'] = email;
    final phone = ContactValidators.optionalPhone(draft.phone);
    if (phone != null) errors['phone'] = phone;
    return errors;
  }

  /// Throws [OrganizationAdminValidationException] when [draft] is invalid.
  static void validate(OrganizationAdminDraft draft, {required bool isCreate}) {
    final errors = fieldErrors(draft, isCreate: isCreate);
    if (errors.isNotEmpty) throw OrganizationAdminValidationException(errors);
  }

  /// Whether [adminId] is the only remaining active administrator.
  static bool isLastActiveAdmin(
    List<OrganizationAdminUser> admins,
    String adminId,
  ) {
    final active = admins
        .where((a) => a.status == OrganizationAdminStatus.active)
        .toList();
    return active.length == 1 && active.first.id == adminId;
  }

  /// Throws when moving [adminId] to [next] would leave no active admin.
  static void checkStatusChange(
    List<OrganizationAdminUser> admins,
    String adminId,
    OrganizationAdminStatus next,
  ) {
    if (next == OrganizationAdminStatus.suspended &&
        isLastActiveAdmin(admins, adminId)) {
      throw ValidationException(lastActiveAdminMessage);
    }
  }
}
