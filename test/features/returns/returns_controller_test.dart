import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/models/return_status_counts.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/session_fakes.dart';

/// Serves pages of [rows] (filtered like the server) and records each read.
class _ScriptedReturnsRepository implements ReturnsRepository {
  _ScriptedReturnsRepository([List<ReturnItem> rows = const []])
    : rows = [...rows];

  final List<ReturnItem> rows;
  final List<
    ({ReturnStatus? status, String? query, ReturnQueue? queue, int offset})
  >
  pageReads = [];
  final List<ReturnQueue?> countReads = [];
  bool failSubmit = false;
  ReturnStatusCounts counts = const ReturnStatusCounts(
    pending: 7,
    approved: 3,
    rejected: 1,
  );

  /// When set, page reads wait for it (to interleave responses).
  Completer<void>? gate;

  @override
  Future<PageResult<ReturnItem>> getReturnsPage({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnQueue? queue,
    ReturnStatus? status,
    String? query,
    int offset = 0,
    int limit = defaultPageSize,
  }) async {
    pageReads.add((status: status, query: query, queue: queue, offset: offset));
    final matches = rows
        .where((r) => status == null || r.status == status)
        .where(
          (r) =>
              query == null ||
              query.isEmpty ||
              r.productTitle.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    await gate?.future;
    return PageResult(
      items: matches.skip(offset).take(limit).toList(),
      total: matches.length,
      offset: offset,
    );
  }

  @override
  Future<ReturnStatusCounts> getReturnCounts({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnQueue? queue,
  }) async {
    countReads.add(queue);
    return counts;
  }

  @override
  Future<ReturnItem?> getReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required String returnId,
  }) async => rows.where((r) => r.id == returnId).firstOrNull;

  @override
  Future<ReturnItem> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  }) async {
    if (failSubmit) throw StateError('nope');
    return _item('created', ReturnStatus.pending);
  }

  @override
  Future<List<ReturnItem>> submitReturnBatch({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnBatchInput input,
  }) async {
    if (failSubmit) throw StateError('nope');
    return input.items
        .map((_) => _item('created', ReturnStatus.pending))
        .toList();
  }

  @override
  Future<void> updateReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required ReturnItem returnItem,
    required CreateReturnInput input,
  }) async {}

  @override
  Future<ReturnItem> reviewReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required ReturnItem returnItem,
    required ReturnStatus decision,
    String? reviewerNotes,
  }) async => returnItem.copyWith(status: decision);
}

ReturnItem _item(String id, ReturnStatus status, {String product = 'Milk'}) =>
    ReturnItem(
      id: id,
      organizationId: 'org-test',
      branchId: 'br-1',
      branchName: 'Branch 1',
      employeeId: 'emp-1',
      employeeName: 'Emp',
      productTitle: product,
      reason: ReturnReason.damaged,
      quantity: 1,
      unit: 'pcs',
      invoiceNumber: 'INV-1',
      returnDate: testNow,
      status: status,
    );

