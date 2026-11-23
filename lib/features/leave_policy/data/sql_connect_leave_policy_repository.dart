import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_policy.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_input.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_policy.dart';
import 'package:workaxis/features/leave_policy/domain/repositories/leave_policy_repository.dart';
import 'package:workaxis/features/leave_policy/domain/services/leave_policy_authorization.dart';
import 'package:workaxis/features/leave_policy/domain/validators/leave_type_validator.dart';

/// [LeavePolicyRepository] backed by the `dataOp` leave-policy operations
/// (`GetLeavePolicy`, `SaveLeaveType`, `ArchiveLeaveType`,
/// `SetLeaveAccrual`). The server scopes every call to the caller's
/// organization.
class SqlConnectLeavePolicyRepository implements LeavePolicyRepository {
  SqlConnectLeavePolicyRepository({required this.gateway});

  final DataGateway gateway;

  @override
  Future<LeavePolicy> getLeavePolicy({
    required UserAccessContext access,
  }) async {
    LeavePolicyAuthorization.organizationId(access);
    final data = await gateway.call('GetLeavePolicy');
    final policy = data.object('leavePolicy');
    return LeavePolicy(
      monthlyAccrual: policy.boolean('monthlyAccrual'),
      leaveTypes: List.unmodifiable(
        policy.objects('leaveTypes').map(_leaveTypeFromJson),
      ),
    );
  }

  @override
  Future<LeaveTypePolicy> saveLeaveType({
    required UserAccessContext access,
    required LeaveTypeInput input,
  }) async {
    LeavePolicyAuthorization.organizationId(access);
    final errors = LeaveTypeValidator.validate(input);
    if (errors.isNotEmpty) {
      throw DatabaseException(
        'Invalid leave type: ${errors.keys.map((k) => k.name).join(', ')}',
        userMessage: errors.values.first,
      );
    }
    final data = await gateway.call('SaveLeaveType', {
      'id': ?input.id,
      'name': input.name.trim(),
      'yearlyDays': _jsonNumber(input.yearlyDays),
      'carryForward': input.carryForward,
    });
    return _leaveTypeFromJson(data.object('leaveType'));
  }

  @override
  Future<void> archiveLeaveType({
    required UserAccessContext access,
    required String leaveTypeId,
  }) async {
    LeavePolicyAuthorization.organizationId(access);
    await gateway.call('ArchiveLeaveType', {'id': leaveTypeId});
  }

  @override
  Future<bool> setMonthlyAccrual({
    required UserAccessContext access,
    required bool monthlyAccrual,
  }) async {
    LeavePolicyAuthorization.organizationId(access);
    final data = await gateway.call('SetLeaveAccrual', {
      'monthlyAccrual': monthlyAccrual,
    });
    return data.object('leavePolicy').boolean('monthlyAccrual');
  }

  static LeaveTypePolicy _leaveTypeFromJson(Map<String, dynamic> row) =>
      LeaveTypePolicy(
        id: row.string('id'),
        name: row.string('name'),
        paid: row.boolean('paid'),
        yearlyDays: row.optNumber('yearlyDays') ?? 0,
        carryForward: row.optBool('carryForward') ?? false,
      );

  /// Whole numbers travel as JSON integers (`12`, not `12.0`).
  static num _jsonNumber(double value) =>
      value == value.truncateToDouble() ? value.toInt() : value;
}
