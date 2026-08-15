/// Utility class for formatting, normalizing, and masking phone numbers.
abstract final class PhoneNumberFormatter {
  /// Normalizes a national number and dial code to E.164 standard format (e.g., +15551234567 or +919876543210).
  static String toE164({
    required String countryCode,
    required String nationalNumber,
  }) {
    final cleanCountry = countryCode.replaceAll(RegExp(r'[^\d+]'), '');
    final prefix =
        cleanCountry.startsWith('+') ? cleanCountry : '+$cleanCountry';
    final cleanNational = nationalNumber.replaceAll(RegExp(r'\D'), '');
    return '$prefix$cleanNational';
  }

  /// Masks a phone number for sensitive display (e.g. "+1 (***) ***-4567" or "+91 (***) ***-4567").
  static String maskPhoneNumber(String rawPhone) {
    if (rawPhone.isEmpty) return '';
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) {
      return rawPhone;
    }
    final lastFour = digits.substring(digits.length - 4);
    if (digits.length == 10) {
      // e.g. 5551234567 -> (***) ***-4567
      return '(***) ***-$lastFour';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      // e.g. 15551234567 -> +1 (***) ***-4567
      return '+1 (***) ***-$lastFour';
    } else if (digits.length == 12 && digits.startsWith('91')) {
      // e.g. 919876543210 -> +91 (***) ***-3210
      return '+91 (***) ***-$lastFour';
    }
    // Generic masking: keep country code if present, mask middle, keep last 4
    final maskedLength = digits.length - 4;
    final prefixLength = maskedLength > 3 ? 3 : 1;
    final prefix = digits.substring(0, prefixLength);
    return '+$prefix ${'*' * (digits.length - prefixLength - 4)}$lastFour';
  }

  /// Validates standard phone format.
  static bool isValidNationalNumber(String nationalNumber) {
    final clean = nationalNumber.replaceAll(RegExp(r'\D'), '');
    return clean.length >= 7 && clean.length <= 15;
  }
}
