class PayrollRecord {
  const PayrollRecord({
    required this.memberId,
    required this.fullName,
    required this.role,
    required this.available,
    required this.scheduledHours,
    required this.payableHours,
    required this.actualHours,
    required this.scheduledWorkdays,
    required this.payableWorkdays,
    required this.unpaidLeaveDays,
    required this.unpaidLeaveImpact,
    required this.overtimeHours,
    required this.overtimePay,
    required this.basePay,
    required this.grossPay,
    this.employeeCode,
    this.unavailableReason,
  });

  final String memberId;
  final String fullName;
  final String role;
  final String? employeeCode;
  final bool available;
  final String? unavailableReason;
  final double scheduledHours;
  final double payableHours;
  final double actualHours;
  final int scheduledWorkdays;
  final int payableWorkdays;
  final int unpaidLeaveDays;
  final double unpaidLeaveImpact;
  final double overtimeHours;
  final double overtimePay;
  final double basePay;
  final double grossPay;

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    final calculation = _map(json['calculation']);
    return PayrollRecord(
      memberId: _string(json['memberId']),
      fullName: _string(json['fullName']),
      role: _string(json['role']),
      employeeCode: json['employeeCode'] as String?,
      available: calculation['available'] == true,
      unavailableReason: calculation['unavailableReason'] as String?,
      scheduledHours: _number(calculation['scheduledHours']),
      payableHours: _number(calculation['payableHours']),
      actualHours: _number(calculation['actualHours']),
      scheduledWorkdays: _integer(calculation['scheduledWorkdays']),
      payableWorkdays: _integer(calculation['payableWorkdays']),
      unpaidLeaveDays: _integer(calculation['unpaidLeaveDays']),
      unpaidLeaveImpact: _number(calculation['unpaidLeaveImpact']),
      overtimeHours: _number(calculation['overtimeHours']),
      overtimePay: _number(calculation['overtimePay']),
      basePay: _number(calculation['basePay']),
      grossPay: _number(calculation['grossPay']),
    );
  }
}

class MonthlyPayroll {
  const MonthlyPayroll({
    required this.month,
    required this.basis,
    required this.overtimeEnabled,
    required this.records,
  });

  final String month;
  final String basis;
  final bool overtimeEnabled;
  final List<PayrollRecord> records;

  factory MonthlyPayroll.fromJson(Map<String, dynamic> json) => MonthlyPayroll(
    month: _string(json['month']),
    basis: _string(json['basis']),
    overtimeEnabled: json['overtimeEnabled'] == true,
    records: _list(json['paySlips'])
        .map((item) => PayrollRecord.fromJson(_map(item)))
        .toList(growable: false),
  );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

List<Object?> _list(Object? value) => value is List ? value : const [];

String _string(Object? value) => value is String ? value : '';

double _number(Object? value) => value is num ? value.toDouble() : 0;

int _integer(Object? value) => value is num ? value.toInt() : 0;
