import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/returns/data/mock_returns_data_source.dart';
import 'package:workaxis/features/returns/data/mock_returns_repository.dart';
import 'package:workaxis/features/returns/data/returns_remote.dart';
import 'package:workaxis/features/returns/data/sql_connect_returns_repository.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/models/return_status_counts.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';

import '../../helpers/access_fixtures.dart';
import '../../helpers/fixed_clock.dart';

/// In-memory [ReturnsRemote] standing in for SQL Connect. It applies no
/// authorization (like the real operations' client side), so the repository
/// under test is what enforces scoping. Records which operations were used.
class FakeReturnsRemote implements ReturnsRemote {
  FakeReturnsRemote(Iterable<ReturnItem> seed) : rows = [...seed];

  final List<ReturnItem> rows;
  final List<String> calls = [];
  Object? failWith;
  ({String branchId, CreateReturnBatchInput input})? lastSubmit;
  ({String id, CreateReturnInput input})? lastUpdate;
  ({String id, ReturnStatus decision, String? notes})? lastReview;

  void _maybeFail() {
    final error = failWith;
    if (error != null) throw error;
  }

  PageResult<ReturnItem> _page(
    Iterable<ReturnItem> matches,
    int offset,
    int limit, {
    ReturnStatus? status,
    String? query,
  }) {
    final text = query?.trim().toLowerCase() ?? '';
    final filtered = matches
        .where((r) => status == null || r.status == status)
        .where(
          (r) =>
              text.isEmpty ||
              '${r.productTitle} ${r.invoiceNumber} ${r.employeeName}'
                  .toLowerCase()
                  .contains(text),
        )
        .toList();
    return PageResult(
      items: filtered.skip(offset).take(limit).toList(),
      total: filtered.length,
      offset: offset,
    );
  }

  Iterable<ReturnItem> _branchRows(String branchId, ReturnQueue? queue) => rows
      .where((r) => r.branchId == branchId)
      .where(
        (r) => switch (queue) {
          null => true,
          ReturnQueue.mine => r.wasSubmittedBy(managerUid),
          ReturnQueue.others => !r.wasSubmittedBy(managerUid),
        },
      );

  /// The signed-in Branch Manager, as the server would derive it.
  String managerUid = 'user-bm-multi-01';

  ReturnStatusCounts _count(Iterable<ReturnItem> matches) => ReturnStatusCounts(
    pending: matches.where((r) => r.status == ReturnStatus.pending).length,
    approved: matches.where((r) => r.status == ReturnStatus.approved).length,
    rejected: matches.where((r) => r.status == ReturnStatus.rejected).length,
  );

  @override
  Future<PageResult<ReturnItem>> listMine({
    required String organizationId,
    required String employeeUid,
    required int limit,
    int offset = 0,
    ReturnStatus? status,
    String? query,
  }) async {
    calls.add('listMine');
    _maybeFail();
    return _page(
      rows.where((r) => r.employeeId == employeeUid),
      offset,
      limit,
      status: status,
      query: query,
    );
  }

  @override
  Future<PageResult<ReturnItem>> listByBranch({
    required String organizationId,
    required BranchSummary branch,
    required int limit,
    int offset = 0,
    ReturnQueue? queue,
    ReturnStatus? status,
    String? query,
  }) async {
    calls.add(
      'listByBranch:${branch.id}${queue == null ? '' : ':${queue.name}'}',
    );
    _maybeFail();
    return _page(
      _branchRows(branch.id, queue),
      offset,
      limit,
      status: status,
      query: query,
    );
  }

  @override
  Future<PageResult<ReturnItem>> listByOrganization({
    required String organizationId,
    required int limit,
    int offset = 0,
    String? branchId,
    ReturnStatus? status,
    String? query,
  }) async {
    calls.add('listByOrganization:${branchId ?? '*'}');
    _maybeFail();
    return _page(
      rows
          .where((r) => r.organizationId == organizationId)
          .where((r) => branchId == null || r.branchId == branchId),
      offset,
      limit,
      status: status,
      query: query,
    );
  }

