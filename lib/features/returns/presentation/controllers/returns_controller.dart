import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/models/return_status_counts.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';

/// Paged returns list for the returns screens.
///
/// The list holds the pages loaded so far for the current queue, status
/// filter and search text (all applied on the server). KPI and filter-chip
/// totals come from the server and cover every page.
class ReturnsController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  ReturnsController({
    required this.repository,
    this.pageSize = defaultPageSize,
    this.searchDebounce = const Duration(milliseconds: 300),
  });

  final ReturnsRepository repository;

  /// Returns requested per page.
  final int pageSize;

  /// Delay applied to [setSearchQuery] so typing does not query per key.
  final Duration searchDebounce;

  /// Guards list loads (page one and "load more"); a newer load wins.
  final RequestGeneration _requests = RequestGeneration();

  /// Guards count loads separately so a page load does not discard them.
  final RequestGeneration _countRequests = RequestGeneration();
  int _epoch = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _actionErrorMessage;

  /// Always replaced, never mutated: repositories may hand back const lists.
  List<ReturnItem> _items = const [];
  int _total = 0;
  ReturnStatusCounts _scopeCounts = ReturnStatusCounts.empty;
  ReturnStatusCounts _queueCounts = ReturnStatusCounts.empty;
  ReturnStatus? _statusFilter;
  ReturnQueue _queue = ReturnQueue.mine;
  String _searchQuery = '';
  Timer? _searchTimer;

  UserAccessContext? _access;
  String? _activeBranchId;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSaving => _isSaving;

  /// Failure from the last load; replaces the list with an error state.
  String? get errorMessage => _errorMessage;

  /// Failure from the last submit/update/review or "load more"; shown inline
  /// without discarding the loaded list.
  String? get actionErrorMessage => _actionErrorMessage;

  /// Loaded pages matching the queue, status filter and search text.
  List<ReturnItem> get items => _items;

  /// Rows on the server matching the current filters (not just loaded ones).
  int get matchingCount => _total;
  bool get hasMore => _items.length < _total;

  ReturnStatus? get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;

  /// A Branch Manager's queue: their own returns or everyone else's.
  ReturnQueue get queue => _queue;

  /// Totals for the whole scope (KPI tiles). For a Branch Manager this is the
  /// whole active branch, regardless of the selected queue.
  ReturnStatusCounts get scopeCounts => _scopeCounts;

  /// Totals for the selected queue (filter chips).
  ReturnStatusCounts get queueCounts => _queueCounts;

  int get pendingCount => _scopeCounts.pending;
  int get approvedCount => _scopeCounts.approved;
  int get rejectedCount => _scopeCounts.rejected;
  int get totalCount => _scopeCounts.total;

  bool get _usesQueue => _access?.user.role == UserRole.branchManager;
  ReturnQueue? get _queueParam => _usesQueue ? _queue : null;

  /// Loads page one and the counts for [access] and [activeBranchId].
  Future<void> loadReturns({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    _access = access;
    _activeBranchId = activeBranchId;
    await Future.wait([_loadFirstPage(), _loadCounts()]);
  }

  /// Appends the next page when more returns match.
  Future<void> loadMore() async {
    final access = _access;
    if (access == null || _isLoading || _isLoadingMore || !hasMore) return;
    final token = _requests.next();
    _isLoadingMore = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final page = await _fetchPage(access, offset: _items.length);
      if (!_requests.isCurrent(token)) return;
      _items = List.unmodifiable([..._items, ...page.items]);
      _total = page.total;
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load more returns. Try again.',
      );
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Narrows the list to [filter] (null: every status) and reloads page one.
  void setFilter(ReturnStatus? filter) {
    if (_statusFilter == filter) return;
    _statusFilter = filter;
    notifyListeners();
    unawaited(_loadFirstPage());
  }

  /// Searches on the server after [searchDebounce] of no typing.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _searchTimer?.cancel();
    // Before the first load there is nothing to refresh; it uses the query.
    if (_access != null) {
      _searchTimer = Timer(searchDebounce, () => unawaited(_loadFirstPage()));
    }
    notifyListeners();
  }

  /// Switches a Branch Manager between their own returns and others'.
  void setQueue(ReturnQueue queue) {
    if (_queue == queue) return;
    _queue = queue;
    _queueCounts = ReturnStatusCounts.empty;
    notifyListeners();
    unawaited(Future.wait([_loadFirstPage(), _loadCounts(scope: false)]));
  }

  /// A loaded return, if it is in the current pages.
  ReturnItem? loadedReturn(String returnId) =>
      _items.where((i) => i.id == returnId).firstOrNull;

  /// [returnId] from the loaded pages, else read from the server (deep links
  /// and items beyond the loaded pages). Null when not visible to [access].
  Future<ReturnItem?> findReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required String returnId,
  }) async {
    final loaded = loadedReturn(returnId);
    if (loaded != null) return loaded;
    try {
      return await repository.getReturn(
        access: access,
        activeBranchId: activeBranchId,
        returnId: returnId,
      );
    } catch (e, st) {
      if (isDisposed) return null;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Failed to load the return request. Please try again.',
      );
      notifyListeners();
      return null;
    }
  }

  Future<bool> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  }) {
    return submitReturnBatch(
      access: access,
      branchId: branchId,
      input: input.toBatch(),
    );
  }

  Future<bool> submitReturnBatch({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnBatchInput input,
  }) async {
    final epoch = _epoch;
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final createdList = await repository.submitReturnBatch(
        access: access,
        branchId: branchId,
        input: input,
      );
      if (epoch != _epoch || isDisposed) return false;
      _addSubmitted(createdList);
      return true;
    } catch (e, st) {
      if (epoch != _epoch || isDisposed) return false;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Failed to submit return request.',
      );
      return false;
    } finally {
      if (epoch == _epoch && !isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<bool> updateReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required ReturnItem item,
    required CreateReturnInput input,
  }) async {
    final epoch = _epoch;
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      await repository.updateReturn(
        access: access,
        activeBranchId: activeBranchId,
        returnItem: item,
        input: input,
      );
      if (epoch != _epoch || isDisposed) return false;
      return true;
    } catch (e, st) {
      if (epoch != _epoch || isDisposed) return false;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Failed to update return request.',
      );
      return false;
    } finally {
      if (epoch == _epoch && !isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<bool> reviewReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required ReturnItem item,
    required ReturnStatus decision,
    String? reviewerNotes,
  }) async {
    final epoch = _epoch;
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.reviewReturn(
        access: access,
        activeBranchId: activeBranchId,
        returnItem: item,
        decision: decision,
        reviewerNotes: reviewerNotes,
      );
      if (epoch != _epoch || isDisposed) return false;
      _applyReview(item, updated);
      return true;
    } catch (e, st) {
      if (epoch != _epoch || isDisposed) return false;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Failed to update return decision.',
      );
      return false;
    } finally {
      if (epoch == _epoch && !isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  void clearActionError() {
    if (_actionErrorMessage != null) {
      _actionErrorMessage = null;
      notifyListeners();
    }
  }

  @override
  void reset() {
    _epoch++;
    _requests.invalidate();
    _countRequests.invalidate();
    _searchTimer?.cancel();
    _isLoading = false;
    _isLoadingMore = false;
    _isSaving = false;
    _errorMessage = null;
    _actionErrorMessage = null;
    _items = const [];
    _total = 0;
    _scopeCounts = ReturnStatusCounts.empty;
    _queueCounts = ReturnStatusCounts.empty;
    _statusFilter = null;
    _queue = ReturnQueue.mine;
    _searchQuery = '';
    _access = null;
    _activeBranchId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    final access = _access;
    if (access == null) return;
    final token = _requests.next();
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    notifyListeners();
    try {
      final page = await _fetchPage(access, offset: 0);
      if (!_requests.isCurrent(token)) return;
      _items = List.unmodifiable(page.items);
      _total = page.total;
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Failed to load return requests. Please try again.',
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<PageResult<ReturnItem>> _fetchPage(
    UserAccessContext access, {
    required int offset,
  }) => repository.getReturnsPage(
    access: access,
    activeBranchId: _activeBranchId,
    queue: _queueParam,
    status: _statusFilter,
    query: _searchQuery,
    offset: offset,
    limit: pageSize,
  );

  /// Loads the queue totals and, unless [scope] is false, the scope totals.
  /// A count failure leaves the previous totals; the list reports errors.
  Future<void> _loadCounts({bool scope = true}) async {
    final access = _access;
    if (access == null) return;
    final token = _countRequests.next();
    try {
      final queueCounts = repository.getReturnCounts(
        access: access,
        activeBranchId: _activeBranchId,
        queue: _queueParam,
      );
      final scopeCounts = !scope
          ? null
          : _usesQueue
          ? repository.getReturnCounts(
              access: access,
              activeBranchId: _activeBranchId,
            )
          : queueCounts;
      final queueResult = await queueCounts;
      final scopeResult = await scopeCounts;
      if (!_countRequests.isCurrent(token)) return;
      _queueCounts = queueResult;
      if (scopeResult != null) _scopeCounts = scopeResult;
      notifyListeners();
    } catch (e, st) {
      if (!_countRequests.isCurrent(token)) return;
      // Counts are secondary to the list; keep the last known totals.
      developer.log(
        'Return totals could not be loaded.',
        name: 'workaxis.returns',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _addSubmitted(List<ReturnItem> created) {
    if (created.isEmpty) return;
    for (final _ in created) {
      _scopeCounts = _scopeCounts.moved(to: ReturnStatus.pending);
      if (!_usesQueue || _queue == ReturnQueue.mine) {
        _queueCounts = _queueCounts.moved(to: ReturnStatus.pending);
      }
    }
    final visible =
        (!_usesQueue || _queue == ReturnQueue.mine) &&
        (_statusFilter == null || _statusFilter == ReturnStatus.pending) &&
        _searchQuery.trim().isEmpty;
    if (!visible) return;
    _items = List.unmodifiable([...created, ..._items]);
    _total += created.length;
  }

  void _applyReview(ReturnItem before, ReturnItem after) {
    if (before.status != after.status) {
      _scopeCounts = _scopeCounts.moved(from: before.status, to: after.status);
      if (_items.any((i) => i.id == before.id)) {
        _queueCounts = _queueCounts.moved(
          from: before.status,
          to: after.status,
        );
      }
    }
    final stillMatches = _statusFilter == null || _statusFilter == after.status;
    if (stillMatches) {
      _items = List.unmodifiable([
        for (final i in _items) i.id == before.id ? after : i,
      ]);
      return;
    }
    final remaining = [
      for (final i in _items)
        if (i.id != before.id) i,
    ];
    if (remaining.length != _items.length) _total -= 1;
    _items = List.unmodifiable(remaining);
  }
}
