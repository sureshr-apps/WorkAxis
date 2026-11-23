import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/leaves/domain/models/leave_queue.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_status_counts.dart';
import 'package:workaxis/features/leaves/domain/models/leave_type_option.dart';
import 'package:workaxis/features/leaves/domain/repositories/leaves_repository.dart';
import 'package:workaxis/features/leaves/domain/services/leave_request_order.dart';
import 'package:workaxis/features/leaves/presentation/controllers/leave_preview_controller.dart';

/// Server-paged leave list for one [LeaveQueue] and optional status filter,
/// plus the server's per-status counts for that queue.
class LeavesController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  LeavesController({required this.repository, this.pageSize = defaultPageSize});

  final LeavesRepository repository;

  /// Requests fetched per page.
  final int pageSize;

  /// Page loads and count loads are guarded separately: a status-filter change
  /// reloads only the page, so it must not discard in-flight counts.
  final RequestGeneration _pageRequests = RequestGeneration();
  final RequestGeneration _countRequests = RequestGeneration();
  int _epoch = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _actionErrorMessage;
  List<LeaveRequest> _items = const [];
  int _total = 0;
  LeaveStatusCounts _counts = LeaveStatusCounts.zero;
  LeaveQueue? _queue;
  LeaveStatus? _statusFilter;
  int _leaveTypeEpoch = 0;
  List<LeaveTypeOption>? _leaveTypes;
  String? _leaveTypesOrganizationId;
  Future<List<LeaveTypeOption>>? _leaveTypesInFlight;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  /// Loaded pages, in server order.
  List<LeaveRequest> get items => _items;

  /// Requests matching the queue and status filter on the server.
  int get totalCount => _total;
  bool get hasMore => _items.length < _total;

  /// Server counts for the whole current queue (ignores the status filter).
  LeaveStatusCounts get counts => _counts;
  int get pendingCount => _counts.pending;

  /// The queue being shown; null until the first load.
  LeaveQueue? get queue => _queue;
  LeaveStatus? get statusFilter => _statusFilter;

  /// Loads the first page and the status counts of the current queue.
  Future<void> loadLeaveRequests({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    final queue = _resolveQueue(access);
    final pageToken = _pageRequests.next();
    final countToken = _countRequests.next();
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    notifyListeners();
    if (queue == null) {
      _items = const [];
      _total = 0;
      _counts = LeaveStatusCounts.zero;
      _errorMessage = 'Leave requests are not available for this account.';
      _isLoading = false;
      notifyListeners();
      return;
    }
    try {
      final results = await Future.wait<Object>([
        _fetchPage(access, activeBranchId, queue, offset: 0),
        repository.getLeaveStatusCounts(
          access: access,
          activeBranchId: activeBranchId,
          queue: queue,
        ),
      ]);
      if (_countRequests.isCurrent(countToken)) {
        _counts = results[1] as LeaveStatusCounts;
      }
      if (!_pageRequests.isCurrent(pageToken)) {
        if (_countRequests.isCurrent(countToken)) notifyListeners();
        return;
      }
      _setFirstPage(results[0] as PageResult<LeaveRequest>);
    } catch (error, stackTrace) {
      if (!_pageRequests.isCurrent(pageToken)) return;
      _errorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'Leave requests could not be loaded. Please try again.',
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Switches queue (Branch Manager: own vs. employee requests) and reloads
  /// the first page and counts. The status filter is kept.
  Future<void> setQueue({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveQueue queue,
  }) {
    _queue = queue;
    return loadLeaveRequests(access: access, activeBranchId: activeBranchId);
  }

  /// Applies a server-side status filter and reloads the first page. Counts
  /// cover the whole queue, so they are not refetched.
  Future<void> setStatusFilter({
    required UserAccessContext access,
    String? activeBranchId,
    LeaveStatus? status,
  }) async {
    _statusFilter = status;
    final queue = _queue;
    // Nothing loaded for this queue yet: load the page and the counts.
    if (queue == null || !queue.isAvailableTo(access.user.role)) {
      return loadLeaveRequests(access: access, activeBranchId: activeBranchId);
    }
    final token = _pageRequests.next();
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    notifyListeners();
    try {
      final page = await _fetchPage(access, activeBranchId, queue, offset: 0);
      if (!_pageRequests.isCurrent(token)) return;
      _setFirstPage(page);
    } catch (error, stackTrace) {
      if (!_pageRequests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'Leave requests could not be loaded. Please try again.',
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Appends the next page when more requests exist.
  Future<void> loadMore({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    final queue = _queue;
    if (queue == null || _isLoading || _isLoadingMore || !hasMore) return;
    final token = _pageRequests.next();
    _isLoadingMore = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final page = await _fetchPage(
        access,
        activeBranchId,
        queue,
        offset: _items.length,
      );
      if (!_pageRequests.isCurrent(token)) return;
      final loaded = {for (final item in _items) item.id};
      _items = List.unmodifiable([
        ..._items,
        ...page.items.where((item) => !loaded.contains(item.id)),
      ]);
      _total = page.total;
    } catch (error, stackTrace) {
      if (!_pageRequests.isCurrent(token)) return;
      _actionErrorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'More leave requests could not be loaded. Please try again.',
      );
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<bool> submitLeaveRequest({
    required UserAccessContext access,
    String? branchId,
    String? activeBranchId,
    required LeaveRequestDraft draft,
  }) => _save(
    () => repository.submitLeaveRequest(
      access: access,
      branchId: branchId,
      activeBranchId: activeBranchId,
      draft: draft,
    ),
    onSaved: _applySubmitted,
    fallback: 'The leave request could not be submitted.',
  );

  Future<bool> updatePendingLeaveRequest({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
    required LeaveRequestDraft draft,
  }) => _save(
    () => repository.updatePendingLeaveRequest(
      access: access,
      activeBranchId: activeBranchId,
      request: request,
      draft: draft,
    ),
    onSaved: (saved) => _applyChanged(request, saved),
    fallback: 'The pending leave request could not be updated.',
  );

  Future<bool> reviewLeaveRequest({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
    required LeaveStatus decision,
    String? reviewerNotes,
  }) => _save(
    () => repository.reviewLeaveRequest(
      access: access,
      activeBranchId: activeBranchId,
      request: request,
      decision: decision,
      reviewerNotes: reviewerNotes,
    ),
    onSaved: (saved) => _applyChanged(request, saved),
    fallback: 'The leave decision could not be saved.',
  );

  /// The organization's active leave types for the leave form. Fetched once
  /// per session (and organization) and shared by concurrent callers; a
  /// failure is not cached, so the next call retries.
  Future<List<LeaveTypeOption>> loadLeaveTypes(UserAccessContext access) {
    final organizationId = access.organization?.id;
    final sameOrganization = _leaveTypesOrganizationId == organizationId;
    final cached = _leaveTypes;
    if (cached != null && sameOrganization) return Future.value(cached);
    final inFlight = _leaveTypesInFlight;
    if (inFlight != null && sameOrganization) return inFlight;
    // A fetch for another organization must not fill this cache.
    _leaveTypeEpoch++;
    _leaveTypes = null;
    _leaveTypesOrganizationId = organizationId;
    return _leaveTypesInFlight = _fetchLeaveTypes(access);
  }

  /// Forgets the cached leave types so the next form fetches them again
  /// (e.g. after a pull-to-refresh, in case the organization changed them).
  void invalidateLeaveTypes() {
    _leaveTypeEpoch++;
    _leaveTypes = null;
    _leaveTypesInFlight = null;
    _leaveTypesOrganizationId = null;
  }

  Future<List<LeaveTypeOption>> _fetchLeaveTypes(
    UserAccessContext access,
  ) async {
    final epoch = _leaveTypeEpoch;
    try {
      final types = List<LeaveTypeOption>.unmodifiable(
        await repository.getLeaveTypes(access: access),
      );
      if (epoch == _leaveTypeEpoch) _leaveTypes = types;
      return types;
    } finally {
      if (epoch == _leaveTypeEpoch) _leaveTypesInFlight = null;
    }
  }

  /// A paid/unpaid preview controller for one form or review dialog. The
  /// caller owns it and must dispose it when the dialog closes.
  LeavePreviewController createPreviewController({
    required UserAccessContext access,
    String? activeBranchId,
  }) => LeavePreviewController(
    repository: repository,
    access: access,
    activeBranchId: activeBranchId,
  );

  void clearActionError() {
    if (_actionErrorMessage == null) return;
    _actionErrorMessage = null;
    notifyListeners();
  }

  @override
  void reset() {
    _epoch++;
    _pageRequests.invalidate();
    _countRequests.invalidate();
    _isLoading = false;
    _isLoadingMore = false;
    _isSaving = false;
    _errorMessage = null;
    _actionErrorMessage = null;
    _items = const [];
    _total = 0;
    _counts = LeaveStatusCounts.zero;
    _queue = null;
    _statusFilter = null;
    invalidateLeaveTypes();
    notifyListeners();
  }

  /// Keeps the chosen queue when the role may read it, otherwise falls back
  /// to the role's default queue.
  LeaveQueue? _resolveQueue(UserAccessContext access) {
    final role = access.user.role;
    final current = _queue;
    _queue = current != null && current.isAvailableTo(role)
        ? current
        : LeaveQueue.defaultFor(role);
    return _queue;
  }

  Future<PageResult<LeaveRequest>> _fetchPage(
    UserAccessContext access,
    String? activeBranchId,
    LeaveQueue queue, {
    required int offset,
  }) => repository.getLeaveRequestsPage(
    access: access,
    activeBranchId: activeBranchId,
    queue: queue,
    status: _statusFilter,
    offset: offset,
    limit: pageSize,
  );

  void _setFirstPage(PageResult<LeaveRequest> page) {
    _items = List.unmodifiable(page.items);
    _total = page.total;
  }

  Future<bool> _save(
    Future<LeaveRequest> Function() action, {
    required ValueChanged<LeaveRequest> onSaved,
    required String fallback,
  }) async {
    final epoch = _epoch;
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final result = await action();
      if (epoch != _epoch || isDisposed) return false;
      onSaved(result);
      return true;
    } catch (error, stackTrace) {
      if (epoch != _epoch || isDisposed) return false;
      _actionErrorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: fallback,
      );
      return false;
    } finally {
      if (epoch == _epoch && !isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  bool _matchesFilter(LeaveRequest request) =>
      _statusFilter == null || request.status == _statusFilter;

  /// A new request belongs only to the applicant's own queue. It is placed at
  /// its server position when that falls inside the loaded pages; otherwise it
  /// arrives with a later page.
  void _applySubmitted(LeaveRequest request) {
    if (_queue != LeaveQueue.mine) return;
    _counts = _counts.added(request.status);
    if (!_matchesFilter(request)) return;
    final index = _items.indexWhere(
      (item) => compareLeaveRequests(request, item) < 0,
    );
    if (index == -1 && hasMore) {
      _total += 1;
      return;
    }
    final items = [..._items];
    items.insert(index == -1 ? items.length : index, request);
    _items = List.unmodifiable(items);
    _total += 1;
  }

  /// Updates [saved] in place, or drops it when it no longer matches the
  /// status filter (e.g. a reviewed request leaves the pending list).
  void _applyChanged(LeaveRequest previous, LeaveRequest saved) {
    final loaded = _items.any((item) => item.id == saved.id);
    if (!loaded) return;
    _counts = _counts.moved(previous.status, saved.status);
    if (_matchesFilter(saved)) {
      _items = List.unmodifiable([
        for (final item in _items) item.id == saved.id ? saved : item,
      ]);
      return;
    }
    _items = List.unmodifiable([
      for (final item in _items)
        if (item.id != saved.id) item,
    ]);
    if (_total > 0) _total -= 1;
  }
}
