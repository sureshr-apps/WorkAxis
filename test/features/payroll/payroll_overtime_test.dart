import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/payroll/data/mock_payroll_repository.dart';
import 'package:workaxis/features/payroll/data/payroll_export_rows.dart';
import 'package:workaxis/features/payroll/domain/models/monthly_payroll.dart';
import 'package:workaxis/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:workaxis/features/payroll/presentation/payroll_overtime_labels.dart';
import 'package:workaxis/features/payroll/presentation/widgets/payroll_overview_card.dart';
import 'package:workaxis/features/payroll/presentation/widgets/payroll_record_card.dart';

const _record = PayrollRecord(
  memberId: 'm-1',
  fullName: 'Ananya Sharma',
  role: 'employee',
  employeeCode: 'EMP-1',
  available: true,
  scheduledHours: 208,
  payableHours: 196,
  actualHours: 199.5,
  scheduledWorkdays: 26,
  payableWorkdays: 25,
  unpaidLeaveDays: 1,
  unpaidLeaveImpact: 961.54,
  overtimeHours: 3.5,
  approvedOvertimeHours: 2,
  overtimePay: 245.28,
  basePay: 24038.46,
  grossPay: 24283.74,
);

const _summary = PayrollSummary(
  employeeCount: 1,
  availableCount: 1,
  scheduledHours: 208,
  payableHours: 196,
  actualHours: 199.5,
  scheduledWorkdays: 26,
  payableWorkdays: 25,
  unpaidLeaveDays: 1,
  unpaidLeaveImpact: 961.54,
  overtimeHours: 3.5,
  approvedOvertimeHours: 2,
  overtimePay: 245.28,
  basePay: 24038.46,
  grossPay: 24283.74,
);

Object? _value(CellValue cell) => switch (cell) {
  TextCellValue() => cell.value.toString(),
  IntCellValue(:final value) => value,
  DoubleCellValue(:final value) => value,
  _ => cell.toString(),
};

void main() {
  group('PayrollExportRows', () {
    test('summary export lists potential and approved overtime', () {
      final headers = PayrollExportRows.summaryHeaders;
      final row = PayrollExportRows.summaryRow('All branches', _summary);
      expect(row, hasLength(headers.length));

      Object? cell(String header) => _value(row[headers.indexOf(header)]);
      expect(cell('Potential overtime hours'), 3.5);
      expect(cell('Approved overtime hours'), 2.0);
      expect(cell('Overtime pay (INR, approved only)'), 245.28);
    });

    test('monthly export lists potential and approved overtime', () {
      final headers = PayrollExportRows.monthlyHeaders;
      final row = PayrollExportRows.monthlyRow(_record);
      expect(row, hasLength(headers.length));

      Object? cell(String header) => _value(row[headers.indexOf(header)]);
      expect(cell('Employee'), 'Ananya Sharma');
      expect(cell('Potential overtime hours'), 3.5);
      expect(cell('Approved overtime hours'), 2.0);
      expect(cell('Status'), 'Available');
    });

    test('payslip lines say which overtime is paid', () {
      final lines = Map.fromEntries(
        PayrollExportRows.payslipLines(
          _record,
          payBasis: 'hours',
          overtimeEnabled: true,
        ).map((line) => MapEntry(line.$1, line.$2)),
      );
      expect(lines['Potential overtime hours'], '3.50 h');
      expect(lines['Approved overtime hours (paid)'], '2.00 h');
      expect(lines['Overtime pay'], 'INR 245.28');
      expect(lines['Overtime policy'], 'Enabled');
      expect(
        PayrollExportRows.overtimeNote,
        contains('approved overtime is paid'),
      );
    });
  });

  test('labels put approved next to potential hours', () {
    expect(
      PayrollOvertimeLabels.approvedOfPotential(1.5, 2),
      '1.50 of 2.00 h approved',
    );
    expect(
      PayrollOvertimeLabels.potentialAndPaid(3.5, '₹245.28'),
      '3.5 h potential · ₹245.28 paid',
    );
  });

  test('mock payroll pays only the approved overtime', () async {
    final payroll = await const MockPayrollRepository().getMonthlyPayroll(
      access: const UserAccessContext(
        user: AppUser(
          id: 'user-emp-01',
          name: 'Sarah Connor',
          username: 'sarah',
          role: UserRole.employee,
        ),
      ),
      month: '2026-11',
      view: PayrollView.self,
    );
    final record = payroll.records.single;
    expect(payroll.overtimeEnabled, isTrue);
    expect(record.approvedOvertimeHours, lessThan(record.overtimeHours));
    expect(record.grossPay, closeTo(record.basePay + record.overtimePay, 0.01));
  });

  group('payroll cards', () {
    Future<void> pump(
      WidgetTester tester,
      Widget child, {
      double width = 390,
    }) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );
    }

    testWidgets('a payslip shows approved of potential overtime', (
      tester,
    ) async {
      await pump(
        tester,
        PayrollRecordCard(
          record: _record,
          month: '2026-11',
          basis: 'hours',
          overtimeEnabled: true,
          onExportPdf: (_, _, _, _) async {},
        ),
      );
      expect(find.textContaining('2.00 of 3.50 h approved'), findsOneWidget);
      expect(find.text(PayrollOvertimeLabels.paidNote), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the overview KPI counts approved overtime', (tester) async {
      await pump(
        tester,
        const PayrollOverviewCard(
          totalGross: 24283.74,
          employeeCount: 1,
          basis: 'hours',
          overtimeEnabled: true,
          monthLabel: 'November 2026',
          payableHours: 196,
          payableWorkdays: 25,
          overtimeHours: 3.5,
          approvedOvertimeHours: 2,
          overtimePay: 245.28,
        ),
        width: 1200,
      );
      expect(find.text('Approved overtime'), findsOneWidget);
      expect(find.text('2.0'), findsOneWidget);
      expect(find.textContaining('3.5 h potential'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
