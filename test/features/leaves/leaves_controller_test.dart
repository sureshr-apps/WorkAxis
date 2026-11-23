import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/leaves/data/mock_leaves_data_source.dart';
import 'package:workaxis/features/leaves/data/mock_leaves_repository.dart';
import 'package:workaxis/features/leaves/domain/models/leave_preview.dart';
import 'package:workaxis/features/leaves/domain/models/leave_queue.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_status_counts.dart';
import 'package:workaxis/features/leaves/domain/models/leave_type_option.dart';
import 'package:workaxis/features/leaves/domain/repositories/leaves_repository.dart';
import 'package:workaxis/features/leaves/presentation/controllers/leaves_controller.dart';

import '../../helpers/access_fixtures.dart';
import 'leave_fixtures.dart';

void main() {
  group('LeavesController paging', () {
    late MockLeavesDataSource dataSource;
    late LeavesController controller;
    final access = orgAdminAccess();

    setUp(() {
      dataSource = MockLeavesDataSource(now: () => DateTime(2026, 11, 23));
      for (var i = 0; i < 4; i++) {
        dataSource.save(
          leaveRequest(id: 'extra-$i', startDate: DateTime(2027, 1, 1 + i)),
        );
      }
      controller = LeavesController(
        repository: MockLeavesRepository(dataSource, delay: Duration.zero),
        pageSize: 3,
      );
    });

    test('loads the first page, appends pages and stops at total', () async {
      await controller.loadLeaveRequests(access: access);

      expect(controller.queue, LeaveQueue.organization);
      expect(controller.items, hasLength(3));
      expect(controller.totalCount, 7);
      expect(controller.hasMore, isTrue);

      await controller.loadMore(access: access);
      expect(controller.items, hasLength(6));

      await controller.loadMore(access: access);
      expect(controller.items, hasLength(7));
      expect(controller.hasMore, isFalse);
      expect(controller.items.map((r) => r.id).toSet(), hasLength(7));

      await controller.loadMore(access: access);
      expect(controller.items, hasLength(7));
    });

    test('counts come from the server, not the loaded page', () async {
      await controller.loadLeaveRequests(access: access);

      expect(controller.items, hasLength(3));
      expect(
        controller.counts,
        const LeaveStatusCounts(pending: 6, approved: 1, rejected: 0),
      );
      expect(controller.pendingCount, 6);
    });

    test('a status filter reloads page one and keeps the counts', () async {
      await controller.loadLeaveRequests(access: access);
      await controller.loadMore(access: access);

      await controller.setStatusFilter(
        access: access,
        status: LeaveStatus.approved,
      );

      expect(controller.statusFilter, LeaveStatus.approved);
      expect(controller.items.map((r) => r.status), [LeaveStatus.approved]);
      expect(controller.totalCount, 1);
      expect(controller.counts.total, 7);
    });

    test('a reviewed request leaves a pending-filtered list', () async {
      await controller.setStatusFilter(
        access: access,
        status: LeaveStatus.pending,
      );
      final target = controller.items.first;

      final saved = await controller.reviewLeaveRequest(
        access: access,
        request: target,
        decision: LeaveStatus.approved,
      );

      expect(saved, isTrue);
      expect(controller.items.map((r) => r.id), isNot(contains(target.id)));
      expect(controller.totalCount, 5);
      expect(
        controller.counts,
        const LeaveStatusCounts(pending: 5, approved: 2, rejected: 0),
      );
    });

    test('a reviewed request is updated in place when unfiltered', () async {
      await controller.loadLeaveRequests(access: access);
      final target = controller.items.first;

      await controller.reviewLeaveRequest(
        access: access,
        request: target,
        decision: LeaveStatus.rejected,
      );

      expect(controller.items.first.id, target.id);
      expect(controller.items.first.status, LeaveStatus.rejected);
      expect(controller.totalCount, 7);
      expect(controller.counts.rejected, 1);
    });

    test('a submitted request joins the own queue and its counts', () async {
      final employee = employeeAccess();
      await controller.loadLeaveRequests(access: employee);
      final before = controller.counts;
      final totalBefore = controller.totalCount;

      await controller.submitLeaveRequest(
        access: employee,
        draft: LeaveRequestDraft(
          leaveTypeId: 'lt-sick',
          startDate: DateTime(2026, 11, 24),
          endDate: DateTime(2026, 11, 24),
          reason: 'Unwell',
        ),
      );

      expect(controller.queue, LeaveQueue.mine);
      expect(controller.items.first.reason, 'Unwell');
      expect(controller.counts.pending, before.pending + 1);
      expect(controller.totalCount, totalBefore + 1);
    });

    test('reset clears queue, filter, pages and counts', () async {
      await controller.setStatusFilter(
        access: access,
        status: LeaveStatus.pending,
      );

      controller.reset();

      expect(controller.queue, isNull);
      expect(controller.statusFilter, isNull);
      expect(controller.items, isEmpty);
      expect(controller.totalCount, 0);
      expect(controller.counts, LeaveStatusCounts.zero);
    });
  });

  group('LeavesController stale responses', () {
    late _ScriptedLeavesRepository repository;
    late LeavesController controller;
    final access = branchManagerAccess();

    setUp(() {
      repository = _ScriptedLeavesRepository();
      controller = LeavesController(repository: repository);
    });

    test('a queue change reloads page one and counts', () async {
      final load = controller.loadLeaveRequests(
        access: access,
        activeBranchId: 'br-01',
      );
      repository.completeAll();
      await load;

      final switched = controller.setQueue(
        access: access,
        activeBranchId: 'br-01',
        queue: LeaveQueue.branchEmployees,
      );
      repository.completeAll();
      await switched;

      expect(repository.pageCalls.map((c) => (c.queue, c.offset)), [
        (LeaveQueue.mine, 0),
        (LeaveQueue.branchEmployees, 0),
      ]);
      expect(repository.countCalls, [
        LeaveQueue.mine,
        LeaveQueue.branchEmployees,
      ]);
      expect(controller.items.single.id, 'branchEmployees-0');
      expect(controller.counts.pending, LeaveQueue.branchEmployees.index + 1);
    });

    test('drops a page from a superseded queue', () async {
      final first = controller.loadLeaveRequests(
        access: access,
        activeBranchId: 'br-01',
      );
      final second = controller.setQueue(
        access: access,
        activeBranchId: 'br-01',
        queue: LeaveQueue.branchEmployees,
      );

      // The newer queue answers first; the older one arrives late.
      repository.complete(1);
      repository.complete(0);
      await Future.wait([first, second]);

      expect(controller.queue, LeaveQueue.branchEmployees);
      expect(controller.items.single.id, 'branchEmployees-0');
      expect(controller.counts.pending, LeaveQueue.branchEmployees.index + 1);
      expect(controller.isLoading, isFalse);
    });

    test('a status change drops the older page but keeps its counts', () async {
      final load = controller.loadLeaveRequests(
        access: access,
        activeBranchId: 'br-01',
      );
      final filtered = controller.setStatusFilter(
        access: access,
        activeBranchId: 'br-01',
        status: LeaveStatus.approved,
      );

      repository.complete(1);
      repository.complete(0);
      await Future.wait([load, filtered]);

      expect(repository.pageCalls.last.status, LeaveStatus.approved);
      expect(controller.items.single.status, LeaveStatus.approved);
      expect(controller.counts.pending, LeaveQueue.mine.index + 1);
      expect(repository.countCalls, [LeaveQueue.mine]);
    });
  });

  group('LeavesController leave types', () {
    late _ScriptedLeavesRepository repository;
    late LeavesController controller;
    final access = employeeAccess();

    setUp(() {
      repository = _ScriptedLeavesRepository();
      controller = LeavesController(repository: repository);
    });

    test('loads once per session and shares a concurrent load', () async {
      final results = await Future.wait([
        controller.loadLeaveTypes(access),
        controller.loadLeaveTypes(access),
      ]);
      final again = await controller.loadLeaveTypes(access);

      expect(results.first, [annualLeave, sickLeave]);
      expect(again, [annualLeave, sickLeave]);
      expect(repository.leaveTypeCalls, 1);
    });

    test('reset and invalidate force a fresh load', () async {
      await controller.loadLeaveTypes(access);
      controller.reset();
      await controller.loadLeaveTypes(access);
      controller.invalidateLeaveTypes();
      await controller.loadLeaveTypes(access);

      expect(repository.leaveTypeCalls, 3);
    });

    test('a failure is not cached', () async {
      repository.leaveTypesError = StateError('offline');
      await expectLater(controller.loadLeaveTypes(access), throwsStateError);

      repository.leaveTypesError = null;
      expect(await controller.loadLeaveTypes(access), hasLength(2));
      expect(repository.leaveTypeCalls, 2);
    });

    test('a load still in flight at reset does not refill the cache', () async {
      repository.leaveTypesGate = Completer<void>();
      final stale = controller.loadLeaveTypes(access);
      controller.reset();
      repository.leaveTypesGate!.complete();
      await stale;
      repository.leaveTypesGate = null;

      await controller.loadLeaveTypes(access);
      expect(repository.leaveTypeCalls, 2);
    });
  });
}

