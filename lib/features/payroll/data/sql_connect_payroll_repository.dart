import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/payroll/domain/models/monthly_payroll.dart';
import 'package:workaxis/features/payroll/domain/repositories/payroll_repository.dart';

class SqlConnectPayrollRepository implements PayrollRepository {
  const SqlConnectPayrollRepository({required DataGateway gateway})
    // Keep the public argument name stable while retaining a private field.
    // ignore: prefer_initializing_formals
    : _gateway = gateway;

  final DataGateway _gateway;

  @override
  Future<MonthlyPayroll> getMonthlyPayroll({
    required UserAccessContext access,
    required String month,
    String? activeBranchId,
  }) async {
    try {
      final response = await _gateway.call('GetMonthlyPayroll', {
        'month': month,
        'activeBranchId': ?activeBranchId,
      });
      return MonthlyPayroll.fromJson(response);
    } catch (error, stackTrace) {
      throw mapBackendError(error, stackTrace);
    }
  }
}
