import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_exceptions_repository.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/checkout_correction.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_exceptions_repository.dart';
import 'package:workaxis/features/attendance/presentation/controllers/attendance_exceptions_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

import '../../helpers/fixed_clock.dart';

/// Every read fails with a raw error that must never reach the user.
class _FailingRepository implements AttendanceExceptionsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(Exception('raw backend failure'));
}

void main() {
  late AccessController accessController;
  late MockAttendanceExceptionsRepository repository;
  late AttendanceExceptionsController controller;

  setUp(() {
    accessController = AccessController(
      accessRepository: MockAccessRepository(
        dataSource: MockAccessDataSource(),
        delay: Duration.zero,
      ),
    );
    repository = MockAttendanceExceptionsRepository(now: fixedNow);
    controller = AttendanceExceptionsController(repository: repository);
  });

  tearDown(() {
    controller.dispose();
    accessController.dispose();
  });

  Future<UserAccessContext> signIn(String id, UserRole role) async {
    await accessController.resolveAccess(
      AppUser(
        id: id,
        name: 'Reviewer',
        username: id,
        role: role,
        organizationId: 'org-acme',
      ),
    );
    return accessController.accessContext!;
  }

  test('Org Admin loads organization-wide corrections and overtime', () async {
    final access = await signIn('user-oa-01', UserRole.orgAdmin);

    await controller.load(access: access);

    expect(controller.hasLoaded, isTrue);
    expect(controller.errorMessage, isNull);
    expect(controller.corrections.map((c) => c.employeeName), ['Mina Patel']);
    expect(controller.overtime.map((e) => e.employeeName), ['Alex Chen']);
    expect(controller.pendingCount, 2);
  });

  test('Branch Manager sees only the active branch', () async {
    final access = await signIn('user-bm-multi-01', UserRole.branchManager);

    await controller.load(access: access, activeBranchId: 'br-01');
    expect(controller.pendingCount, 2);

    controller.reset();
    expect(controller.hasLoaded, isFalse);
    expect(controller.pendingCount, 0);

    await controller.load(access: access, activeBranchId: 'br-02');
    expect(controller.pendingCount, 0);
  });

  test(
    'Branch Manager without an active branch gets a clear message',
    () async {
      final access = await signIn('user-bm-multi-01', UserRole.branchManager);

      await controller.load(access: access);

      expect(controller.hasLoaded, isFalse);
      // Access denials use the app's standard user-facing wording.
      expect(
        controller.errorMessage,
        'You do not have permission to perform this action.',
      );
    },
  );

  test('approving a correction refreshes the list', () async {
    final access = await signIn('user-oa-01', UserRole.orgAdmin);
    await controller.load(access: access);

    final ok = await controller.reviewCorrection(
      access: access,
      correctionId: 'corr-demo-1',
      decision: CorrectionDecision.approve,
      note: '  Confirmed with the shift lead  ',
    );

    expect(ok, isTrue);
    expect(controller.corrections, isEmpty);
    expect(controller.isSaving, isFalse);
  });

  test(
    'overtime above the potential is refused with the server message',
    () async {
      final access = await signIn('user-oa-01', UserRole.orgAdmin);
      await controller.load(access: access);

      final ok = await controller.reviewOvertime(
        access: access,
        entryId: 'att-day-overtime',
        decision: OvertimeDecision.approve,
        approvedHours: 3,
      );

      expect(ok, isFalse);
      expect(controller.actionErrorMessage, contains('at most 2.0 hours'));
      expect(controller.overtime, hasLength(1));

      controller.clearActionError();
      expect(controller.actionErrorMessage, isNull);
    },
  );

  test('approving part of the overtime removes it from the queue', () async {
    final access = await signIn('user-oa-01', UserRole.orgAdmin);
    await controller.load(access: access);

    final ok = await controller.reviewOvertime(
      access: access,
      entryId: 'att-day-overtime',
      decision: OvertimeDecision.approve,
      approvedHours: 1.5,
    );

    expect(ok, isTrue);
    expect(controller.overtime, isEmpty);
  });

  test('rejecting overtime ignores any hours', () async {
    final access = await signIn('user-oa-01', UserRole.orgAdmin);
    await controller.load(access: access);

    final ok = await controller.reviewOvertime(
      access: access,
      entryId: 'att-day-overtime',
      decision: OvertimeDecision.reject,
      approvedHours: 99,
    );

    expect(ok, isTrue);
    expect(controller.overtime, isEmpty);
  });

  test('a load failure shows the fallback, never the raw error', () async {
    final access = await signIn('user-oa-01', UserRole.orgAdmin);
    controller.dispose();
    controller = AttendanceExceptionsController(
      repository: _FailingRepository(),
    );

    await controller.load(access: access);

    expect(
      controller.errorMessage,
      'Could not load attendance exceptions. Try again.',
    );
    expect(controller.isLoading, isFalse);
  });

  test('a decision finishing after reset leaves the cleared state', () async {
    final access = await signIn('user-oa-01', UserRole.orgAdmin);
    await controller.load(access: access);

    final pending = controller.reviewCorrection(
      access: access,
      correctionId: 'corr-demo-1',
      decision: CorrectionDecision.reject,
    );
    controller.reset();

    expect(await pending, isFalse);
    expect(controller.hasLoaded, isFalse);
    expect(controller.corrections, isEmpty);
  });

  test('pending overtime entries carry the potential hours', () async {
    final access = await signIn('user-oa-01', UserRole.orgAdmin);
    await controller.load(access: access);

    final entry = controller.overtime.single;
    expect(entry.overtimeStatus, OvertimeStatus.pending);
    expect(entry.potentialOvertimeHours, 2);
  });
}
