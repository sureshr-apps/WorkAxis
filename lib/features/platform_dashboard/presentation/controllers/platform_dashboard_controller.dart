import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/platform_dashboard/domain/models/platform_dashboard_summary.dart';
import 'package:workaxis/features/platform_dashboard/domain/repositories/platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';

enum PlatformDashboardStatus { initial, loading, loaded, error }

/// Controller managing Platform Overview presentation state.
///
/// The recent organizations are searched on the server with the same query and
/// status filter as the Organizations tab, so a search finds every match, not
/// only the newest rows.
class PlatformDashboardController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  PlatformDashboardController({
    required this.repository,
    this.searchDebounce = const Duration(milliseconds: 300),
  });

  final PlatformDashboardRepository repository;
  final Duration searchDebounce;

  final RequestGeneration _requests = RequestGeneration();
  final RequestGeneration _recentRequests = RequestGeneration();
  Timer? _searchDebounceTimer;

  PlatformDashboardStatus _status = PlatformDashboardStatus.initial;
  PlatformDashboardSummary? _summary;
  List<CustomerOrganization> _recentOrganizations = const [];
  String? _errorMessage;
  String _recentQuery = '';
  OrganizationStatus? _recentStatus;
  String? _recentErrorMessage;

  PlatformDashboardStatus get status => _status;
  bool get isLoading => _status == PlatformDashboardStatus.loading;
  bool get hasError => _status == PlatformDashboardStatus.error;
  PlatformDashboardSummary? get summary => _summary;
  List<CustomerOrganization> get recentOrganizations => _recentOrganizations;
  String? get errorMessage => _errorMessage;
  String get recentQuery => _recentQuery;
  OrganizationStatus? get recentStatus => _recentStatus;

  /// Failure from the last recent-organizations search. The list keeps its
  /// previous rows so the panel never goes blank on a failed search.
  String? get recentErrorMessage => _recentErrorMessage;

  Future<void> loadDashboard() async {
    final token = _requests.next();
    final recentToken = _recentRequests.next();
    _status = PlatformDashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final summaryResult = await repository.getPlatformDashboardSummary();
      final orgsResult = await repository.getRecentOrganizations(
        query: _recentQuery,
        status: _recentStatus,
      );
      if (!_requests.isCurrent(token)) return;

      _summary = summaryResult;
      // A search typed while this load was in flight owns the list now.
      if (_recentRequests.isCurrent(recentToken)) {
        _recentOrganizations = orgsResult;
        _recentErrorMessage = null;
      }
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

  /// Searches the recent organizations by name or code and by status. Typing
  /// is debounced, so the server is queried once the user pauses.
  void searchRecentOrganizations(String query, OrganizationStatus? status) {
    _recentQuery = query;
    _recentStatus = status;
    // Results for earlier input are no longer wanted, including an in-flight load.
    _recentRequests.invalidate();
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(searchDebounce, _reloadRecentOrganizations);
  }

  /// Forgets the previous search. Called when the dashboard is entered again, so
  /// an empty search box always matches the list it shows.
  void clearRecentSearch() {
    _recentRequests.invalidate();
    _searchDebounceTimer?.cancel();
    _recentQuery = '';
    _recentStatus = null;
    _recentErrorMessage = null;
  }

  Future<void> _reloadRecentOrganizations() async {
    final token = _recentRequests.next();
    final query = _recentQuery;
    final status = _recentStatus;
    try {
      final orgs = await repository.getRecentOrganizations(
        query: query,
        status: status,
      );
      if (!_recentRequests.isCurrent(token)) return;
      _recentOrganizations = orgs;
      _recentErrorMessage = null;
    } catch (e, st) {
      if (!_recentRequests.isCurrent(token)) return;
      _recentErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not search organizations. Please try again.',
      );
    }
    notifyListeners();
  }

  @override
  void reset() {
    _requests.invalidate();
    _recentRequests.invalidate();
    _searchDebounceTimer?.cancel();
    _status = PlatformDashboardStatus.initial;
    _summary = null;
    _recentOrganizations = const [];
    _errorMessage = null;
    _recentQuery = '';
    _recentStatus = null;
    _recentErrorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
