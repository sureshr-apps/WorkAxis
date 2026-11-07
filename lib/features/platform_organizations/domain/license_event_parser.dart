/// Parses license-event fields that the schema stores as text.
///
/// `planTier` looks like `Level 2` and `validityPeriod` like
/// `2026-11-07 to 2027-11-07`. Values that do not parse yield null so callers
/// fall back to real timestamps instead of fabricating dates.
class LicenseEventParser {
  LicenseEventParser._();

  static int? level(String planTier) {
    final match = RegExp(r'(\d+)').firstMatch(planTier);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static ({DateTime start, DateTime end})? period(String validityPeriod) {
    final match = RegExp(
      r'(\d{4}-\d{2}-\d{2})\s*(?:to|-)\s*(\d{4}-\d{2}-\d{2})',
    ).firstMatch(validityPeriod);
    if (match == null) return null;
    final start = DateTime.tryParse(match.group(1)!);
    final end = DateTime.tryParse(match.group(2)!);
    if (start == null || end == null) return null;
    return (start: start, end: end);
  }
}
