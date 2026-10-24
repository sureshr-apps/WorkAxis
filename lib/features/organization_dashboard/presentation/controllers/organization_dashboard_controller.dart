import 'package:flutter/foundation.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/organization_dashboard_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/repositories/organization_dashboard_repository.dart';

enum OrganizationDashboardStatus { initial, loading, loaded, error }

/// Controller managing Organization Admin Overview presentation state.
class OrganizationDashboardController extends ChangeNotifier {
  final OrganizationDashboardRepository repository;

  OrganizationDashboardStatus _status = OrganizationDashboardStatus.initial;
  OrganizationDashboardSummary? _summary;
  String? _errorMessage;

  OrganizationDashboardController({required this.repository});

  OrganizationDashboardStatus get status => _status;
  bool get isLoading => _status == OrganizationDashboardStatus.loading;
  bool get hasError => _status == OrganizationDashboardStatus.error;
  OrganizationDashboardSummary? get summary => _summary;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard() async {
    _status = OrganizationDashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getOrganizationDashboardSummary();
      _summary = result;
      _status = OrganizationDashboardStatus.loaded;
    } catch (e) {
      _errorMessage = 'Failed to load organization overview: $e';
      _status = OrganizationDashboardStatus.error;
    } finally {
      notifyListeners();
    }
  }
}
