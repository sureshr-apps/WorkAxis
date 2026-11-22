class ScheduleVersion {
  const ScheduleVersion({
    required this.id,
    required this.effectiveFrom,
    required this.dailyWorkHours,
    required this.shiftHours,
    required this.weeklyDayOff,
    this.effectiveTo,
  });

  final String id;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final double dailyWorkHours;
  final String shiftHours;

  /// Sunday is 0, Monday is 1, and Saturday is 6.
  final int weeklyDayOff;

  factory ScheduleVersion.fromJson(Map<String, dynamic> json) =>
      ScheduleVersion(
        id: _string(json['id']),
        effectiveFrom: _date(json['effectiveFrom']),
        effectiveTo: _optionalDate(json['effectiveTo']),
        dailyWorkHours: _number(json['dailyWorkHours']),
        shiftHours: _string(json['shiftHours']),
        weeklyDayOff: _integer(json['weeklyDayOff']),
      );
}

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
int _integer(Object? value) => value is num ? value.toInt() : 0;
DateTime _date(Object? value) =>
    DateTime.tryParse(_string(value)) ?? DateTime(1970);
DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.tryParse(_string(value));
