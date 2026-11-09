import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/returns/data/mock_returns_data_source.dart';
import 'package:workaxis/features/returns/data/mock_returns_repository.dart';
import 'package:workaxis/features/returns/data/returns_remote.dart';
import 'package:workaxis/features/returns/data/sql_connect_returns_repository.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
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
  ({String branchId, CreateReturnInput input})? lastSubmit;
  ({String id, ReturnStatus decision, String? notes})? lastReview;

  void _maybeFail() {
    final error = failWith;
    if (error != null) throw error;
  }

  @override
  Future<List<ReturnItem>> listMine({
    required String organizationId,
    required String employeeUid,
    required int limit,
    int offset = 0,
    ReturnStatus? status,
  }) async {
    calls.add('listMine');
    _maybeFail();
    return rows
        .where((r) => r.employeeId == employeeUid)
        .where((r) => status == null || r.status == status)
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<List<ReturnItem>> listByBranch({
    required String organizationId,
    required BranchSummary branch,
    required int limit,
    int offset = 0,
    ReturnStatus? status,
  }) async {
    calls.add('listByBranch:${branch.id}');
    _maybeFail();
    return rows
        .where((r) => r.branchId == branch.id)
        .where((r) => status == null || r.status == status)
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<List<ReturnItem>> listByOrganization({
    required String organizationId,
    required int limit,
    int offset = 0,
    String? branchId,
    ReturnStatus? status,
  }) async {
    calls.add('listByOrganization:${branchId ?? '*'}');
    _maybeFail();
    return rows
        .where((r) => r.organizationId == organizationId)
        .where((r) => branchId == null || r.branchId == branchId)
        .where((r) => status == null || r.status == status)
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<String> submit({
    required String branchId,
    required CreateReturnInput input,
  }) async {
    calls.add('submit');
    _maybeFail();
    lastSubmit = (branchId: branchId, input: input);
    return 'RET-FAKE-${rows.length + 1}';
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

/// Behaviour every [ReturnsRepository] must have, whatever the backend.
void _contract(String name, ReturnsRepository Function() create) {
  group('ReturnsRepository contract: $name', () {
    late ReturnsRepository repo;
    setUp(() => repo = create());

    test('employee sees only their own returns', () async {
      final items = await repo.getReturns(access: employeeAccess());
      expect(items, isNotEmpty);
      expect(items.every((r) => r.employeeId == 'user-emp-01'), isTrue);
    });

    test('branch manager sees only the active branch', () async {
      final items = await repo.getReturns(
        access: branchManagerAccess(),
        activeBranchId: 'br-01',
      );
      expect(items, isNotEmpty);
      expect(items.every((r) => r.branchId == 'br-01'), isTrue);
    });

    test('branch manager cannot read a branch outside the assigned set', () {
      expect(
        () => repo.getReturns(
          access: branchManagerAccess(branchIds: ['br-01']),
          activeBranchId: 'br-02',
        ),
        throwsA(isA<BranchAuthorizationException>()),
      );
    });

    test('branch manager needs an active branch', () {
      expect(
        () =>
            repo.getReturns(access: branchManagerAccess(activeBranchId: null)),
        throwsA(isA<BranchAuthorizationException>()),
      );
    });

    test('org admin sees the organization across branches', () async {
      final items = await repo.getReturns(access: orgAdminAccess());
      expect(items.map((r) => r.branchId).toSet(), {'br-01', 'br-02', 'br-04'});
      expect(items.every((r) => r.organizationId == 'org-acme'), isTrue);
    });

    test('org admin of another organization sees none of them', () async {
      final items = await repo.getReturns(
        access: orgAdminAccess(org: otherOrg, branchIds: const []),
      );
      expect(items, isEmpty);
    });

    test('status filter narrows the result', () async {
      final items = await repo.getReturns(
        access: orgAdminAccess(),
        statusFilter: ReturnStatus.pending,
      );
      expect(items, isNotEmpty);
      expect(items.every((r) => r.status == ReturnStatus.pending), isTrue);
    });

    test('platform users have no returns scope', () {
      expect(
        () => repo.getReturns(access: platformAccess()),
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
        final pending = (await repo.getReturns(
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
      final other = (await repo.getReturns(access: orgAdminAccess()))
          .firstWhere((r) => r.branchId != 'br-01');

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
      final item = (await repo.getReturns(access: employeeAccess())).first;
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
      final item = (await repo.getReturns(
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
      final done = (await repo.getReturns(
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
    test('all 201 returns are read for ${access.user.role.name}', () async {
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
      final rows = await repo.getReturns(
        access: access,
        activeBranchId: access.user.role.name == 'branchManager'
            ? 'br-01'
            : null,
      );
      expect(rows, hasLength(201));
      expect(rows.map((r) => r.id).toSet(), hasLength(201));
      expect(remote.calls, hasLength(3));
    });
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
      await repo.getReturns(access: employeeAccess());
      expect(remote.calls, ['listMine']);
    });

    test('manager reads exactly the active branch', () async {
      await repo.getReturns(
        access: branchManagerAccess(),
        activeBranchId: 'br-01',
      );
      expect(remote.calls, ['listByBranch:br-01']);
    });

    test('org admin reads the organization with one query', () async {
      final items = await repo.getReturns(access: orgAdminAccess());
      expect(remote.calls, ['listByOrganization:*']);
      expect(items.map((r) => r.branchId).toSet().length, greaterThan(1));
    });

    test('org admin narrowed to a branch passes the branch filter', () async {
      await repo.getReturns(access: orgAdminAccess(), activeBranchId: 'br-02');
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
      expect(sent.input.productTitle, 'Eggs');
      expect(sent.input.quantity, 12);
      expect(sent.input.unit, 'pcs');
      expect(sent.input.billImageUrl, isNull);
    });

    test(
      'review sends only id, decision and notes (no reviewer identity)',
      () async {
        final access = orgAdminAccess();
        final pending = (await repo.getReturns(
          access: access,
          statusFilter: ReturnStatus.pending,
        )).first;
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
        repo.getReturns(access: employeeAccess()),
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
        repo.getReturns(access: orgAdminAccess()),
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
