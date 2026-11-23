/// Display text for leave-day quantities.
abstract final class LeaveDaysFormat {
  /// `12`, `1.5`, `0.25`: no trailing zeros, at most two decimals.
  static String number(double days) {
    if (days == days.truncateToDouble()) return days.toInt().toString();
    return days
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  /// `12 days / year`, `1 day / year`.
  static String perYear(double days) =>
      '${number(days)} ${days == 1 ? 'day' : 'days'} / year';
}
