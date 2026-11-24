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
    PayrollView view = PayrollView.self,
    String? selectedMemberId,
  }) async {
    PayrollRecord record({
      required String id,
      required String name,
      required String role,
      String? authUid,
    }) => PayrollRecord(
      memberId: id,
      fullName: name,
      role: role,
      authUid: authUid,
      employeeCode: role == 'employee' ? 'EMP-10001' : null,
      available: true,
      scheduledHours: 208,
      payableHours: 196,
      actualHours: 196,
      scheduledWorkdays: 26,
      payableWorkdays: 25,
      unpaidLeaveDays: 1,
      unpaidLeaveImpact: 961.54,
      // 3.5 h worked beyond the schedule, 2 h approved: only those are paid.
      overtimeHours: 3.5,
      approvedOvertimeHours: 2,
      overtimePay: 245.28,
      basePay: 24038.46,
      grossPay: 24283.74,
    );

    final sample = record(
      id: selectedMemberId ?? 'mock-member-1',
      name: view == PayrollView.self ? access.user.name : 'Ananya Sharma',
      role: view == PayrollView.self ? access.user.role.name : 'employee',
      authUid: view == PayrollView.self ? access.user.id : null,
    );
    final summary = PayrollSummary(
      employeeCount: 1,
      availableCount: 1,
      scheduledHours: sample.scheduledHours,
      payableHours: sample.payableHours,
      actualHours: sample.actualHours,
      scheduledWorkdays: sample.scheduledWorkdays.toDouble(),
      payableWorkdays: sample.payableWorkdays.toDouble(),
      unpaidLeaveDays: sample.unpaidLeaveDays.toDouble(),
      unpaidLeaveImpact: sample.unpaidLeaveImpact,
      overtimeHours: sample.overtimeHours,
      approvedOvertimeHours: sample.approvedOvertimeHours,
      overtimePay: sample.overtimePay,
      basePay: sample.basePay,
      grossPay: sample.grossPay,
    );
    final availableBranches = view == PayrollView.branchSummary
        ? access.assignedBranches
              .where((item) => item.id == activeBranchId)
              .toList(growable: false)
        : access.assignedBranches;
    final branch = availableBranches.isEmpty ? null : availableBranches.first;
    return MonthlyPayroll(
      month: month,
      basis: 'hours',
      overtimeEnabled: true,
      records: switch (view) {
        PayrollView.self => [sample],
        PayrollView.employee => selectedMemberId == null ? const [] : [sample],
        PayrollView.branchSummary ||
        PayrollView.organizationSummary => const [],
      },
      summary:
          view == PayrollView.branchSummary ||
              view == PayrollView.organizationSummary
          ? summary
          : null,
      branchSummaries:
          branch == null ||
              (view != PayrollView.branchSummary &&
                  view != PayrollView.organizationSummary)
          ? const []
          : [
              BranchPayrollSummary(
                branchId: branch.id,
                branchName: branch.name,
                summary: summary,
              ),
            ],
    );
  }
}
