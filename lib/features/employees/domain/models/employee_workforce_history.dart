class ScheduleVersion {
  const ScheduleVersion({
    required this.id,
    required this.effectiveFrom,
    required this.dailyWorkHours,
    required this.shiftHours,
    required this.weeklyDaysOff,
    this.effectiveTo,
  });

  final String id;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final double dailyWorkHours;
  final String shiftHours;

  /// Recurring days off, with Sunday as 0 and Saturday as 6. Empty means none.
  final List<int> weeklyDaysOff;

  factory ScheduleVersion.fromJson(Map<String, dynamic> json) =>
      ScheduleVersion(
        id: _string(json['id']),
        effectiveFrom: _date(json['effectiveFrom']),
        effectiveTo: _optionalDate(json['effectiveTo']),
        dailyWorkHours: _number(json['dailyWorkHours']),
        shiftHours: _string(json['shiftHours']),
        weeklyDaysOff: _parseWeeklyDaysOff(json),
      );
}

/// The version of [schedules] in force on [date] (compared by calendar day),
/// or null when none covers it. Order of [schedules] does not matter.
ScheduleVersion? scheduleInForceOn(
  Iterable<ScheduleVersion> schedules,
  DateTime date,
) {
  final day = _day(date);
  ScheduleVersion? found;
  for (final schedule in schedules) {
    final from = _day(schedule.effectiveFrom);
    final to = schedule.effectiveTo == null
        ? null
        : _day(schedule.effectiveTo!);
    if (from.isAfter(day) || (to != null && !day.isBefore(to))) continue;
    if (found == null || from.isAfter(_day(found.effectiveFrom))) {
      found = schedule;
    }
  }
  return found;
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

class CompensationVersion {
  const CompensationVersion({
    required this.id,
    required this.effectiveFrom,
    required this.monthlySalary,
    this.effectiveTo,
  });

  final String id;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final double monthlySalary;

  factory CompensationVersion.fromJson(Map<String, dynamic> json) =>
      CompensationVersion(
        id: _string(json['id']),
        effectiveFrom: _date(json['effectiveFrom']),
        effectiveTo: _optionalDate(json['effectiveTo']),
        monthlySalary: _number(json['monthlySalary']),
      );
}

class EmployeeWorkforceHistory {
  const EmployeeWorkforceHistory({
    required this.schedules,
    required this.compensations,
  });

  final List<ScheduleVersion> schedules;
  final List<CompensationVersion> compensations;

  factory EmployeeWorkforceHistory.fromJson(Map<String, dynamic> json) =>
      EmployeeWorkforceHistory(
        schedules: _list(json['schedules'])
            .map((item) => ScheduleVersion.fromJson(_map(item)))
            .toList(growable: false),
        compensations: _list(json['compensations'])
            .map((item) => CompensationVersion.fromJson(_map(item)))
            .toList(growable: false),
      );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};
List<Object?> _list(Object? value) => value is List ? value : const [];
String _string(Object? value) => value is String ? value : '';
double _number(Object? value) => value is num ? value.toDouble() : 0;

List<int> _parseWeeklyDaysOff(Map<String, dynamic> json) {
  final days =
      _list(json['weeklyDaysOff'])
          .whereType<num>()
          .map((day) => day.toInt())
          .where((day) => day >= 0 && day <= 6)
          .toSet()
          .toList()
        ..sort();
  return List.unmodifiable(days);
}

DateTime _date(Object? value) =>
    DateTime.tryParse(_string(value)) ?? DateTime(1970);
DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.tryParse(_string(value));
