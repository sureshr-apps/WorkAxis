import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';

/// Form fields that can carry a validation error.
enum LicensePlanField { name, level, description, maxStores, maxUsers }

/// Business rules for a license plan draft. These mirror the server rules so
/// the form can explain a problem before a request is sent; the server stays
/// the authority.
abstract final class LicensePlanPolicy {
  static const int maxDescriptionLength = 200;

  static const String nameRequiredMessage = 'Plan Name is required.';
  static const String levelMessage =
      'Plan Level must be a positive whole number.';
  static const String maxStoresMessage =
      'Maximum Stores must be a positive whole number.';
  static const String maxUsersMessage =
      'Maximum Users must be a positive whole number.';
  static const String descriptionTooLongMessage =
      'Description must be at most $maxDescriptionLength characters.';

  /// Returns one message per invalid field. An empty map means the draft is
  /// valid.
  static Map<LicensePlanField, String> validate(LicensePlanDraftFields draft) {
    final errors = <LicensePlanField, String>{};
    if (draft.name.trim().isEmpty) {
      errors[LicensePlanField.name] = nameRequiredMessage;
    }
    if (draft.level < 1) {
      errors[LicensePlanField.level] = levelMessage;
    }
    if (draft.maxStores < 1) {
      errors[LicensePlanField.maxStores] = maxStoresMessage;
    }
    if (draft.maxUsers < 1) {
      errors[LicensePlanField.maxUsers] = maxUsersMessage;
    }
    if (draft.description.trim().length > maxDescriptionLength) {
      errors[LicensePlanField.description] = descriptionTooLongMessage;
    }
    return errors;
  }

  /// Throws a [ValidationException] carrying the first failing message. Used by
  /// repositories as a guard before any remote call.
  static void ensureValid(LicensePlanDraftFields draft) {
    final errors = validate(draft);
    if (errors.isEmpty) return;
    throw ValidationException(errors.values.first);
  }
}