typedef _PageCall = ({LeaveQueue queue, LeaveStatus? status, int offset});

/// Holds every page request until the test completes it, so responses can
/// arrive out of order. Counts resolve with the page of the same load.
class _ScriptedLeavesRepository implements LeavesRepository {
  final List<_PageCall> pageCalls = [];
  final List<LeaveQueue> countCalls = [];
  final List<Completer<void>> _gates = [];

  void complete(int index) => _gates[index].complete();

  void completeAll() {
    for (final gate in _gates) {
      if (!gate.isCompleted) gate.complete();
    }
  }

  @override
  Future<PageResult<LeaveRequest>> getLeaveRequestsPage({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveQueue queue,
    LeaveStatus? status,
    int offset = 0,
    int limit = defaultPageSize,
  }) async {
    pageCalls.add((queue: queue, status: status, offset: offset));
    final gate = Completer<void>();
    _gates.add(gate);
    await gate.future;
    return PageResult(
      items: [
        leaveRequest(
          id: '${queue.name}-$offset',
          status: status ?? LeaveStatus.pending,
        ),
      ],
      total: 1,
      offset: offset,
    );
  }

  @override
  Future<LeaveStatusCounts> getLeaveStatusCounts({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveQueue queue,
  }) async {
    countCalls.add(queue);
    return LeaveStatusCounts(
      pending: queue.index + 1,
      approved: 0,
      rejected: 0,
    );
  }

  int leaveTypeCalls = 0;

  /// When set, the next leave type load waits for it.
  Completer<void>? leaveTypesGate;
  Object? leaveTypesError;

  @override
  Future<List<LeaveTypeOption>> getLeaveTypes({
    required UserAccessContext access,
  }) async {
    leaveTypeCalls++;
    await leaveTypesGate?.future;
    final error = leaveTypesError;
    if (error != null) throw error;
    return [annualLeave, sickLeave];
  }

  @override
  Future<LeavePreview> previewLeaveDraft({
    required UserAccessContext access,
    required String leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    String? editingRequestId,
  }) => throw UnimplementedError();

  @override
  Future<LeavePreview> previewLeaveReview({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
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
