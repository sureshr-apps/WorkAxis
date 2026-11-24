import 'package:excel/excel.dart';
import 'package:workaxis/features/payroll/domain/models/monthly_payroll.dart';

/// Columns, rows and payslip lines of the payroll exports, kept free of file
/// I/O so they can be tested. Overtime shows potential and approved hours
/// side by side; only approved hours are paid.
abstract final class PayrollExportRows {
  static const String overtimeNote =
      'Only manager-approved overtime is paid. Potential overtime includes '
      'hours still pending approval or rejected.';

  static const List<String> summaryHeaders = [
    'Branch',
    'Employees',
    'Scheduled hours',
    'Payable hours',
    'Unpaid leave days',
    'Potential overtime hours',
    'Approved overtime hours',
    'Overtime pay (INR, approved only)',
    'Gross pay (INR)',
  ];

  static List<CellValue> summaryRow(String label, PayrollSummary summary) => [
    TextCellValue(label),
    IntCellValue(summary.employeeCount),
    DoubleCellValue(summary.scheduledHours),
    DoubleCellValue(summary.payableHours),
    DoubleCellValue(summary.unpaidLeaveDays),
    DoubleCellValue(summary.overtimeHours),
    DoubleCellValue(summary.approvedOvertimeHours),
    DoubleCellValue(summary.overtimePay),
    DoubleCellValue(summary.grossPay),
  ];

  static const List<String> monthlyHeaders = [
    'Employee',
    'Employee ID',
    'Role',
    'Scheduled hours',
    'Payable hours',
    'Scheduled days',
    'Payable days',
    'Paid leave days',
    'Unpaid leave days',
    'Unpaid leave impact (INR)',
    'Potential overtime hours',
    'Approved overtime hours',
    'Overtime pay (INR, approved only)',
    'Base pay (INR)',
    'Gross pay (INR)',
    'Status',
  ];

  static List<CellValue> monthlyRow(PayrollRecord record) => [
    TextCellValue(record.fullName),
    TextCellValue(record.employeeCode ?? ''),
    TextCellValue(record.role),
    DoubleCellValue(record.scheduledHours),
    DoubleCellValue(record.payableHours),
    IntCellValue(record.scheduledWorkdays),
    IntCellValue(record.payableWorkdays),
    IntCellValue(record.paidLeaveDays),
    IntCellValue(record.unpaidLeaveDays),
    DoubleCellValue(record.unpaidLeaveImpact),
    DoubleCellValue(record.overtimeHours),
    DoubleCellValue(record.approvedOvertimeHours),
    DoubleCellValue(record.overtimePay),
    DoubleCellValue(record.basePay),
    DoubleCellValue(record.grossPay),
    TextCellValue(
      record.available ? 'Available' : 'Needs schedule or salary history',
    ),
  ];

  /// Label/value lines of an available payslip, before base and gross pay.
  static List<(String, String)> payslipLines(
    PayrollRecord record, {
    required String payBasis,
    required bool overtimeEnabled,
  }) => [
    ('Calculation basis', payBasis == 'workdays' ? 'Workdays' : 'Hours'),
    ('Scheduled hours', hours(record.scheduledHours)),
    ('Payable hours', hours(record.payableHours)),
    ('Actual hours', hours(record.actualHours)),
    ('Scheduled workdays', '${record.scheduledWorkdays}'),
    ('Payable workdays', '${record.payableWorkdays}'),
    if (record.outsideEmploymentDays > 0)
      (
        'Days before joining / after relieving',
        '${record.outsideEmploymentDays}',
      ),
    ('Paid leave days', '${record.paidLeaveDays}'),
    ('Approved unpaid leave days', '${record.unpaidLeaveDays}'),
    ('Unpaid leave impact', money(record.unpaidLeaveImpact)),
    ('Overtime policy', overtimeEnabled ? 'Enabled' : 'Off'),
    ('Potential overtime hours', hours(record.overtimeHours)),
    ('Approved overtime hours (paid)', hours(record.approvedOvertimeHours)),
    ('Overtime pay', money(record.overtimePay)),
  ];

  static String money(double value) => 'INR ${value.toStringAsFixed(2)}';
  static String hours(double value) => '${value.toStringAsFixed(2)} h';
}
