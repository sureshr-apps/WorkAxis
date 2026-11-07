import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';

class ReturnsController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  final ReturnsRepository repository;

  final RequestGeneration _requests = RequestGeneration();
  int _epoch = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _actionErrorMessage;

  /// Always replaced, never mutated: repositories may hand back const lists.
  List<ReturnItem> _items = const [];
  ReturnStatus? _statusFilter;
  String _searchQuery = '';

  ReturnsController({required this.repository});

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  /// Failure from the last load; replaces the list with an error state.
  String? get errorMessage => _errorMessage;

  /// Failure from the last submit/review action; shown inline without
  /// discarding the loaded list.
  String? get actionErrorMessage => _actionErrorMessage;
  List<ReturnItem> get items => _items;
  ReturnStatus? get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;

  int get pendingCount =>
      _items.where((i) => i.status == ReturnStatus.pending).length;
  int get approvedCount =>
      _items.where((i) => i.status == ReturnStatus.approved).length;
  int get rejectedCount =>
      _items.where((i) => i.status == ReturnStatus.rejected).length;
  int get totalCount => _items.length;

  List<ReturnItem> get filteredItems {
    Iterable<ReturnItem> result = _items;
    if (_statusFilter != null) {
      result = result.where((i) => i.status == _statusFilter);
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      result = result.where((i) {
        return i.productTitle.toLowerCase().contains(q) ||
            i.invoiceNumber.toLowerCase().contains(q) ||
            i.employeeName.toLowerCase().contains(q) ||
            i.branchName.toLowerCase().contains(q);
      });
    }
    return result.toList();
  }

  void setFilter(ReturnStatus? filter) {
    if (_statusFilter == filter) return;
    _statusFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadReturns({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    final token = _requests.next();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getReturns(
        access: access,
        activeBranchId: activeBranchId,
      );
      if (!_requests.isCurrent(token)) return;
      _items = List.unmodifiable(result);
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

  Future<bool> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  }) async {
    final epoch = _epoch;
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final created = await repository.submitReturn(
        access: access,
        branchId: branchId,
        input: input,
      );
      if (epoch != _epoch) return false;
      _items = [created, ..._items];
      return true;
    } catch (e, st) {
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Failed to submit return request.',
      );
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
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
      if (epoch != _epoch) return false;
      _items = [for (final i in _items) i.id == item.id ? updated : i];
      return true;
    } catch (e, st) {
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Failed to update return decision.',
      );
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
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
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    _actionErrorMessage = null;
    _items = const [];
    _statusFilter = null;
    _searchQuery = '';
    notifyListeners();
  }
}
