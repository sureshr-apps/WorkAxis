import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/platform_dashboard_summary.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';
import 'package:workaxis/features/platform_dashboard/domain/repositories/platform_dashboard_repository.dart';

enum PlatformDashboardStatus { initial, loading, loaded, error }

/// Controller managing Platform Overview presentation state.
class PlatformDashboardController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  final PlatformDashboardRepository repository;

  final RequestGeneration _requests = RequestGeneration();
  PlatformDashboardStatus _status = PlatformDashboardStatus.initial;
  PlatformDashboardSummary? _summary;
  List<RecentOrganizationSummary> _recentOrganizations = const [];
  String? _errorMessage;

  PlatformDashboardController({required this.repository});

  PlatformDashboardStatus get status => _status;
  bool get isLoading => _status == PlatformDashboardStatus.loading;
  bool get hasError => _status == PlatformDashboardStatus.error;
  PlatformDashboardSummary? get summary => _summary;
  List<RecentOrganizationSummary> get recentOrganizations =>
      _recentOrganizations;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard() async {
    final token = _requests.next();
    _status = PlatformDashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final summaryResult = await repository.getPlatformDashboardSummary();
      final orgsResult = await repository.getRecentOrganizations();
      if (!_requests.isCurrent(token)) return;

      _summary = summaryResult;
      _recentOrganizations = orgsResult;
      _status = PlatformDashboardStatus.loaded;
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load the platform overview. Please try again.',
      );
      _status = PlatformDashboardStatus.error;
    }
    notifyListeners();
  }

  @override
  void reset() {
    _requests.invalidate();
    _status = PlatformDashboardStatus.initial;
    _summary = null;
    _recentOrganizations = const [];
    _errorMessage = null;
    notifyListeners();
  }
}
