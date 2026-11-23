import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/assets/domain/models/asset_queue.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';
import 'package:workaxis/features/assets/domain/repositories/assets_repository.dart';
import 'package:workaxis/features/assets/presentation/controllers/assets_controller.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

import '../../helpers/access_fixtures.dart';

EmployeeAsset _asset(
  String id, {
  String holder = 'Holder',
  String holderId = 'user-emp-01',
  String? holderUid,
  String branchId = 'br-01',
}) => EmployeeAsset(
  id: id,
  organizationId: 'org-acme',
  branchId: branchId,
  branchName: 'Downtown Flagship',
  employeeId: holderId,
  employeeUid: holderUid,
  employeeName: holder,
  name: 'Asset $id',
  category: 'Device',
  assetTag: 'TAG-$id',
  status: AssetStatus.assigned,
);

typedef _PageRequest = ({
  AssetQueue queue,
  String? query,
  int offset,
  int limit,
});

/// Records page requests; answers from [rows] unless a test holds the
/// request with [hold].
class _PagedAssetsRepository implements AssetsRepository {
  _PagedAssetsRepository([this.rows = const []]);

  List<EmployeeAsset> rows;
  final List<_PageRequest> requests = [];
  final List<Completer<PageResult<EmployeeAsset>>> _held = [];
  bool hold = false;
  EmployeeAsset? saveResult;

  Completer<PageResult<EmployeeAsset>> held(int index) => _held[index];

  @override
  Future<PageResult<EmployeeAsset>> getAssetsPage({
    required UserAccessContext access,
    required AssetQueue queue,
    String? activeBranchId,
    String? query,
    int offset = 0,
    int limit = defaultPageSize,
  }) {
    requests.add((queue: queue, query: query, offset: offset, limit: limit));
    if (hold) {
      final completer = Completer<PageResult<EmployeeAsset>>();
      _held.add(completer);
      return completer.future;
    }
    return Future.value(
      PageResult(
        items: rows.skip(offset).take(limit).toList(),
        total: rows.length,
        offset: offset,
      ),
    );
  }

  @override
  Future<EmployeeAsset> saveAsset({
    required UserAccessContext access,
    required EmployeeAsset asset,
    String? activeBranchId,
  }) async => saveResult ?? asset;

