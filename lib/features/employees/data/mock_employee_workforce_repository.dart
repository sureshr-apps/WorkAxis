import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employees/domain/models/employee_workforce_history.dart';
import 'package:workaxis/features/employees/domain/repositories/employee_workforce_repository.dart';

class MockEmployeeWorkforceRepository implements EmployeeWorkforceRepository {
  const MockEmployeeWorkforceRepository();

  @override
  Future<EmployeeWorkforceHistory> getHistory({
    required UserAccessContext access,
    required String memberId,
    String? activeBranchId,
  }) async => EmployeeWorkforceHistory(
    schedules: [
      ScheduleVersion(
        id: 'mock-schedule',
        effectiveFrom: DateTime(2026, 1, 1),
        dailyWorkHours: 8,
        shiftHours: '09:00 AM - 05:00 PM',
        weeklyDayOff: DateTime.sunday % 7,
      ),
    ],
    compensations: [
      CompensationVersion(
        id: 'mock-salary',
        effectiveFrom: DateTime(2026, 1, 1),
        monthlySalary: 25000,
      ),
    ],
  );

  @override
  Future<void> saveSchedule({
    required UserAccessContext access,
    required String memberId,
    required String effectiveFrom,
    required double dailyWorkHours,
    required String shiftHours,
    required int weeklyDayOff,
    String? activeBranchId,
  }) async {}

  @override
  Future<void> saveCompensation({
    required UserAccessContext access,
    required String memberId,
    required String effectiveFrom,
    required double monthlySalary,
    String? activeBranchId,
  }) async {}
}
