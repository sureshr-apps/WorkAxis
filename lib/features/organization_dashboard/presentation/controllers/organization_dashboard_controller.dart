import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/repositories/organization_dashboard_repository.dart';

enum OrganizationDashboardStatus { initial, loading, loaded, error }

/// Controller managing Organization Admin Overview presentation state.
class OrganizationDashboardController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  final OrganizationDashboardRepository repository;

  final RequestGeneration _requests = RequestGeneration();
  OrganizationDashboardStatus _status = OrganizationDashboardStatus.initial;
  OrganizationDashboardSummary? _summary;
  String? _errorMessage;

  OrganizationDashboardController({required this.repository});

  OrganizationDashboardStatus get status => _status;
  bool get isLoading => _status == OrganizationDashboardStatus.loading;
  bool get hasError => _status == OrganizationDashboardStatus.error;
  OrganizationDashboardSummary? get summary => _summary;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard({required UserAccessContext access}) async {
    final token = _requests.next();
    _status = OrganizationDashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getOrganizationDashboardSummary(
        access: access,
      );
      if (!_requests.isCurrent(token)) return;
      _summary = result;
      _status = OrganizationDashboardStatus.loaded;
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load the organization overview. Please try again.',
      );
      _status = OrganizationDashboardStatus.error;
    }
    notifyListeners();
  }

  @override
  void reset() {
    _requests.invalidate();
    _status = OrganizationDashboardStatus.initial;
    _summary = null;
    _errorMessage = null;
    notifyListeners();
  }
}