  @override
  Future<void> deleteAsset({
    required UserAccessContext access,
    required String assetId,
    String? activeBranchId,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoMembers implements OrganizationMembersRepository {
  @override
  Future<PageResult<OrganizationMember>> getMembersPage({
    required UserAccessContext access,
    String? activeBranchId,
    String? query,
    AccountStatus? status,
    UserRole? role,
    int offset = 0,
    int limit = defaultPageSize,
  }) async => const PageResult.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PageResult<EmployeeAsset> _page(List<EmployeeAsset> items, {int? total}) =>
    PageResult(items: items, total: total ?? items.length, offset: 0);

void main() {
  late _PagedAssetsRepository repository;
  late AssetsController controller;

  AssetsController build({
    Duration debounce = Duration.zero,
    int pageSize = 2,
  }) => AssetsController(
    repository: repository,
    membersRepository: _NoMembers(),
    searchDebounce: debounce,
    pageSize: pageSize,
  );

  tearDown(() => controller.dispose());

  test('loads page by page and stops at the server total', () async {
    repository = _PagedAssetsRepository([
      for (var i = 1; i <= 5; i++) _asset('a$i'),
    ]);
    controller = build();
    final access = orgAdminAccess();

    await controller.load(access);
    expect(controller.queue, AssetQueue.organization);
    expect(controller.assets.map((a) => a.id), ['a1', 'a2']);
    expect(controller.totalCount, 5);
    expect(controller.hasMore, isTrue);

    await controller.loadMore(access);
    await controller.loadMore(access);
    expect(controller.assets.map((a) => a.id), ['a1', 'a2', 'a3', 'a4', 'a5']);
    expect(controller.hasMore, isFalse);
    expect(controller.isLoadingMore, isFalse);

    await controller.loadMore(access);
    expect(repository.requests.map((r) => r.offset), [0, 2, 4]);
    expect(repository.requests.map((r) => r.limit).toSet(), {2});
  });

  test('search is debounced and sent to the server from page one', () async {
    repository = _PagedAssetsRepository([
      for (var i = 1; i <= 3; i++) _asset('a$i'),
    ]);
    controller = build(debounce: const Duration(milliseconds: 40));
    final access = orgAdminAccess();
    await controller.load(access);
    await controller.loadMore(access);
    repository.requests.clear();

    final first = controller.setQuery(access, 'l');
    final second = controller.setQuery(access, 'la');
    final last = controller.setQuery(access, 'lap');
    expect(controller.query, 'lap');
    expect(repository.requests, isEmpty, reason: 'still debouncing');

    await Future.wait([first, second, last]);
    expect(repository.requests, [
      (queue: AssetQueue.organization, query: 'lap', offset: 0, limit: 2),
    ]);
  });

  test('a Branch Manager opens on their own assets', () async {
    repository = _PagedAssetsRepository();
    controller = build();
    await controller.load(branchManagerAccess(), activeBranchId: 'br-01');
    expect(controller.queue, AssetQueue.mine);
    expect(repository.requests.single.queue, AssetQueue.mine);
  });

  test('switching queue reloads page one and drops stale responses', () async {
    repository = _PagedAssetsRepository([_asset('own', holder: 'Me')]);
    controller = build();
    final access = branchManagerAccess();
    await controller.load(access, activeBranchId: 'br-01');
    expect(controller.assets.map((a) => a.id), ['own']);

    repository.hold = true;
    final toEmployees = controller.setQueue(
      access,
      AssetQueue.branchEmployees,
      activeBranchId: 'br-01',
    );
    expect(controller.assets, isEmpty, reason: 'old queue rows are cleared');
    expect(controller.isLoading, isTrue);
    final backToMine = controller.setQueue(
      access,
      AssetQueue.mine,
      activeBranchId: 'br-01',
    );

    // The newer request answers first; the older one must not overwrite it.
    repository.held(1).complete(_page([_asset('mine-2')]));
    await backToMine;
    repository.held(0).complete(_page([_asset('team-1'), _asset('team-2')]));
    await toEmployees;

    expect(controller.queue, AssetQueue.mine);
    expect(controller.assets.map((a) => a.id), ['mine-2']);
    expect(controller.totalCount, 1);
    expect(controller.isLoading, isFalse);
    final switched = repository.requests.skip(1).toList();
    expect(switched.map((r) => r.queue), [
      AssetQueue.branchEmployees,
      AssetQueue.mine,
    ]);
    expect(switched.map((r) => r.offset), [0, 0]);
  });

  test('a stale search response is dropped', () async {
    repository = _PagedAssetsRepository([_asset('a1')]);
    controller = build();
    final access = orgAdminAccess();
    await controller.load(access);

    repository.hold = true;
    final older = controller.setQuery(access, 'old');
    final newer = controller.setQuery(access, 'new');
    repository.held(1).complete(_page([_asset('new-hit')]));
    await newer;
    repository.held(0).complete(_page([_asset('old-hit')]));
    await older;

    expect(controller.assets.map((a) => a.id), ['new-hit']);
  });

  test('a queue the role may not read is ignored', () async {
    repository = _PagedAssetsRepository();
    controller = build();
    final access = orgAdminAccess();
    await controller.load(access);
    await controller.setQueue(access, AssetQueue.mine);
    expect(controller.queue, AssetQueue.organization);
    expect(repository.requests, hasLength(1));
  });

  group('in-place updates', () {
    test('a saved team asset is added only to the employee queue', () async {
      final access = branchManagerAccess();
      final teamAsset = _asset('new', holder: 'Bea', holderId: 'user-emp-02');
      repository = _PagedAssetsRepository([
        _asset('own', holder: 'Me', holderId: 'user-bm-01'),
      ])..saveResult = teamAsset;
      controller = build();
      await controller.load(access, activeBranchId: 'br-01');

      expect(
        await controller.saveAsset(access, teamAsset, activeBranchId: 'br-01'),
        isTrue,
      );
      expect(controller.assets.map((a) => a.id), ['own']);
      expect(controller.totalCount, 1);

      repository.rows = [_asset('t1', holder: 'Abe', holderId: 'user-emp-03')];
      await controller.setQueue(
        access,
        AssetQueue.branchEmployees,
        activeBranchId: 'br-01',
      );
      await controller.saveAsset(access, teamAsset, activeBranchId: 'br-01');
      expect(controller.assets.map((a) => a.id), ['t1', 'new']);
      expect(controller.totalCount, 2);
    });

    test(
      'a new asset sorting past the loaded pages waits for loadMore',
      () async {
        final access = orgAdminAccess();
        repository = _PagedAssetsRepository([
          _asset('a1', holder: 'Ann'),
          _asset('a2', holder: 'Ben'),
          _asset('a3', holder: 'Cal'),
        ]);
        controller = build();
        await controller.load(access);

        await controller.saveAsset(access, _asset('z', holder: 'Zed'));
        expect(controller.assets.map((a) => a.id), ['a1', 'a2']);
        expect(controller.totalCount, 4);

        await controller.saveAsset(access, _asset('b', holder: 'Bea'));
        expect(controller.assets.map((a) => a.id), ['a1', 'b', 'a2']);
        expect(controller.totalCount, 5);
      },
    );

    test('a saved asset outside the search is not shown', () async {
      final access = orgAdminAccess();
      repository = _PagedAssetsRepository([_asset('a1')])
        ..saveResult = _asset('x', holder: 'Nobody');
      controller = build();
      await controller.load(access);
      await controller.setQuery(access, 'asset a1');
      await controller.saveAsset(access, repository.saveResult!);
      expect(controller.assets.map((a) => a.id), ['a1']);
      expect(controller.totalCount, 1);
    });

    test('deleting removes the row and decrements the total', () async {
      final access = orgAdminAccess();
      repository = _PagedAssetsRepository([
        for (var i = 1; i <= 3; i++) _asset('a$i'),
      ]);
      controller = build();
      await controller.load(access);
      expect(await controller.deleteAsset(access, _asset('a1')), isTrue);
      expect(controller.assets.map((a) => a.id), ['a2']);
      expect(controller.totalCount, 2);
      expect(controller.hasMore, isTrue);
    });
  });

  test('reset clears the list, queue, and search', () async {
    repository = _PagedAssetsRepository([_asset('a1')]);
    controller = build();
    final access = orgAdminAccess();
    await controller.load(access);
    await controller.setQuery(access, 'a1');
    controller.reset();
    expect(controller.assets, isEmpty);
    expect(controller.totalCount, 0);
    expect(controller.queue, isNull);
    expect(controller.query, isEmpty);
  });
}
