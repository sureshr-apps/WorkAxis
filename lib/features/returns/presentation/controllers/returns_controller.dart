import 'package:flutter/foundation.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';

class ReturnsController extends ChangeNotifier {
  final ReturnsRepository repository;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<ReturnItem> _items = [];
  ReturnStatus? _statusFilter;
  String _searchQuery = '';

  ReturnsController({required this.repository});

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await repository.getReturns(
        access: access,
        activeBranchId: activeBranchId,
      );
    } catch (e) {
      _errorMessage = 'Failed to load return requests. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await repository.submitReturn(
        access: access,
        branchId: branchId,
        input: input,
      );
      _items.insert(0, created);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit return request.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> reviewReturn({
    required String returnId,
    required ReturnStatus decision,
    required String reviewerNotes,
    required String reviewerName,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.reviewReturn(
        returnId: returnId,
        decision: decision,
        reviewerNotes: reviewerNotes,
        reviewerName: reviewerName,
      );
      final index = _items.indexWhere((i) => i.id == returnId);
      if (index != -1) {
        _items[index] = updated;
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update return decision.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
