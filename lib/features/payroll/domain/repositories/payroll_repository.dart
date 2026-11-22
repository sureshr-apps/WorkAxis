import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/payroll/domain/models/monthly_payroll.dart';

enum PayrollView { self, employee, branchSummary, organizationSummary }

abstract interface class PayrollRepository {
  Future<MonthlyPayroll> getMonthlyPayroll({
    required UserAccessContext access,
    required String month,
    String? activeBranchId,
    PayrollView view = PayrollView.self,
    String? selectedMemberId,
  });
}
