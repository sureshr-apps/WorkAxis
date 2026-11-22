import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/payroll/domain/models/monthly_payroll.dart';
import 'package:workaxis/features/payroll/domain/repositories/payroll_repository.dart';

class MockPayrollRepository implements PayrollRepository {
  const MockPayrollRepository();

  @override
  Future<MonthlyPayroll> getMonthlyPayroll({
    required UserAccessContext access,
    required String month,
    String? activeBranchId,
  }) async => MonthlyPayroll(
    month: month,
    basis: 'hours',
    overtimeEnabled: false,
    records: const [
      PayrollRecord(
        memberId: 'mock-member-1',
        fullName: 'Ananya Sharma',
        role: 'employee',
        employeeCode: 'EMP-10001',
        available: true,
        scheduledHours: 208,
        payableHours: 196,
        actualHours: 196,
        scheduledWorkdays: 26,
        payableWorkdays: 25,
        unpaidLeaveDays: 1,
        unpaidLeaveImpact: 961.54,
        overtimeHours: 0,
        overtimePay: 0,
        basePay: 24038.46,
        grossPay: 24038.46,
      ),
    ],
  );
}
