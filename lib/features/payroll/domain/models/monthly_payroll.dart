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
    this.authUid,
    this.unavailableReason,
  });

  final String memberId;
  final String fullName;
  final String role;
  final String? employeeCode;
  final String? authUid;
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
      authUid: json['authUid'] as String?,
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
    this.summary,
    this.branchSummaries = const [],
  });

  final String month;
  final String basis;
  final bool overtimeEnabled;
  final List<PayrollRecord> records;
  final PayrollSummary? summary;
  final List<BranchPayrollSummary> branchSummaries;

  factory MonthlyPayroll.fromJson(Map<String, dynamic> json) => MonthlyPayroll(
    month: _string(json['month']),
    basis: _string(json['basis']),
    overtimeEnabled: json['overtimeEnabled'] == true,
    records: _list(json['paySlips'])
        .map((item) => PayrollRecord.fromJson(_map(item)))
        .toList(growable: false),
    summary: json['summary'] is Map
        ? PayrollSummary.fromJson(_map(json['summary']))
        : null,
    branchSummaries: _list(json['branchSummaries'])
        .map((item) => BranchPayrollSummary.fromJson(_map(item)))
        .toList(growable: false),
  );
}

class PayrollSummary {
  const PayrollSummary({
    required this.employeeCount,
    required this.availableCount,
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
  });

  final int employeeCount;
  final int availableCount;
  final double scheduledHours;
  final double payableHours;
  final double actualHours;
  final double scheduledWorkdays;
  final double payableWorkdays;
  final double unpaidLeaveDays;
  final double unpaidLeaveImpact;
  final double overtimeHours;
  final double overtimePay;
  final double basePay;
  final double grossPay;

  factory PayrollSummary.fromJson(Map<String, dynamic> json) => PayrollSummary(
    employeeCount: _integer(json['employeeCount']),
    availableCount: _integer(json['availableCount']),
    scheduledHours: _number(json['scheduledHours']),
    payableHours: _number(json['payableHours']),
    actualHours: _number(json['actualHours']),
    scheduledWorkdays: _number(json['scheduledWorkdays']),
    payableWorkdays: _number(json['payableWorkdays']),
    unpaidLeaveDays: _number(json['unpaidLeaveDays']),
    unpaidLeaveImpact: _number(json['unpaidLeaveImpact']),
    overtimeHours: _number(json['overtimeHours']),
    overtimePay: _number(json['overtimePay']),
    basePay: _number(json['basePay']),
    grossPay: _number(json['grossPay']),
  );
}

class BranchPayrollSummary {
  const BranchPayrollSummary({
    required this.branchId,
    required this.branchName,
    required this.summary,
  });

  final String branchId;
  final String branchName;
  final PayrollSummary summary;

  factory BranchPayrollSummary.fromJson(Map<String, dynamic> json) =>
      BranchPayrollSummary(
        branchId: _string(json['branchId']),
        branchName: _string(json['branchName']),
        summary: PayrollSummary.fromJson(json),
      );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

List<Object?> _list(Object? value) => value is List ? value : const [];

String _string(Object? value) => value is String ? value : '';

double _number(Object? value) => value is num ? value.toDouble() : 0;

int _integer(Object? value) => value is num ? value.toInt() : 0;
