import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employees/domain/models/employee_workforce_history.dart';
import 'package:workaxis/features/employees/domain/repositories/employee_workforce_repository.dart';

class SqlConnectEmployeeWorkforceRepository
    implements EmployeeWorkforceRepository {
  const SqlConnectEmployeeWorkforceRepository({required DataGateway gateway})
    // Keep the public argument name stable while retaining a private field.
    // ignore: prefer_initializing_formals
    : _gateway = gateway;

  final DataGateway _gateway;

  @override
  Future<EmployeeWorkforceHistory> getHistory({
    required UserAccessContext access,
    required String memberId,
    String? activeBranchId,
  }) async {
    try {
      final result = await _gateway.call('GetEmployeeWorkforceHistory', {
        if (memberId.isNotEmpty) 'memberId': memberId,
        'activeBranchId': ?activeBranchId,
      });
      return EmployeeWorkforceHistory.fromJson(result);
    } catch (error, stackTrace) {
      throw mapBackendError(error, stackTrace);
    }
  }

  @override
  Future<void> saveSchedule({
    required UserAccessContext access,
    required String memberId,
    required String effectiveFrom,
    required double dailyWorkHours,
    required String shiftHours,
    required List<int> weeklyDaysOff,
    String? activeBranchId,
  }) async {
    try {
      await _gateway.call('SaveEmployeeSchedule', {
        'memberId': memberId,
        'effectiveFrom': effectiveFrom,
        'dailyWorkHours': dailyWorkHours,
        'shiftHours': shiftHours,
        'weeklyDaysOff': weeklyDaysOff,
        'activeBranchId': ?activeBranchId,
      });
    } catch (error, stackTrace) {
      throw mapBackendError(error, stackTrace);
    }
  }

  @override
  Future<void> saveCompensation({
    required UserAccessContext access,
    required String memberId,
    required String effectiveFrom,
    required double monthlySalary,
    String? activeBranchId,
  }) async {
    try {
      await _gateway.call('SaveEmployeeCompensation', {
        'memberId': memberId,
        'effectiveFrom': effectiveFrom,
        'monthlySalary': monthlySalary,
        'activeBranchId': ?activeBranchId,
      });
    } catch (error, stackTrace) {
      throw mapBackendError(error, stackTrace);
    }
  }
}