  @override
  Future<ReturnStatusCounts> countMine() async {
    calls.add('countMine');
    _maybeFail();
    return _count(rows.where((r) => r.employeeId == 'user-emp-01'));
  }

  @override
  Future<ReturnStatusCounts> countByBranch({
    required String branchId,
    ReturnQueue? queue,
  }) async {
    calls.add(
      'countByBranch:$branchId${queue == null ? '' : ':${queue.name}'}',
    );
    _maybeFail();
    return _count(_branchRows(branchId, queue));
  }

  @override
  Future<ReturnStatusCounts> countByOrganization({
    required String organizationId,
    String? branchId,
  }) async {
    calls.add('countByOrganization:${branchId ?? '*'}');
    _maybeFail();
    return _count(
      rows
          .where((r) => r.organizationId == organizationId)
          .where((r) => branchId == null || r.branchId == branchId),
    );
  }

  @override
  Future<ReturnItem?> getById({
    required String organizationId,
    required String returnId,
  }) async {
    calls.add('getById:$returnId');
    _maybeFail();
    return rows
        .where((r) => r.organizationId == organizationId && r.id == returnId)
        .firstOrNull;
  }

  @override
  Future<List<String>> submitBatch({
    required String branchId,
    required CreateReturnBatchInput input,
  }) async {
    calls.add('submitBatch');
    _maybeFail();
    lastSubmit = (branchId: branchId, input: input);
    return [
      for (var i = 0; i < input.items.length; i++)
        'RET-FAKE-${rows.length + i + 1}',
    ];
  }

  @override
  Future<void> update({
    required String returnId,
    required CreateReturnInput input,
  }) async {
    calls.add('update');
    _maybeFail();
    lastUpdate = (id: returnId, input: input);
  }

  @override
  Future<void> review({
    required String returnId,
    required ReturnStatus decision,
    String? reviewerNotes,
  }) async {
    calls.add('review');
    _maybeFail();
    lastReview = (id: returnId, decision: decision, notes: reviewerNotes);
    final i = rows.indexWhere((r) => r.id == returnId);
    rows[i] = rows[i].copyWith(
      status: decision,
      reviewerNotes: reviewerNotes,
      reviewedBy: 'Server Reviewer',
      reviewedAt: testNow,
    );
  }
}

const _input = CreateReturnInput(
  productTitle: 'Milk',
  reason: ReturnReason.damaged,
  quantity: 3,
  unit: 'units',
  invoiceNumber: 'INV-1',
);

/// Every return in scope, read two per page so paging is exercised too.
Future<List<ReturnItem>> _all(
  ReturnsRepository repo, {
  required UserAccessContext access,
  String? activeBranchId,
  ReturnStatus? statusFilter,
}) async {
  final items = <ReturnItem>[];
  while (true) {
    final page = await repo.getReturnsPage(
      access: access,
      activeBranchId: activeBranchId,
      status: statusFilter,
      offset: items.length,
      limit: 2,
    );
    items.addAll(page.items);
    if (!page.hasMore) return items;
  }
}

