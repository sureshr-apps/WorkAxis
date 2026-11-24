import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employees/domain/models/employee_workforce_history.dart';

abstract interface class EmployeeWorkforceRepository {
  Future<EmployeeWorkforceHistory> getHistory({
    required UserAccessContext access,
    required String memberId,
    String? activeBranchId,
  });

  Future<void> saveSchedule({
    required UserAccessContext access,
    required String memberId,
    required String effectiveFrom,
    required double dailyWorkHours,
    required String shiftHours,
    required List<int> weeklyDaysOff,
    String? activeBranchId,
  });

  Future<void> saveCompensation({
    required UserAccessContext access,
    required String memberId,
    required String effectiveFrom,
    required double monthlySalary,
    String? activeBranchId,
  });
}
