import 'package:flutter/foundation.dart';
import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';
import 'package:workaxis/features/branch_dashboard/domain/repositories/branch_dashboard_repository.dart';

enum BranchDashboardStatus { initial, loading, loaded, error }

/// Controller managing Branch Manager Overview presentation state.
class BranchDashboardController extends ChangeNotifier {
  final BranchDashboardRepository repository;

  BranchDashboardStatus _status = BranchDashboardStatus.initial;
  BranchDashboardSummary? _summary;
  String? _loadedBranchId;
  String? _errorMessage;

  BranchDashboardController({required this.repository});

  BranchDashboardStatus get status => _status;
  bool get isLoading => _status == BranchDashboardStatus.loading;
  bool get hasError => _status == BranchDashboardStatus.error;
  BranchDashboardSummary? get summary => _summary;
  String? get loadedBranchId => _loadedBranchId;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard(
    String branchId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _status == BranchDashboardStatus.loaded &&
        _loadedBranchId == branchId) {
      return;
    }

    // Immediately clear previous branch data so old branch metrics are never shown
    if (_loadedBranchId != branchId) {
      _summary = null;
    }

    _status = BranchDashboardStatus.loading;
    _loadedBranchId = branchId;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getBranchDashboardSummary(branchId);
      _summary = result;
      _status = BranchDashboardStatus.loaded;
    } catch (e) {
      _errorMessage = 'Failed to load branch overview: $e';
      _status = BranchDashboardStatus.error;
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _status = BranchDashboardStatus.initial;
    _summary = null;
    _loadedBranchId = null;
    _errorMessage = null;
    notifyListeners();
  }
}