/// Behaviour every [ReturnsRepository] must have, whatever the backend.
void _contract(String name, ReturnsRepository Function() create) {
  group('ReturnsRepository contract: $name', () {
    late ReturnsRepository repo;
    setUp(() => repo = create());

    test('employee sees only their own returns', () async {
      final items = await _all(repo, access: employeeAccess());
      expect(items, isNotEmpty);
      expect(items.every((r) => r.employeeId == 'user-emp-01'), isTrue);
    });

    test('branch manager sees only the active branch', () async {
      final items = await _all(
        repo,
        access: branchManagerAccess(),
        activeBranchId: 'br-01',
      );
      expect(items, isNotEmpty);
      expect(items.every((r) => r.branchId == 'br-01'), isTrue);
    });

    test('branch manager cannot read a branch outside the assigned set', () {
      expect(
        () => _all(
          repo,
          access: branchManagerAccess(branchIds: ['br-01']),
          activeBranchId: 'br-02',
        ),
        throwsA(isA<BranchAuthorizationException>()),
      );
    });

    test('branch manager needs an active branch', () {
      expect(
        () => _all(repo, access: branchManagerAccess(activeBranchId: null)),
        throwsA(isA<BranchAuthorizationException>()),
      );
    });

    test('org admin sees the organization across branches', () async {
      final items = await _all(repo, access: orgAdminAccess());
      expect(items.map((r) => r.branchId).toSet(), {'br-01', 'br-02', 'br-04'});
      expect(items.every((r) => r.organizationId == 'org-acme'), isTrue);
    });

    test('org admin of another organization sees none of them', () async {
      final items = await _all(
        repo,
        access: orgAdminAccess(org: otherOrg, branchIds: const []),
      );
      expect(items, isEmpty);
    });

    test('status filter narrows the result', () async {
      final items = await _all(
        repo,
        access: orgAdminAccess(),
        statusFilter: ReturnStatus.pending,
      );
      expect(items, isNotEmpty);
      expect(items.every((r) => r.status == ReturnStatus.pending), isTrue);
    });

    test('platform users have no returns scope', () {
      expect(
        () => _all(repo, access: platformAccess()),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test(
      'employee submits a pending return without a placeholder bill',
      () async {
        final created = await repo.submitReturn(
          access: employeeAccess(),
          input: _input,
        );
        expect(created.status, ReturnStatus.pending);
        expect(created.branchId, 'br-01');
        expect(created.employeeId, 'user-emp-01');
        expect(created.productTitle, 'Milk');
        expect(created.billImageUrl, isNull);
      },
    );

    test('submit to an unassigned branch is rejected', () {
      expect(
        () => repo.submitReturn(
          access: employeeAccess(),
          branchId: 'br-02',
          input: _input,
        ),
        throwsA(isA<BranchAuthorizationException>()),
      );
    });

    test('org admins do not submit returns', () {
      expect(
        () => repo.submitReturn(access: orgAdminAccess(), input: _input),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test(
      'branch manager reviews a pending return in the active branch',
      () async {
        final access = branchManagerAccess();
        final pending = (await _all(
          repo,
          access: access,
          activeBranchId: 'br-01',
          statusFilter: ReturnStatus.pending,
        )).first;

        final reviewed = await repo.reviewReturn(
          access: access,
          activeBranchId: 'br-01',
          returnItem: pending,
          decision: ReturnStatus.approved,
          reviewerNotes: 'Looks fine',
        );

        expect(reviewed.id, pending.id);
        expect(reviewed.status, ReturnStatus.approved);
        expect(reviewed.reviewedBy, isNotNull);
      },
    );

    test('review outside the active branch is rejected', () async {
      final access = branchManagerAccess();
      final other = (await _all(
        repo,
        access: orgAdminAccess(),
      )).firstWhere((r) => r.branchId != 'br-01');

      expect(
        () => repo.reviewReturn(
          access: access,
          activeBranchId: 'br-01',
          returnItem: other,
          decision: ReturnStatus.approved,
        ),
        throwsA(isA<BranchAuthorizationException>()),
      );
    });

    test('employees cannot review', () async {
      final item = (await _all(repo, access: employeeAccess())).first;
      expect(
        () => repo.reviewReturn(
          access: employeeAccess(),
          returnItem: item,
          decision: ReturnStatus.rejected,
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('an org admin of another organization cannot review', () async {
      final item = (await _all(
        repo,
        access: orgAdminAccess(),
        statusFilter: ReturnStatus.pending,
      )).first;
      expect(
        () => repo.reviewReturn(
          access: orgAdminAccess(org: otherOrg, branchIds: const []),
          returnItem: item,
          decision: ReturnStatus.approved,
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('an already reviewed return cannot be reviewed again', () async {
      final access = orgAdminAccess();
      final done = (await _all(
        repo,
        access: access,
        statusFilter: ReturnStatus.approved,
      )).first;
      expect(
        () => repo.reviewReturn(
          access: access,
          returnItem: done,
          decision: ReturnStatus.rejected,
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}

void main() {
  for (final access in [
    employeeAccess(),
    branchManagerAccess(),
    orgAdminAccess(),
  ]) {
    test(
      'reads one page per call for ${access.user.role.name}, with the total',
      () async {
        final seed = MockReturnsDataSource().returns.first;
        final remote = FakeReturnsRemote([
          for (var i = 0; i < 201; i++)
            seed.copyWith(
              id: 'ret-$i',
              organizationId: 'org-acme',
              employeeId: 'user-emp-01',
              branchId: 'br-01',
            ),
        ]);
        final repo = SqlConnectReturnsRepository(remote: remote);
        final branch = access.user.role.name == 'branchManager'
            ? 'br-01'
            : null;
        final first = await repo.getReturnsPage(
          access: access,
          activeBranchId: branch,
          limit: 100,
        );
        expect(first.items, hasLength(100));
        expect(first.total, 201);
        expect(first.hasMore, isTrue);
        final last = await repo.getReturnsPage(
          access: access,
          activeBranchId: branch,
          offset: 200,
          limit: 100,
        );
        expect(last.items.single.id, 'ret-200');
        expect(last.hasMore, isFalse);
        expect(remote.calls, hasLength(2));
      },
    );
  }

  _contract(
    'mock',
    () => MockReturnsRepository(
      dataSource: MockReturnsDataSource(now: fixedNow),
      now: fixedNow,
      delay: Duration.zero,
    ),
  );

  _contract(
    'SQL Connect (fake remote)',
    () => SqlConnectReturnsRepository(
      remote: FakeReturnsRemote(MockReturnsDataSource(now: fixedNow).returns),
      now: fixedNow,
    ),
  );

  group('SqlConnectReturnsRepository query selection', () {
    late FakeReturnsRemote remote;
    late SqlConnectReturnsRepository repo;
    setUp(() {
      remote = FakeReturnsRemote(MockReturnsDataSource(now: fixedNow).returns);
      repo = SqlConnectReturnsRepository(remote: remote, now: fixedNow);
    });

    test('employee uses ListMyReturns only', () async {
      await repo.getReturnsPage(access: employeeAccess());
      expect(remote.calls, ['listMine']);
    });

    test('manager reads exactly the active branch', () async {
      await repo.getReturnsPage(
        access: branchManagerAccess(),
        activeBranchId: 'br-01',
      );
      expect(remote.calls, ['listByBranch:br-01']);
    });

    test('org admin reads the organization with one query', () async {
      final items = (await repo.getReturnsPage(access: orgAdminAccess())).items;
      expect(remote.calls, ['listByOrganization:*']);
      expect(items.map((r) => r.branchId).toSet().length, greaterThan(1));
    });

    test('org admin narrowed to a branch passes the branch filter', () async {
      await repo.getReturnsPage(
        access: orgAdminAccess(),
        activeBranchId: 'br-02',
      );
      expect(remote.calls, ['listByOrganization:br-02']);
    });

    test('submit sends the real fields and omits a missing bill', () async {
      await repo.submitReturn(
        access: employeeAccess(),
        input: const CreateReturnInput(
          productTitle: 'Eggs',
          reason: ReturnReason.expired,
          quantity: 12,
          unit: 'pcs',
          invoiceNumber: 'INV-9',
          remarks: ' cracked ',
        ),
      );
      final sent = remote.lastSubmit!;
      expect(sent.branchId, 'br-01');
      expect(sent.input.items.single.productTitle, 'Eggs');
      expect(sent.input.items.single.quantity, 12);
      expect(sent.input.items.single.unit, 'pcs');
      expect(sent.input.billImageUrl, isNull);
    });

    test('a multi-line bill is submitted in one call', () async {
      final created = await repo.submitReturnBatch(
        access: employeeAccess(),
        input: CreateReturnBatchInput(
          billNumber: 'BILL-42',
          invoiceNumber: 'INV-42',
          returnDate: DateTime(2026, 11, 20),
          remarks: 'Counter 2',
          items: const [
            ReturnLineItemInput(
              productTitle: 'Eggs',
              quantity: 12,
              reason: ReturnReason.expired,
            ),
            ReturnLineItemInput(
              productTitle: 'Milk',
              quantity: 2,
              reason: ReturnReason.damaged,
              remarks: 'Leaking',
            ),
          ],
        ),
      );
      expect(remote.calls, ['submitBatch']);
      expect(remote.lastSubmit!.input.billNumber, 'BILL-42');
      expect(remote.lastSubmit!.input.returnDate, DateTime(2026, 11, 20));
      expect(created.map((r) => r.productTitle), ['Eggs', 'Milk']);
      expect(created.map((r) => r.id).toSet().length, 2);
      expect(created.last.remarks, 'Counter 2 - Leaking');
      expect(created.first.billNumber, 'BILL-42');
    });

    test('a failed bill submission reports one error and no rows', () async {
      remote.failWith = const NetworkException();
      await expectLater(
        repo.submitReturnBatch(
          access: employeeAccess(),
          input: const CreateReturnBatchInput(
            invoiceNumber: 'INV-42',
            items: [
              ReturnLineItemInput(
                productTitle: 'Eggs',
                quantity: 12,
                reason: ReturnReason.expired,
              ),
              ReturnLineItemInput(
                productTitle: 'Milk',
                quantity: 2,
                reason: ReturnReason.damaged,
              ),
            ],
          ),
        ),
        throwsA(isA<NetworkException>()),
      );
      expect(remote.calls, ['submitBatch']);
    });

    test(
      'review sends only id, decision and notes (no reviewer identity)',
      () async {
        final access = orgAdminAccess();
        final pending = (await repo.getReturnsPage(
          access: access,
          status: ReturnStatus.pending,
        )).items.first;
        await repo.reviewReturn(
          access: access,
          returnItem: pending,
          decision: ReturnStatus.rejected,
          reviewerNotes: 'No receipt',
        );
        expect(remote.lastReview, (
          id: pending.id,
          decision: ReturnStatus.rejected,
          notes: 'No receipt',
        ));
      },
    );

    test('backend failures surface as safe typed errors', () async {
      remote.failWith = StateError('db password=hunter2');
      await expectLater(
        repo.getReturnsPage(access: employeeAccess()),
        throwsA(
          isA<DatabaseException>().having(
            (e) => e.userMessage,
            'userMessage',
            isNot(contains('hunter2')),
          ),
        ),
      );
    });

    test('a failed list never yields fabricated rows', () async {
      remote.failWith = const NetworkException();
      await expectLater(
        repo.getReturnsPage(access: orgAdminAccess()),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('status vocabulary', () {
    test(
      'parses server statuses case-insensitively and rejects unknown ones',
      () {
        expect(ReturnStatus.tryParse('Pending'), ReturnStatus.pending);
        expect(ReturnStatus.tryParse('APPROVED'), ReturnStatus.approved);
        expect(ReturnStatus.tryParse('rejected'), ReturnStatus.rejected);
        expect(ReturnStatus.tryParse('cancelled'), isNull);
        expect(ReturnReason.parse('wrongItem'), ReturnReason.wrongItem);
        expect(ReturnReason.parse('unknown-legacy'), ReturnReason.other);
      },
    );
  });
}
