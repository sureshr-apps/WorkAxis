import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';
import 'package:workaxis/features/branch_dashboard/domain/repositories/branch_dashboard_repository.dart';

enum BranchDashboardStatus { initial, loading, loaded, error }

/// Controller managing Branch Manager Overview presentation state.
class BranchDashboardController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  final BranchDashboardRepository repository;

  final RequestGeneration _requests = RequestGeneration();
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

  Future<void> loadDashboard({
    required UserAccessContext access,
    required String branchId,
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

    final token = _requests.next();
    _status = BranchDashboardStatus.loading;
    _loadedBranchId = branchId;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getBranchDashboardSummary(
        access: access,
        branchId: branchId,
      );
      if (!_requests.isCurrent(token)) return;
      _summary = result;
      _status = BranchDashboardStatus.loaded;
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load the branch overview. Please try again.',
      );
      _status = BranchDashboardStatus.error;
    }
    notifyListeners();
  }

  @override
  void reset() {
    _requests.invalidate();
    _status = BranchDashboardStatus.initial;
    _summary = null;
    _loadedBranchId = null;
    _errorMessage = null;
    notifyListeners();
  }
}
