import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/domain/repositories/platform_users_repository.dart';

/// Coordinates list, form, and access-status state for Platform Users.
///
/// The list is paginated. Search and status filters apply instantly to the
/// loaded rows; when those rows are not the complete result (more pages exist,
/// or the loaded rows were themselves filtered by the server) the controller
/// also reloads from the server after [searchDebounce].
class PlatformUsersController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  PlatformUsersController({
    required this.repository,
    this.searchDebounce = const Duration(milliseconds: 300),
    this.pageSize = defaultPageSize,
  });

  final PlatformUsersRepository repository;
  final Duration searchDebounce;
  final int pageSize;

  final RequestGeneration _listRequests = RequestGeneration();
  final RequestGeneration _detailRequests = RequestGeneration();
  final RequestGeneration _countRequests = RequestGeneration();

  List<PlatformAdministrator> _loaded = const [];
  List<PlatformAdministrator> _administrators = const [];
  PlatformAdministrator? _selectedAdministrator;
  AccountStatus? _statusFilter;
  String _searchQuery = '';
  String _loadedFilterKey = '|';
  int _loadedTotal = 0;
  int _totalCount = 0;
  int _activeCount = 0;
  int _suspendedCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _actionErrorMessage;
  Timer? _debounce;

  List<PlatformAdministrator> get administrators => _administrators;
  PlatformAdministrator? get selectedAdministrator => _selectedAdministrator;
  AccountStatus? get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  /// Whether the server has more rows for the current search and filter.
  bool get hasMore => _loaded.length < _loadedTotal;

  /// Platform-wide counts (independent of the current search/filter).
  int get totalCount => _totalCount;
  int get activeCount => _activeCount;
  int get suspendedCount => _suspendedCount;

  String get _filterKey =>
      '${_searchQuery.trim().toLowerCase()}|${_statusFilter?.name ?? ''}';

  /// Loads the first page for the current search/filter plus the summary
  /// counts.
  Future<void> loadAdministrators() async {
    final token = _listRequests.next();
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    notifyListeners();
    final key = _filterKey;
    try {
      final page = await repository.getAdministratorsPage(
        query: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        status: _statusFilter,
        limit: pageSize,
      );
      if (!_listRequests.isCurrent(token)) return;
      _loaded = List.unmodifiable(page.items);
      _loadedTotal = page.total;
      _loadedFilterKey = key;
      _applyFilters();
    } catch (e, st) {
      if (!_listRequests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load platform administrators. Try again.',
      );
    }
    _isLoading = false;
    notifyListeners();
    await _loadCounts();
  }

  /// Appends the next page.
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !hasMore) return;
    final token = _listRequests.next();
    _isLoadingMore = true;
    notifyListeners();
    try {
      final page = await repository.getAdministratorsPage(
        query: _loadedFilterKey.startsWith('|') ? null : _searchQuery.trim(),
        status: _statusFilter,
        offset: _loaded.length,
        limit: pageSize,
      );
      if (!_listRequests.isCurrent(token)) return;
      _loaded = List.unmodifiable([..._loaded, ...page.items]);
      _loadedTotal = page.total;
      _applyFilters();
    } catch (e, st) {
      if (!_listRequests.isCurrent(token)) return;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load more administrators. Try again.',
      );
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
    _scheduleServerRefresh();
  }

  void setStatusFilter(AccountStatus? status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
    _scheduleServerRefresh();
  }

  Future<PlatformAdministrator?> loadAdministrator(String id) async {
    final token = _detailRequests.next();
    _isLoading = true;
    _errorMessage = null;
    _selectedAdministrator = null;
    notifyListeners();
    try {
      final result = await repository.getAdministratorById(id);
      if (!_detailRequests.isCurrent(token)) return null;
      _selectedAdministrator = result;
      if (result == null) {
        _errorMessage = 'This platform administrator could not be found.';
      }
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e, st) {
      if (!_detailRequests.isCurrent(token)) return null;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load this platform administrator. Try again.',
      );
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<PlatformAdministrator?> createAdministrator({
    required PlatformAdministrator administrator,
    required String initialPassword,
  }) async {
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final created = await repository.createAdministrator(
        administrator: administrator,
        initialPassword: initialPassword,
      );
      _refreshAfterMutation(created, isNew: true);
      await _loadCounts();
      return created;
    } catch (error, st) {
      _actionErrorMessage = _friendlyError(error, st);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<PlatformAdministrator?> updateAdministrator(
    PlatformAdministrator administrator,
  ) async {
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final updated = await repository.updateAdministrator(administrator);
      _refreshAfterMutation(updated);
      return updated;
    } catch (error, st) {
      _actionErrorMessage = _friendlyError(error, st);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<PlatformAdministrator?> updateStatus(
    String id,
    AccountStatus status,
  ) async {
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final updated = await repository.updateAdministratorStatus(id, status);
      _refreshAfterMutation(updated);
      await _loadCounts();
      return updated;
    } catch (error, st) {
      _actionErrorMessage = _friendlyError(error, st);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Sets a new password for the administrator [id]. Returns whether it
  /// succeeded; failures populate [actionErrorMessage].
  Future<bool> resetPassword({
    required String id,
    required String newPassword,
  }) async {
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      await repository.resetAdministratorPassword(
        id: id,
        newPassword: newPassword,
      );
      return true;
    } catch (error, st) {
      _actionErrorMessage = _friendlyError(error, st);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearActionError() {
    if (_actionErrorMessage == null) return;
    _actionErrorMessage = null;
    notifyListeners();
  }

  @override
  void reset() {
    _debounce?.cancel();
    _listRequests.invalidate();
    _detailRequests.invalidate();
    _countRequests.invalidate();
    _loaded = const [];
    _administrators = const [];
    _selectedAdministrator = null;
    _statusFilter = null;
    _searchQuery = '';
    _loadedFilterKey = '|';
    _loadedTotal = 0;
    _totalCount = 0;
    _activeCount = 0;
    _suspendedCount = 0;
    _isLoading = false;
    _isLoadingMore = false;
    _isSaving = false;
    _errorMessage = null;
    _actionErrorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleServerRefresh() {
    _debounce?.cancel();
    final loadedFiltered = _loadedFilterKey != '|';
    final needsServer =
        _filterKey != _loadedFilterKey && (hasMore || loadedFiltered);
    if (!needsServer) return;
    _debounce = Timer(searchDebounce, loadAdministrators);
  }

  Future<void> _loadCounts() async {
    final token = _countRequests.next();
    try {
      final results = await (
        repository.countAdministrators(),
        repository.countAdministrators(status: AccountStatus.active),
        repository.countAdministrators(status: AccountStatus.suspended),
      ).wait;
      if (!_countRequests.isCurrent(token)) return;
      _totalCount = results.$1;
      _activeCount = results.$2;
      _suspendedCount = results.$3;
      notifyListeners();
    } catch (_) {
      // Summary counts are decorative; keep the previous values and let the
      // list surface its own errors.
    }
  }

  void _refreshAfterMutation(
    PlatformAdministrator changed, {
    bool isNew = false,
  }) {
    final index = _loaded.indexWhere((item) => item.id == changed.id);
    final next = [..._loaded];
    if (index == -1 && isNew) {
      next.insert(0, changed);
      _loadedTotal += 1;
    } else if (index >= 0) {
      next[index] = changed;
    }
    _loaded = List.unmodifiable(next);
    _selectedAdministrator = changed;
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();
    _administrators = _loaded
        .where((administrator) {
          if (_statusFilter != null && administrator.status != _statusFilter) {
            return false;
          }
          if (query.isEmpty) return true;
          return administrator.fullName.toLowerCase().contains(query) ||
              administrator.username.toLowerCase().contains(query) ||
              administrator.email.toLowerCase().contains(query) ||
              (administrator.phone?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);
  }

  String _friendlyError(Object error, StackTrace st) => userMessageFor(
    error,
    st,
    fallback: 'The requested change could not be completed. Try again.',
  );
}
