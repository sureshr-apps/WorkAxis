import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/leaves/domain/models/leave_preview.dart';
import 'package:workaxis/features/leaves/domain/models/leave_queue.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_status_counts.dart';
import 'package:workaxis/features/leaves/domain/models/leave_type_option.dart';
import 'package:workaxis/features/leaves/domain/repositories/leaves_repository.dart';
import 'package:workaxis/features/leaves/presentation/controllers/leave_preview_controller.dart';

import '../../helpers/access_fixtures.dart';
import 'leave_fixtures.dart';

void main() {
  late _PreviewRepository repository;

  setUp(() => repository = _PreviewRepository());

  LeavePreviewController controllerFor({
    Duration debounce = Duration.zero,
    UserAccessContext? access,
    String? activeBranchId,
  }) => LeavePreviewController(
    repository: repository,
    access: access ?? employeeAccess(),
    activeBranchId: activeBranchId,
    debounce: debounce,
  );

  Future<void> settle([int ms = 0]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  test('debounces draft changes and sends only the latest', () async {
    final controller = controllerFor(
      debounce: const Duration(milliseconds: 40),
    );
    repository.autoComplete = true;

    for (final day in [1, 2, 3]) {
      controller.previewDraft(
        leaveTypeId: 'lt-annual',
        startDate: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, day),
        editingRequestId: 'leave-1',
      );
    }
    expect(controller.isLoading, isTrue);
    expect(repository.draftCalls, isEmpty);

    await settle(120);

    expect(repository.draftCalls, hasLength(1));
    expect(repository.draftCalls.single.endDate, DateTime(2026, 12, 3));
    expect(repository.draftCalls.single.editingRequestId, 'leave-1');
    expect(controller.preview?.workdays, 3);
    expect(controller.isLoading, isFalse);
    controller.dispose();
  });

  test('drops a response that a newer request superseded', () async {
    final controller = controllerFor();

    controller.previewDraft(
      leaveTypeId: 'lt-annual',
      startDate: DateTime(2026, 12, 1),
      endDate: DateTime(2026, 12, 1),
    );
    await settle();
    controller.previewDraft(
      leaveTypeId: 'lt-sick',
      startDate: DateTime(2026, 12, 1),
      endDate: DateTime(2026, 12, 2),
    );
    await settle();
    expect(repository.draftCalls, hasLength(2));

    // The newer request answers first; the older one arrives late.
    repository.complete(1);
    await settle();
    repository.complete(0);
    await settle();

    expect(controller.preview?.leaveTypeId, 'lt-sick');
    expect(controller.preview?.workdays, 2);
    expect(controller.isLoading, isFalse);
    controller.dispose();
  });

  test('an invalid date range is not sent', () async {
    final controller = controllerFor();

    controller.previewDraft(
      leaveTypeId: 'lt-annual',
      startDate: DateTime(2026, 12, 5),
      endDate: DateTime(2026, 12, 1),
    );
    await settle();

    expect(repository.draftCalls, isEmpty);
    expect(controller.isLoading, isFalse);
    expect(controller.preview, isNull);
    controller.dispose();
  });

  test('a failure leaves a message and no preview', () async {
    final controller = controllerFor();
    repository.error = const NetworkException();
    repository.autoComplete = true;

    controller.previewDraft(
      leaveTypeId: 'lt-annual',
      startDate: DateTime(2026, 12, 1),
      endDate: DateTime(2026, 12, 1),
    );
    await settle(10);

    expect(controller.preview, isNull);
    expect(controller.errorMessage, isNotEmpty);
    expect(controller.isLoading, isFalse);
    controller.dispose();
  });

  test('a review preview loads immediately with the active branch', () async {
    final controller = controllerFor(
      access: branchManagerAccess(),
      activeBranchId: 'br-01',
      debounce: const Duration(seconds: 5),
    );
    repository.autoComplete = true;

    await controller.previewReview(leaveRequest(id: 'leave-3'));

    expect(repository.reviewCalls.single, ('leave-3', 'br-01'));
    expect(controller.preview?.leaveTypeId, 'lt-annual');
    controller.dispose();
  });

  test('a late response after dispose is ignored', () async {
    final controller = controllerFor();
    controller.previewDraft(
      leaveTypeId: 'lt-annual',
      startDate: DateTime(2026, 12, 1),
      endDate: DateTime(2026, 12, 1),
    );
    await settle();
    controller.dispose();

    repository.complete(0);
    await settle();

    expect(controller.isDisposed, isTrue);
  });
}

typedef _DraftCall = ({
  String leaveTypeId,
  DateTime startDate,
  DateTime endDate,
  String? editingRequestId,
});

/// Answers previews with the request's day count; holds each answer until the
/// test completes it unless [autoComplete] is set.
class _PreviewRepository implements LeavesRepository {
  final List<_DraftCall> draftCalls = [];
  final List<(String, String?)> reviewCalls = [];
  final List<Completer<void>> _gates = [];
  bool autoComplete = false;
  Object? error;

  void complete(int index) => _gates[index].complete();

  Future<LeavePreview> _answer(String typeId, int days) async {
    final gate = Completer<void>();
    _gates.add(gate);
    if (autoComplete) gate.complete();
    await gate.future;
    final failure = error;
    if (failure != null) throw failure;
    return LeavePreview(
      leaveTypeId: typeId,
      availableDays: 1,
      workdays: days,
      paidDays: days < 1 ? days : 1,
      unpaidDays: days < 1 ? 0 : days - 1,
    );
  }

  @override
  Future<LeavePreview> previewLeaveDraft({
    required UserAccessContext access,
    required String leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    String? editingRequestId,
  }) {
    draftCalls.add((
      leaveTypeId: leaveTypeId,
      startDate: startDate,
      endDate: endDate,
      editingRequestId: editingRequestId,
    ));
    return _answer(leaveTypeId, endDate.difference(startDate).inDays + 1);
  }

  @override
  Future<LeavePreview> previewLeaveReview({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
  }) {
    reviewCalls.add((request.id, activeBranchId));
    return _answer(request.leaveTypeId, request.inclusiveDays);
  }

  @override
  Future<List<LeaveTypeOption>> getLeaveTypes({
    required UserAccessContext access,
  }) => throw UnimplementedError();

  @override
  Future<PageResult<LeaveRequest>> getLeaveRequestsPage({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveQueue queue,
    LeaveStatus? status,
    int offset = 0,
    int limit = defaultPageSize,
  }) => throw UnimplementedError();

  @override
  Future<LeaveStatusCounts> getLeaveStatusCounts({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveQueue queue,
  }) => throw UnimplementedError();

  @override
  Future<LeaveRequest> submitLeaveRequest({
    required UserAccessContext access,
    String? branchId,
    String? activeBranchId,
    required LeaveRequestDraft draft,
  }) => throw UnimplementedError();

  @override
  Future<LeaveRequest> updatePendingLeaveRequest({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
    required LeaveRequestDraft draft,
  }) => throw UnimplementedError();

  @override
  Future<LeaveRequest> reviewLeaveRequest({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
    required LeaveStatus decision,
    String? reviewerNotes,
  }) => throw UnimplementedError();
}
