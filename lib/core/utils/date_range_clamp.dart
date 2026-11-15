/// Returns [date] limited to the inclusive range [first]..[last].
///
/// `showDatePicker` asserts that `initialDate` lies inside the allowed range,
/// so persisted values that pre-date or post-date the range must be clamped
/// before they are handed to the picker.
DateTime clampDate(DateTime date, DateTime first, DateTime last) {
  if (date.isBefore(first)) return first;
  if (date.isAfter(last)) return last;
  return date;
}

/// The earlier of two dates.
DateTime earlierOf(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
