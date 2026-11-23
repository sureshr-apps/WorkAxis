import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/assets/domain/models/asset_queue.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';
import 'package:workaxis/features/assets/domain/policies/asset_listing_policy.dart';
import 'package:workaxis/features/assets/domain/repositories/assets_repository.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

/// Server-paged asset list for one [AssetQueue], with debounced server-side
/// search, plus the assignable members the asset editor offers.
class AssetsController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  AssetsController({
    required this.repository,
    required this.membersRepository,
    this.searchDebounce = const Duration(milliseconds: 300),
    this.pageSize = defaultPageSize,
  });

  final AssetsRepository repository;
  final OrganizationMembersRepository membersRepository;

  /// Assets requested per page.
  final int pageSize;

  /// Delay applied to [setQuery] so typing does not hit the backend per key.
  final Duration searchDebounce;

  final RequestGeneration _requests = RequestGeneration();
  int _scopeGeneration = 0;

  List<EmployeeAsset> _assets = const [];
  List<OrganizationMember> _members = const [];
  AssetQueue? _queue;
  int _total = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSaving = false;
  bool _isAcknowledging = false;
  String _query = '';
  String? _errorMessage;
  String? _actionErrorMessage;
  Timer? _debounceTimer;
  Completer<void>? _pendingSearch;

  /// Loaded pages of the current queue, in server order.
  List<EmployeeAsset> get assets => _assets;
  List<OrganizationMember> get members => _members;

  /// The queue being listed; null until the first [load].
  AssetQueue? get queue => _queue;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSaving => _isSaving;
  bool get isAcknowledging => _isAcknowledging;

  /// Matching assets on the server (not just the loaded pages).
  int get totalCount => _total;
  bool get hasMore => _assets.length < _total;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  /// Current search text; seed search fields with it so the visible box and
  /// the applied search never drift apart.
  String get query => _query;

  /// Loads assignable members and the first page of assets for a scope.
  ///
  /// Keeps the current queue when [access] may read it (otherwise switches to
  /// the role's default) and the current search unless [query] is given.
  Future<void> load(
    UserAccessContext access, {
    String? activeBranchId,
    String? query,
  }) async {
    // Only reset() changes the scope. A reload in the same scope must not, or
    // an in-flight save would be dropped and leave isSaving stuck at true;
    // _requests already discards superseded loads.
    final scopeGeneration = _scopeGeneration;
    _cancelPendingSearch();
    if (query != null) _query = query;
    final allowed = AssetQueue.allowedFor(access.user.role);
    if (!allowed.contains(_queue)) {
      _queue = AssetQueue.defaultFor(access.user.role);
    }
    final request = _requests.next();
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final page = await _fetchPage(access, activeBranchId, offset: 0);
      final members = access.user.role == UserRole.employee
          ? const <OrganizationMember>[]
          : await membersRepository.getMembers(
              access: access,
              activeBranchId: activeBranchId,
              maxItems: 500,
            );
      if (!_isCurrent(request, scopeGeneration)) return;
      _assets = List.unmodifiable(page.items);
      _total = page.total;
      _members = members
          .where(
            (member) =>
                member.role == UserRole.employee ||
                (access.user.role == UserRole.orgAdmin &&
                    member.role == UserRole.branchManager),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      if (!_isCurrent(request, scopeGeneration)) return;
      _assets = const [];
      _total = 0;
      _errorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'Assets could not be loaded. Please try again.',
      );
    } finally {
      if (_isCurrent(request, scopeGeneration)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Switches the listed queue and reloads its first page.
  Future<void> setQueue(
    UserAccessContext access,
    AssetQueue queue, {
    String? activeBranchId,
  }) {
    if (queue == _queue) return Future.value();
    if (!AssetQueue.allowedFor(access.user.role).contains(queue)) {
      return Future.value();
    }
    _cancelPendingSearch();
    _queue = queue;
    // The previous queue's rows must not show under the new selection.
    _assets = const [];
    _total = 0;
    return _reloadFirstPage(access, activeBranchId);
  }

  /// Updates the search text and reloads page one after [searchDebounce] of
  /// inactivity. The returned future completes when the (possibly coalesced)
  /// load finishes.
  Future<void> setQuery(
    UserAccessContext access,
    String query, {
    String? activeBranchId,
  }) {
    _query = query;
    _cancelPendingSearch();
    notifyListeners();

    if (searchDebounce == Duration.zero) {
      return _reloadFirstPage(access, activeBranchId);
    }
    final completer = Completer<void>();
    _pendingSearch = completer;
    _debounceTimer = Timer(searchDebounce, () async {
      try {
        await _reloadFirstPage(access, activeBranchId);
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    });
    return completer.future;
  }

  /// Appends the next page when more assets exist.
  Future<void> loadMore(
    UserAccessContext access, {
    String? activeBranchId,
  }) async {
    if (_isLoading || _isLoadingMore || !hasMore) return;
    final scopeGeneration = _scopeGeneration;
    final request = _requests.next();
    _isLoadingMore = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final page = await _fetchPage(
        access,
        activeBranchId,
        offset: _assets.length,
      );
      if (!_isCurrent(request, scopeGeneration)) return;
      final loadedIds = {for (final asset in _assets) asset.id};
      _assets = List.unmodifiable([
        ..._assets,
        ...page.items.where((asset) => !loadedIds.contains(asset.id)),
      ]);
      _total = page.total;
    } catch (error, stackTrace) {
      if (!_isCurrent(request, scopeGeneration)) return;
      _actionErrorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'More assets could not be loaded. Please try again.',
      );
    } finally {
      if (_isCurrent(request, scopeGeneration)) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<bool> saveAsset(
    UserAccessContext access,
    EmployeeAsset asset, {
    String? activeBranchId,
  }) async {
    final scopeGeneration = _scopeGeneration;
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final saved = await repository.saveAsset(
        access: access,
        asset: asset,
        activeBranchId: activeBranchId,
      );
      if (scopeGeneration != _scopeGeneration) return false;
      _placeSaved(saved, access, activeBranchId);
      return true;
    } catch (error, stackTrace) {
      if (scopeGeneration != _scopeGeneration) return false;
      _actionErrorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'The asset could not be saved. Please try again.',
      );
      return false;
    } finally {
      if (scopeGeneration == _scopeGeneration) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<bool> deleteAsset(
    UserAccessContext access,
    EmployeeAsset asset, {
    String? activeBranchId,
  }) async {
    final scopeGeneration = _scopeGeneration;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      await repository.deleteAsset(
        access: access,
        assetId: asset.id,
        activeBranchId: activeBranchId,
      );
      if (scopeGeneration != _scopeGeneration) return false;
      final remaining = _assets.where((item) => item.id != asset.id).toList();
      if (remaining.length != _assets.length && _total > 0) _total -= 1;
      _assets = List.unmodifiable(remaining);
      return true;
    } catch (error, stackTrace) {
      if (scopeGeneration != _scopeGeneration) return false;
      _actionErrorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'The asset could not be deleted. Please try again.',
      );
      return false;
    } finally {
      if (scopeGeneration == _scopeGeneration) notifyListeners();
    }
  }

  Future<bool> acknowledgeAsset(
    UserAccessContext access,
    EmployeeAsset asset,
  ) async {
    final scopeGeneration = _scopeGeneration;
    _isAcknowledging = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final acknowledged = await repository.acknowledgeAsset(
        access: access,
        assetId: asset.id,
      );
      if (scopeGeneration != _scopeGeneration) return false;
      _assets = List.unmodifiable([
        for (final current in _assets)
          current.id == asset.id ? acknowledged : current,
      ]);
      return true;
    } catch (error, stackTrace) {
      if (scopeGeneration != _scopeGeneration) return false;
      _actionErrorMessage = userMessageFor(
        error,
        stackTrace,
        fallback:
            'The asset receipt could not be acknowledged. Please try again.',
      );
      return false;
    } finally {
      if (scopeGeneration == _scopeGeneration) {
        _isAcknowledging = false;
        notifyListeners();
      }
    }
  }

  void clearActionError() {
    _actionErrorMessage = null;
    notifyListeners();
  }

  @override
  void reset() {
    _scopeGeneration++;
    _cancelPendingSearch();
    _requests.invalidate();
    _assets = const [];
    _members = const [];
    _queue = null;
    _total = 0;
    _isLoading = false;
    _isLoadingMore = false;
    _isSaving = false;
    _isAcknowledging = false;
    _query = '';
    _errorMessage = null;
    _actionErrorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelPendingSearch();
    super.dispose();
  }

  /// Drops a debounced search that has not fired yet, releasing its waiter.
  void _cancelPendingSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    final pending = _pendingSearch;
    _pendingSearch = null;
    if (pending != null && !pending.isCompleted) pending.complete();
  }

  bool _isCurrent(int request, int scopeGeneration) =>
      _requests.isCurrent(request) &&
      scopeGeneration == _scopeGeneration &&
      !isDisposed;

  Future<PageResult<EmployeeAsset>> _fetchPage(
    UserAccessContext access,
    String? activeBranchId, {
    required int offset,
  }) {
    final queue = _queue;
    if (queue == null) return Future.value(const PageResult.empty());
    return repository.getAssetsPage(
      access: access,
      queue: queue,
      activeBranchId: activeBranchId,
      query: _query,
      offset: offset,
      limit: pageSize,
    );
  }

  /// Reloads page one of the current queue and search, keeping the members.
  Future<void> _reloadFirstPage(
    UserAccessContext access,
    String? activeBranchId,
  ) async {
    final scopeGeneration = _scopeGeneration;
    final request = _requests.next();
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    notifyListeners();
    try {
      final page = await _fetchPage(access, activeBranchId, offset: 0);
      if (!_isCurrent(request, scopeGeneration)) return;
      _assets = List.unmodifiable(page.items);
      _total = page.total;
    } catch (error, stackTrace) {
      if (!_isCurrent(request, scopeGeneration)) return;
      _assets = const [];
      _total = 0;
      _errorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'Assets could not be loaded. Please try again.',
      );
    } finally {
      if (_isCurrent(request, scopeGeneration)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Puts a saved asset where a reload would: in sort order when it belongs
  /// to the current queue and search, and out of the list otherwise. A row
  /// sorting past the loaded pages is left for [loadMore] to fetch, so the
  /// next page offset stays aligned with the server.
  void _placeSaved(
    EmployeeAsset saved,
    UserAccessContext access,
    String? activeBranchId,
  ) {
    final wasLoaded = _assets.any((asset) => asset.id == saved.id);
    final rest = _assets.where((asset) => asset.id != saved.id).toList();
    final queue = _queue;
    final belongs =
        queue != null &&
        AssetListingPolicy.belongsToQueue(
          saved,
          queue,
          access,
          activeBranchId: activeBranchId,
        ) &&
        AssetListingPolicy.matchesQuery(saved, _query);

    if (!belongs) {
      if (wasLoaded && _total > 0) _total -= 1;
      _assets = List.unmodifiable(rest);
      return;
    }
    if (!wasLoaded) _total += 1;
    final index = rest.indexWhere(
      (asset) => AssetListingPolicy.compare(saved, asset) < 0,
    );
    if (index != -1) {
      rest.insert(index, saved);
    } else if (rest.length + 1 >= _total) {
      // Every matching row is loaded, so the saved one goes last.
      rest.add(saved);
    }
    _assets = List.unmodifiable(rest);
  }
}
