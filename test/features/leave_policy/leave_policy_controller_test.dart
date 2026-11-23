import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/leave_policy/data/mock_leave_policy_repository.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_policy.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_input.dart';
import 'package:workaxis/features/leave_policy/presentation/controllers/leave_policy_controller.dart';

import '../../helpers/access_fixtures.dart';

/// Mock repository whose calls can be made to fail.
class _FlakyRepository extends MockLeavePolicyRepository {
  _FlakyRepository() : super(delay: Duration.zero);

  bool failLoad = false;
  bool failAccrual = false;
  bool failArchive = false;

  @override
  Future<LeavePolicy> getLeavePolicy({required UserAccessContext access}) {
    if (failLoad) throw const NetworkException();
    return super.getLeavePolicy(access: access);
  }

  @override
  Future<bool> setMonthlyAccrual({
    required UserAccessContext access,
    required bool monthlyAccrual,
  }) {
    if (failAccrual) throw const DatabaseException('boom');
    return super.setMonthlyAccrual(
      access: access,
      monthlyAccrual: monthlyAccrual,
    );
  }

  @override
  Future<void> archiveLeaveType({
    required UserAccessContext access,
    required String leaveTypeId,
  }) {
    if (failArchive) throw const NetworkException();
    return super.archiveLeaveType(access: access, leaveTypeId: leaveTypeId);
  }
}

void main() {
  late _FlakyRepository repository;
  late LeavePolicyController controller;
  final access = orgAdminAccess();

  setUp(() {
    repository = _FlakyRepository();
    controller = LeavePolicyController(repository: repository);
  });

  tearDown(() => controller.dispose());

  List<String> names() =>
      controller.policy!.leaveTypes.map((t) => t.name).toList();

  test('load fills the policy', () async {
    expect(controller.status, LeavePolicyLoadStatus.initial);
    final loading = controller.load(access);
    expect(controller.status, LeavePolicyLoadStatus.loading);
    await loading;

    expect(controller.status, LeavePolicyLoadStatus.loaded);
    expect(controller.policy!.monthlyAccrual, isFalse);
    expect(names(), [
      'Annual leave',
      'Sick leave',
      'Personal leave',
      'Unpaid leave',
    ]);
  });

  test('load failure reports a user-safe message', () async {
    repository.failLoad = true;
    await controller.load(access);

    expect(controller.status, LeavePolicyLoadStatus.error);
    expect(controller.policy, isNull);
    expect(controller.loadErrorMessage, const NetworkException().userMessage);
  });

  test('saving a new type adds it before the unpaid type', () async {
    await controller.load(access);
    final saved = await controller.saveLeaveType(
      access,
      const LeaveTypeInput(
        name: 'Study leave',
        yearlyDays: 3,
        carryForward: false,
      ),
    );

    expect(saved, isTrue);
    expect(controller.isSavingType, isFalse);
    expect(names(), [
      'Annual leave',
      'Sick leave',
      'Personal leave',
      'Study leave',
      'Unpaid leave',
    ]);
  });

  test('saving an existing type replaces it in place', () async {
    await controller.load(access);
    await controller.saveLeaveType(
      access,
      const LeaveTypeInput(
        id: 'lt-sick',
        name: 'Medical leave',
        yearlyDays: 10,
        carryForward: true,
      ),
    );

    final sick = controller.policy!.leaveTypes[1];
    expect(sick.name, 'Medical leave');
    expect(sick.yearlyDays, 10);
    expect(sick.carryForward, isTrue);
  });

  test('a rejected save keeps the data and shows the server message', () async {
    await controller.load(access);
    final saved = await controller.saveLeaveType(
      access,
      const LeaveTypeInput(
        name: 'Sick leave',
        yearlyDays: 1,
        carryForward: false,
      ),
    );

    expect(saved, isFalse);
    expect(controller.actionErrorMessage, MockLeavePolicyRepository.nameInUse);
    expect(controller.policy!.leaveTypes, hasLength(4));
    controller.clearActionError();
    expect(controller.actionErrorMessage, isNull);
  });

  test('archiving removes the type', () async {
    await controller.load(access);
    final type = controller.policy!.leaveTypes[2];

    expect(await controller.archiveLeaveType(access, type), isTrue);
    expect(names(), ['Annual leave', 'Sick leave', 'Unpaid leave']);
  });

  test('a failed archive keeps the type', () async {
    await controller.load(access);
    repository.failArchive = true;
    final type = controller.policy!.leaveTypes.first;

    expect(await controller.archiveLeaveType(access, type), isFalse);
    expect(controller.actionErrorMessage, isNotNull);
    expect(controller.policy!.leaveTypes, hasLength(4));
  });

  test('accrual toggle saves and updates the policy', () async {
    await controller.load(access);
    final pending = controller.setMonthlyAccrual(access, true);
    expect(controller.isUpdatingAccrual, isTrue);

    expect(await pending, isTrue);
    expect(controller.isUpdatingAccrual, isFalse);
    expect(controller.policy!.monthlyAccrual, isTrue);
  });

  test('a failed accrual change keeps the previous value', () async {
    await controller.load(access);
    repository.failAccrual = true;

    expect(await controller.setMonthlyAccrual(access, true), isFalse);
    expect(controller.policy!.monthlyAccrual, isFalse);
    expect(
      controller.actionErrorMessage,
      'Monthly accrual could not be changed. Please try again.',
    );
    expect(controller.isUpdatingAccrual, isFalse);
  });

  test('reset clears the policy and drops in-flight changes', () async {
    await controller.load(access);
    final pending = controller.setMonthlyAccrual(access, true);
    controller.reset();

    expect(await pending, isFalse);
    expect(controller.status, LeavePolicyLoadStatus.initial);
    expect(controller.policy, isNull);
    expect(controller.isUpdatingAccrual, isFalse);
  });

  test('other roles cannot load the policy', () async {
    await controller.load(branchManagerAccess());

    expect(controller.status, LeavePolicyLoadStatus.error);
    expect(controller.policy, isNull);
  });
}