void main() {
  final access = UserAccessContext(user: testUser(UserRole.employee));
  final manager = UserAccessContext(user: testUser(UserRole.branchManager));
  const input = CreateReturnInput(
    productTitle: 'Milk',
    reason: ReturnReason.damaged,
    quantity: 1,
    unit: 'pcs',
    invoiceNumber: 'INV-1',
  );

  late _ScriptedReturnsRepository repository;
  late ReturnsController controller;

  ReturnsController create({int pageSize = 25}) => ReturnsController(
    repository: repository,
    pageSize: pageSize,
    searchDebounce: Duration.zero,
  );

  setUp(() {
    repository = _ScriptedReturnsRepository();
    controller = create();
  });

  tearDown(() => controller.dispose());

  test('submit succeeds on an empty first page', () async {
    await controller.loadReturns(access: access);
    expect(controller.items, isEmpty);

    final ok = await controller.submitReturn(access: access, input: input);

    expect(ok, isTrue);
    expect(controller.items.single.id, 'created');
    expect(controller.actionErrorMessage, isNull);
  });

  test('submit also works before any load (initial const list)', () async {
    final ok = await controller.submitReturn(access: access, input: input);

    expect(ok, isTrue);
    expect(controller.items, hasLength(1));
  });

  test('review replaces the item without mutating the list', () async {
    await controller.loadReturns(access: access);
    await controller.submitReturn(access: access, input: input);

    final ok = await controller.reviewReturn(
      access: access,
      item: controller.items.single,
      decision: ReturnStatus.approved,
      reviewerNotes: 'ok',
    );

    expect(ok, isTrue);
    expect(controller.items.single.status, ReturnStatus.approved);
  });

  test(
    'action failures do not replace the loaded list with an error state',
    () async {
      await controller.loadReturns(access: access);
      repository.failSubmit = true;

      final ok = await controller.submitReturn(access: access, input: input);

      expect(ok, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.actionErrorMessage, isNotNull);
      expect(controller.actionErrorMessage, isNot(contains('nope')));
      controller.clearActionError();
      expect(controller.actionErrorMessage, isNull);
    },
  );

  test('reset clears items, filters and errors', () async {
    await controller.submitReturn(access: access, input: input);
    controller.setSearchQuery('milk');
    controller.setFilter(ReturnStatus.pending);

    controller.reset();

    expect(controller.items, isEmpty);
    expect(controller.searchQuery, isEmpty);
    expect(controller.statusFilter, isNull);
    expect(controller.totalCount, 0);
  });

  group('paging', () {
    setUp(() {
      repository = _ScriptedReturnsRepository([
        for (var i = 0; i < 5; i++) _item('r$i', ReturnStatus.pending),
      ]);
      controller = create(pageSize: 2);
    });

    test('loads one page and appends the next until the total', () async {
      await controller.loadReturns(access: access);
      expect(controller.items.map((r) => r.id), ['r0', 'r1']);
      expect(controller.matchingCount, 5);
      expect(controller.hasMore, isTrue);

      await controller.loadMore();
      await controller.loadMore();
      expect(controller.items, hasLength(5));
      expect(controller.hasMore, isFalse);

      await controller.loadMore();
      expect(repository.pageReads.map((r) => r.offset), [0, 2, 4]);
    });

    test('KPI totals come from the server, not the loaded page', () async {
      await controller.loadReturns(access: access);
      expect(controller.items, hasLength(2));
      expect(controller.pendingCount, 7);
      expect(controller.totalCount, 11);
      expect(controller.queueCounts.total, 11);
    });
  });

  test('a status filter reloads page one on the server', () async {
    repository = _ScriptedReturnsRepository([
      _item('p', ReturnStatus.pending),
      _item('a', ReturnStatus.approved),
    ]);
    controller = create();
    await controller.loadReturns(access: access);

    controller.setFilter(ReturnStatus.approved);
    await pumpEventQueue();

    expect(repository.pageReads.last.status, ReturnStatus.approved);
    expect(controller.items.map((r) => r.id), ['a']);
  });

  test('search is sent to the server after the debounce', () async {
    repository = _ScriptedReturnsRepository([
      _item('m', ReturnStatus.pending),
      _item('e', ReturnStatus.pending, product: 'Eggs'),
    ]);
    controller = create();
    await controller.loadReturns(access: access);

    controller.setSearchQuery('egg');
    await pumpEventQueue();

    expect(repository.pageReads.last.query, 'egg');
    expect(controller.items.map((r) => r.id), ['e']);
  });

  test('a stale page response is dropped', () async {
    repository = _ScriptedReturnsRepository([
      _item('p', ReturnStatus.pending),
      _item('a', ReturnStatus.approved),
    ]);
    controller = create();
    await controller.loadReturns(access: access);

    final slow = Completer<void>();
    repository.gate = slow;
    controller.setFilter(ReturnStatus.pending);
    repository.gate = null;
    controller.setFilter(ReturnStatus.approved);
    await pumpEventQueue();
    slow.complete();
    await pumpEventQueue();

    expect(controller.items.map((r) => r.id), ['a']);
  });

  test('a reviewed return leaves a pending-only list', () async {
    repository = _ScriptedReturnsRepository([
      _item('p1', ReturnStatus.pending),
      _item('p2', ReturnStatus.pending),
    ]);
    controller = create();
    await controller.loadReturns(access: access);
    controller.setFilter(ReturnStatus.pending);
    await pumpEventQueue();

    await controller.reviewReturn(
      access: access,
      item: controller.items.first,
      decision: ReturnStatus.approved,
    );

    expect(controller.items.map((r) => r.id), ['p2']);
    expect(controller.matchingCount, 1);
    expect(controller.pendingCount, 6);
    expect(controller.approvedCount, 4);
  });

  test('a branch manager queue reads its own totals and page', () async {
    await controller.loadReturns(access: manager, activeBranchId: 'br-1');
    // Page one, the queue totals and the whole-branch totals.
    expect(repository.pageReads.single.queue, ReturnQueue.mine);
    expect(repository.countReads, [ReturnQueue.mine, null]);

    controller.setQueue(ReturnQueue.others);
    await pumpEventQueue();

    expect(repository.pageReads.last.queue, ReturnQueue.others);
    expect(repository.countReads.last, ReturnQueue.others);
  });

  test('findReturn falls back to the server beyond loaded pages', () async {
    repository = _ScriptedReturnsRepository([
      for (var i = 0; i < 3; i++) _item('r$i', ReturnStatus.pending),
    ]);
    controller = create(pageSize: 1);
    await controller.loadReturns(access: access);

    final found = await controller.findReturn(access: access, returnId: 'r2');

    expect(found?.id, 'r2');
    expect(controller.items.map((r) => r.id), ['r0']);
  });
}
