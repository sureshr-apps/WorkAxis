import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_policy.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_input.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_policy.dart';

/// The organization's leave types, yearly allowances and accrual mode.
///
/// Organization Admins only: every method throws `AccessDeniedException` for
/// other roles. Allowance changes apply from the next month (each month
/// accrues at the rate in force when it began) and the accrual setting from
/// today; earlier days and past payroll keep the policy in force then.
abstract interface class LeavePolicyRepository {
  /// Active leave types (display order) and the monthly-accrual flag.
  Future<LeavePolicy> getLeavePolicy({required UserAccessContext access});

  /// Creates a type when [LeaveTypeInput.id] is null, else renames it or
  /// changes its allowance. Fails with a user-safe message when another
  /// active type has the same name or the unpaid type is given an allowance.
  Future<LeaveTypePolicy> saveLeaveType({
    required UserAccessContext access,
    required LeaveTypeInput input,
  });

  /// Hides a type from new requests; existing requests keep it. The unpaid
  /// type cannot be removed.
  Future<void> archiveLeaveType({
    required UserAccessContext access,
    required String leaveTypeId,
  });

  /// Turns monthly accrual on or off; returns the saved value.
  Future<bool> setMonthlyAccrual({
    required UserAccessContext access,
    required bool monthlyAccrual,
  });
}
