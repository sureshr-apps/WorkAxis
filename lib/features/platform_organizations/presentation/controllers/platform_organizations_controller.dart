import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_draft.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_admin_rules.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';

/// Controller for Platform Organization Management.
///
/// The organization list and the selected-organization detail load
/// independently: each has its own loading flag, error and stale-response
/// guard, so opening a detail page never flips the list into a loading/error
/// state (or vice versa).
class PlatformOrganizationsController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  final PlatformOrganizationsRepository repository;

  PlatformOrganizationsController({
    required this.repository,
    this.searchDebounce = const Duration(milliseconds: 300),
    this.pageSize = defaultPageSize,
  });

  /// Delay before a search/filter change reloads from the server.
  final Duration searchDebounce;

  /// Organizations requested per page.
  final int pageSize;

  int _scopeEpoch = 0;
  bool _isCurrentScope(int epoch) => epoch == _scopeEpoch && !isDisposed;

  final RequestGeneration _listRequests = RequestGeneration();
  final RequestGeneration _detailRequests = RequestGeneration();
  final RequestGeneration _countRequests = RequestGeneration();
  Timer? _debounce;
  String _loadedFilterKey = '|';
  int _loadedTotal = 0;
  bool _isLoadingMore = false;
  OrganizationStatusCounts _counts = const OrganizationStatusCounts(
    active: 0,
    suspended: 0,
  );

  List<CustomerOrganization> _allOrganizations = const [];
  List<CustomerOrganization> _filteredOrganizations = const [];
  CustomerOrganization? _selectedOrganization;
  OrganizationLicenseDetails? _selectedLicenseDetails;
  bool _isListLoading = false;
  bool _isDetailLoading = false;
  bool _isActionLoading = false;
  String? _listErrorMessage;
  String? _detailErrorMessage;
  String? _actionErrorMessage;

  String _searchQuery = '';
  OrganizationStatus? _statusFilter;

  List<CustomerOrganization> get organizations => _filteredOrganizations;
  CustomerOrganization? get selectedOrganization => _selectedOrganization;
  OrganizationLicenseDetails? get selectedLicenseDetails =>
      _selectedLicenseDetails;

  /// Whether the organization list is loading.
  bool get isListLoading => _isListLoading;

  /// Whether the selected organization's details are loading.
  bool get isDetailLoading => _isDetailLoading;

  /// Failure from the last list load.
  String? get listErrorMessage => _listErrorMessage;

  /// Failure from the last detail load.
  String? get detailErrorMessage => _detailErrorMessage;

  /// Legacy combined flag: true while the list or a detail is loading.
  /// New code should use [isListLoading] / [isDetailLoading].
  bool get isLoading => _isListLoading || _isDetailLoading;

  /// Legacy combined error: the list error, else the detail error.
  /// New code should use [listErrorMessage] / [detailErrorMessage].
  String? get errorMessage => _listErrorMessage ?? _detailErrorMessage;

  bool get isActionLoading => _isActionLoading;
  String? get actionErrorMessage => _actionErrorMessage;
  String get searchQuery => _searchQuery;
  OrganizationStatus? get statusFilter => _statusFilter;

  /// Platform-wide counts (independent of the current search/filter).
  int get totalCount => _counts.total;
  int get activeCount => _counts.active;
  int get suspendedCount => _counts.suspended;

  bool get isLoadingMore => _isLoadingMore;

  /// Whether the server has more rows for the current search and filter.
  bool get hasMore => _allOrganizations.length < _loadedTotal;

  String get _filterKey =>
      '${_searchQuery.trim().toLowerCase()}|${_statusFilter?.name ?? ''}';

  Future<void> loadOrganizations() async {
    final token = _listRequests.next();
    _isListLoading = true;
    _isLoadingMore = false;
    _listErrorMessage = null;
    notifyListeners();

    final key = _filterKey;
    try {
      final page = await repository.getOrganizationsPage(
        query: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        statusFilter: _statusFilter,
        limit: pageSize,
      );
      if (!_listRequests.isCurrent(token)) return;
      _allOrganizations = List.unmodifiable(page.items);
      _loadedTotal = page.total;
      _loadedFilterKey = key;
      _applyFilter();
    } catch (e, st) {
      if (!_listRequests.isCurrent(token)) return;
      _listErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load customer organizations. Please try again.',
      );
    }
    _isListLoading = false;
    notifyListeners();
    await _loadCounts();
  }

  /// Appends the next page of organizations.
  Future<void> loadMore() async {
    if (_isListLoading || _isLoadingMore || !hasMore) return;
    final token = _listRequests.next();
    _isLoadingMore = true;
    notifyListeners();
    try {
      final page = await repository.getOrganizationsPage(
        query: _loadedFilterKey.startsWith('|') ? null : _searchQuery.trim(),
        statusFilter: _statusFilter,
        offset: _allOrganizations.length,
        limit: pageSize,
      );
      if (!_listRequests.isCurrent(token)) return;
      _allOrganizations = List.unmodifiable([
        ..._allOrganizations,
        ...page.items,
      ]);
      _loadedTotal = page.total;
      _applyFilter();
    } catch (e, st) {
      if (!_listRequests.isCurrent(token)) return;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load more organizations. Please try again.',
      );
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
    _scheduleServerRefresh();
  }

  void setStatusFilter(OrganizationStatus? filter) {
    _statusFilter = filter;
    _applyFilter();
    notifyListeners();
    _scheduleServerRefresh();
  }

  /// Search and filters apply instantly to loaded rows. When those rows are
  /// not the complete result, the server is queried after [searchDebounce].
  void _scheduleServerRefresh() {
    _debounce?.cancel();
    final loadedFiltered = _loadedFilterKey != '|';
    final needsServer =
        _filterKey != _loadedFilterKey && (hasMore || loadedFiltered);
    if (!needsServer) return;
    _debounce = Timer(searchDebounce, loadOrganizations);
  }

  Future<void> _loadCounts() async {
    final token = _countRequests.next();
    try {
      final counts = await repository.getStatusCounts();
      if (!_countRequests.isCurrent(token)) return;
      _counts = counts;
      notifyListeners();
    } catch (_) {
      // Summary counts are decorative; the list reports its own errors.
    }
  }

  void _applyFilter() {
    _filteredOrganizations = _allOrganizations
        .where((org) {
          if (_statusFilter != null && org.status != _statusFilter) {
            return false;
          }
          if (_searchQuery.trim().isNotEmpty) {
            final q = _searchQuery.trim().toLowerCase();
            final matchesName = org.name.toLowerCase().contains(q);
            final matchesCode = org.code.toLowerCase().contains(q);
            if (!matchesName && !matchesCode) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }

  Future<CustomerOrganization?> loadOrganizationDetails(String id) async {
    final token = _detailRequests.next();
    _isDetailLoading = true;
    _detailErrorMessage = null;
    if (_selectedOrganization?.id != id) {
      _selectedOrganization = null;
      _selectedLicenseDetails = null;
    }
    notifyListeners();

    try {
      final org = await repository.getOrganizationById(id);
      final license = org == null
          ? null
          : await repository.getOrganizationLicenseDetails(id);
      if (!_detailRequests.isCurrent(token)) return null;
      _selectedOrganization = org;
      _selectedLicenseDetails = license;
      _isDetailLoading = false;
      notifyListeners();
      return org;
    } catch (e, st) {
      if (!_detailRequests.isCurrent(token)) return null;
      _detailErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load organization details. Please try again.',
      );
      _isDetailLoading = false;
      notifyListeners();
      return null;
    }
  }

  void setSelectedOrganization(CustomerOrganization? org) {
    _selectedOrganization = org;
    notifyListeners();
  }

  Future<CustomerOrganization?> createOrganization(
    CreateOrganizationRequest request,
  ) async {
    final epoch = _scopeEpoch;
    _isActionLoading = true;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final created = await repository.createOrganization(request);
      if (!_isCurrentScope(epoch)) return null;
      await loadOrganizations();
      if (!_isCurrentScope(epoch)) return null;
      _selectedOrganization = created;
      return created;
    } catch (e, st) {
      if (!_isCurrentScope(epoch)) return null;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'The organization could not be created. Please try again.',
      );
      return null;
    } finally {
      if (_isCurrentScope(epoch)) {
        _isActionLoading = false;
        notifyListeners();
      }
    }
  }

  Future<CustomerOrganization?> updateOrganization(
    CustomerOrganization updatedOrg,
  ) async {
    final epoch = _scopeEpoch;
    _isActionLoading = true;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.updateOrganization(updatedOrg);
      if (!_isCurrentScope(epoch)) return null;
      await loadOrganizations();
      if (!_isCurrentScope(epoch)) return null;
      _selectedOrganization = updated;
      return updated;
    } catch (e, st) {
      if (!_isCurrentScope(epoch)) return null;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'The organization could not be updated. Please try again.',
      );
      return null;
    } finally {
      if (_isCurrentScope(epoch)) {
        _isActionLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> updateStatus(String id, OrganizationStatus newStatus) async {
    final epoch = _scopeEpoch;
    _isActionLoading = true;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.updateOrganizationStatus(id, newStatus);
      if (!_isCurrentScope(epoch)) return false;
      await _loadCounts();
      if (!_isCurrentScope(epoch)) return false;
      _allOrganizations = [
        for (final o in _allOrganizations) o.id == id ? updated : o,
      ];
      _applyFilter();
      if (_selectedOrganization?.id == id) {
        _selectedOrganization = updated;
      }
      return true;
    } catch (e, st) {
      if (!_isCurrentScope(epoch)) return false;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'The status could not be changed. Please try again.',
      );
      return false;
    } finally {
      if (_isCurrentScope(epoch)) {
        _isActionLoading = false;
        notifyListeners();
      }
    }
  }

  /// Adds an Organization Admin to the selected organization.
  /// Returns false (with [actionErrorMessage] set) on failure.
  Future<bool> createAdministrator(
    String organizationId,
    OrganizationAdminDraft draft,
  ) => _runAdminAction(
    fallback: 'The administrator could not be added. Please try again.',
    body: () => repository.createOrganizationAdmin(organizationId, draft),
  );

  /// Saves an administrator's name, email and phone.
  Future<bool> updateAdministrator(
    String organizationId,
    OrganizationAdminUser administrator,
  ) => _runAdminAction(
    fallback: 'The administrator could not be updated. Please try again.',
    body: () =>
        repository.updateOrganizationAdmin(organizationId, administrator),
  );

  /// Sets a new password for an administrator.
  Future<bool> resetAdministratorPassword(
    String organizationId,
    String adminId,
    String newPassword,
  ) => _runAdminAction(
    fallback: 'The password could not be reset. Please try again.',
    body: () async {
      await repository.resetOrganizationAdminPassword(
        organizationId: organizationId,
        adminId: adminId,
        newPassword: newPassword,
      );
      return null;
    },
  );

  /// Suspends or reactivates an administrator. Suspending the last active
  /// administrator is refused before any request is sent.
  Future<bool> setAdministratorStatus(
    String organizationId,
    String adminId,
    OrganizationAdminStatus status,
  ) {
    final selected = _selectedOrganization;
    if (selected != null && selected.id == organizationId) {
      try {
        OrganizationAdminRules.checkStatusChange(
          selected.admins,
          adminId,
          status,
        );
      } on Object catch (e, st) {
        _actionErrorMessage = userMessageFor(e, st, fallback: '');
        notifyListeners();
        return Future.value(false);
      }
    }
    return _runAdminAction(
      fallback: status == OrganizationAdminStatus.active
          ? 'The administrator could not be reactivated. Please try again.'
          : 'The administrator could not be suspended. Please try again.',
      body: () => repository.setOrganizationAdminStatus(
        organizationId,
        adminId,
        status,
      ),
    );
  }

  /// Whether [adminId] is the only active administrator of the selected
  /// organization (used to disable the suspend action).
  bool isLastActiveAdministrator(String adminId) {
    final selected = _selectedOrganization;
    return selected != null &&
        OrganizationAdminRules.isLastActiveAdmin(selected.admins, adminId);
  }

  Future<bool> _runAdminAction({
    required String fallback,
    required Future<CustomerOrganization?> Function() body,
  }) async {
    final epoch = _scopeEpoch;
    _isActionLoading = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final updated = await body();
      if (!_isCurrentScope(epoch)) return false;
      if (updated != null) _applyOrganization(updated);
      return true;
    } catch (e, st) {
      if (!_isCurrentScope(epoch)) return false;
      _actionErrorMessage = userMessageFor(e, st, fallback: fallback);
      return false;
    } finally {
      if (_isCurrentScope(epoch)) {
        _isActionLoading = false;
        notifyListeners();
      }
    }
  }

  /// Replaces the loaded copies of [updated] with what the server returned.
  void _applyOrganization(CustomerOrganization updated) {
    _allOrganizations = [
      for (final o in _allOrganizations) o.id == updated.id ? updated : o,
    ];
    _applyFilter();
    if (_selectedOrganization?.id == updated.id) {
      _selectedOrganization = updated;
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
    _scopeEpoch++;
    _debounce?.cancel();
    _listRequests.invalidate();
    _detailRequests.invalidate();
    _countRequests.invalidate();
    _loadedFilterKey = '|';
    _loadedTotal = 0;
    _isLoadingMore = false;
    _counts = const OrganizationStatusCounts(active: 0, suspended: 0);
    _allOrganizations = const [];
    _filteredOrganizations = const [];
    _selectedOrganization = null;
    _selectedLicenseDetails = null;
    _isListLoading = false;
    _isDetailLoading = false;
    _isActionLoading = false;
    _listErrorMessage = null;
    _detailErrorMessage = null;
    _actionErrorMessage = null;
    _searchQuery = '';
    _statusFilter = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
