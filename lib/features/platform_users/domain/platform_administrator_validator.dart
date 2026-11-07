import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';

/// Validation shared by the mock and production Platform Users repositories.
class PlatformAdministratorValidator {
  PlatformAdministratorValidator._();

  /// Validates and normalizes a draft; throws [ValidationException].
  static PlatformAdministrator prepare(
    PlatformAdministrator draft, {
    required bool isCreate,
    String? initialPassword,
  }) {
    if (draft.fullName.trim().isEmpty) {
      throw ValidationException('Full name is required.');
    }
    if (isCreate) {
      final usernameError = ContactValidators.username(draft.username);
      if (usernameError != null) throw ValidationException(usernameError);
      final passwordError = ContactValidators.password(initialPassword);
      if (passwordError != null) throw ValidationException(passwordError);
    }
    final emailError = ContactValidators.optionalEmail(draft.email);
    if (emailError != null) throw ValidationException(emailError);
    final phoneError = ContactValidators.optionalPhone(draft.phone);
    if (phoneError != null) throw ValidationException(phoneError);
    final phone = ContactValidators.normalizePhone(draft.phone);
    return draft.copyWith(
      fullName: draft.fullName.trim(),
      username: draft.username.trim().toLowerCase(),
      email: draft.email.trim().toLowerCase(),
      phone: phone,
      clearPhone: phone == null,
    );
  }
}
