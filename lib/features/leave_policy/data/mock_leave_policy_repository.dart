import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_policy.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_input.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_policy.dart';
import 'package:workaxis/features/leave_policy/domain/repositories/leave_policy_repository.dart';
import 'package:workaxis/features/leave_policy/domain/services/leave_policy_authorization.dart';
import 'package:workaxis/features/leave_policy/domain/validators/leave_type_validator.dart';

/// In-memory [LeavePolicyRepository] enforcing the server's rules: Org
/// Admins only, unique active names, the unpaid type has no allowance and
/// cannot be removed. Each organization starts from the built-in types.
class MockLeavePolicyRepository implements LeavePolicyRepository {
  MockLeavePolicyRepository({this.delay = const Duration(milliseconds: 150)});

  final Duration delay;
  final Map<String, LeavePolicy> _policies = {};
  int _nextId = 1;

  static const String nameInUse = 'Another leave type already uses that name.';
  static const String unpaidHasNoAllowance = 'Unpaid leave has no allowance.';
  static const String cannotRemove =
      'Leave type not found, or it cannot be removed.';

  /// Built-in types every organization starts with (matching the server's
  /// seed), with sample allowances.
  static const LeavePolicy seed = LeavePolicy(
    monthlyAccrual: false,
    leaveTypes: [
      LeaveTypePolicy(
        id: 'lt-annual',
        name: 'Annual leave',
        paid: true,
        yearlyDays: 12,
        carryForward: true,
      ),
      LeaveTypePolicy(
        id: 'lt-sick',
        name: 'Sick leave',
        paid: true,
        yearlyDays: 6,
        carryForward: false,
      ),
      LeaveTypePolicy(
        id: 'lt-personal',
        name: 'Personal leave',
        paid: true,
        yearlyDays: 2,
        carryForward: false,
      ),
      LeaveTypePolicy(
        id: 'lt-unpaid',
        name: 'Unpaid leave',
        paid: false,
        yearlyDays: 0,
        carryForward: false,
      ),
    ],
  );

  Future<void> _latency() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  LeavePolicy _policyOf(String orgId) => _policies[orgId] ?? seed;

  @override
  Future<LeavePolicy> getLeavePolicy({
    required UserAccessContext access,
  }) async {
    final orgId = LeavePolicyAuthorization.organizationId(access);
    await _latency();
    return _policyOf(orgId);
  }

  @override
  Future<LeaveTypePolicy> saveLeaveType({
    required UserAccessContext access,
    required LeaveTypeInput input,
  }) async {
    final orgId = LeavePolicyAuthorization.organizationId(access);
    final errors = LeaveTypeValidator.validate(input);
    if (errors.isNotEmpty) {
      throw DatabaseException(
        'Invalid leave type',
        userMessage: errors.values.first,
      );
    }
    await _latency();
    final policy = _policyOf(orgId);
    final name = input.name.trim();
    final duplicate = policy.leaveTypes.any(
      (type) =>
          type.id != input.id &&
          type.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      throw const DatabaseException('Duplicate name', userMessage: nameInUse);
    }

    final LeaveTypePolicy saved;
    final id = input.id;
    if (id == null) {
      saved = LeaveTypePolicy(
        id: 'lt-custom-${_nextId++}',
        name: name,
        paid: true,
        yearlyDays: input.yearlyDays,
        carryForward: input.carryForward,
      );
    } else {
      final existing = policy.leaveTypes.where((type) => type.id == id);
      if (existing.isEmpty) {
        throw const NotFoundException(
          'Leave type not found',
          userMessage: 'Leave type not found.',
        );
      }
      final current = existing.first;
      if (!current.paid && (input.yearlyDays > 0 || input.carryForward)) {
        throw const DatabaseException(
          'Unpaid allowance',
          userMessage: unpaidHasNoAllowance,
        );
      }
      saved = LeaveTypePolicy(
        id: id,
        name: name,
        paid: current.paid,
        yearlyDays: current.paid ? input.yearlyDays : 0,
        carryForward: current.paid && input.carryForward,
      );
    }
    _policies[orgId] = policy.withSavedType(saved);
    return saved;
  }

  @override
  Future<void> archiveLeaveType({
    required UserAccessContext access,
    required String leaveTypeId,
  }) async {
    final orgId = LeavePolicyAuthorization.organizationId(access);
    await _latency();
    final policy = _policyOf(orgId);
    final removable = policy.leaveTypes.any(
      (type) => type.id == leaveTypeId && type.canBeRemoved,
    );
    if (!removable) {
      throw const NotFoundException(
        'Leave type not removable',
        userMessage: cannotRemove,
      );
    }
    _policies[orgId] = policy.withoutType(leaveTypeId);
  }

  @override
  Future<bool> setMonthlyAccrual({
    required UserAccessContext access,
    required bool monthlyAccrual,
  }) async {
    final orgId = LeavePolicyAuthorization.organizationId(access);
    await _latency();
    _policies[orgId] = _policyOf(orgId)
        .copyWith(monthlyAccrual: monthlyAccrual);
    return monthlyAccrual;
  }
}
