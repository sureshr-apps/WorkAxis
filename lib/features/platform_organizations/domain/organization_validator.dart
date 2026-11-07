import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/validation/contact_validators.dart';

/// Validation shared by the mock and production organization repositories.
class OrganizationValidator {
  OrganizationValidator._();

  /// Throws [ValidationException] when [name] or the optional contact email
  /// is unusable.
  static void validate({required String name, String? contactEmail}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ValidationException('Enter the organization name.');
    }
    if (trimmed.length > 100) {
      throw ValidationException(
        'Organization name must be 100 characters or fewer.',
      );
    }
    final emailError = ContactValidators.optionalEmail(contactEmail);
    if (emailError != null) throw ValidationException(emailError);
  }
}
