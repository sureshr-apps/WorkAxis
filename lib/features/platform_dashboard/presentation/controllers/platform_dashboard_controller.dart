import 'package:flutter/foundation.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/platform_dashboard_summary.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/recent_organization_summary.dart';
import 'package:workaxis/features/platform_dashboard/domain/repositories/platform_dashboard_repository.dart';

enum PlatformDashboardStatus { initial, loading, loaded, error }

/// Controller managing Platform Overview presentation state.
class PlatformDashboardController extends ChangeNotifier {
  final PlatformDashboardRepository repository;

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
    _status = PlatformDashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final summaryResult = await repository.getPlatformDashboardSummary();
      final orgsResult = await repository.getRecentOrganizations();

      _summary = summaryResult;
      _recentOrganizations = orgsResult;
      _status = PlatformDashboardStatus.loaded;
    } catch (e) {
      _errorMessage = 'Failed to load platform overview: $e';
      _status = PlatformDashboardStatus.error;
    } finally {
      notifyListeners();
    }
  }
}
