/// Validation of optional contact aliases (email and phone).
///
/// Both are optional login aliases (AGENTS section 3): callers validate them
/// only when the user supplied a value. Rules mirror the server
/// (`functions/src/util/identifiers.ts`).
class ContactValidators {
  ContactValidators._();

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _phoneDigits = RegExp(r'^\+\d{7,15}$');

  /// Returns an error message, or null when [value] is blank or valid.
  static String? optionalEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (v.length > 100 || !_email.hasMatch(v)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Returns an error message, or null when [value] is blank or valid.
  static String? optionalPhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final normalized = normalizePhone(v);
    if (normalized == null || !_phoneDigits.hasMatch(normalized)) {
      return 'Enter the phone number with country code, e.g. +91 98765 43210.';
    }
    return null;
  }

  /// Strips spaces, dashes and brackets, matching the server's key
  /// normalization. Returns null for blank input.
  static String? normalizePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    return v.replaceAll(RegExp(r'[\s\-().]'), '');
  }

  /// Username rule: 3-50 characters of `[a-z0-9._-]` containing a letter.
  static String? username(String? value) {
    final v = value?.trim().toLowerCase() ?? '';
    if (v.length < 3 || v.length > 50) {
      return 'Username must be 3-50 characters.';
    }
    if (!RegExp(r'^[a-z0-9._-]+$').hasMatch(v) ||
        !RegExp(r'[a-z]').hasMatch(v)) {
      return 'Username may use letters, digits, dot, dash and underscore, '
          'and must contain a letter.';
    }
    return null;
  }

  /// Password rule: 8-128 characters.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.length < 8 || v.length > 128) {
      return 'Password must be 8-128 characters.';
    }
    return null;
  }
}
