import 'package:flutter/foundation.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';

/// Controller for Platform Organization Management.
class PlatformOrganizationsController extends ChangeNotifier {
  final PlatformOrganizationsRepository repository;

  PlatformOrganizationsController({required this.repository});

  List<CustomerOrganization> _allOrganizations = [];
  List<CustomerOrganization> _filteredOrganizations = [];
  CustomerOrganization? _selectedOrganization;
  OrganizationLicenseDetails? _selectedLicenseDetails;
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  String? _actionErrorMessage;

  String _searchQuery = '';
  OrganizationStatus? _statusFilter;

  List<CustomerOrganization> get organizations => _filteredOrganizations;
  CustomerOrganization? get selectedOrganization => _selectedOrganization;
  OrganizationLicenseDetails? get selectedLicenseDetails =>
      _selectedLicenseDetails;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  String get searchQuery => _searchQuery;
  OrganizationStatus? get statusFilter => _statusFilter;

  int get totalCount => _allOrganizations.length;
  int get activeCount => _allOrganizations
      .where((o) => o.status == OrganizationStatus.active)
      .length;
  int get suspendedCount => _allOrganizations
      .where((o) => o.status == OrganizationStatus.suspended)
      .length;

  Future<void> loadOrganizations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allOrganizations = await repository.getOrganizations();
      _applyFilter();
    } catch (e) {
      _errorMessage = 'Failed to load customer organizations: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void setStatusFilter(OrganizationStatus? filter) {
    _statusFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filteredOrganizations = _allOrganizations.where((org) {
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
    }).toList();
  }

  Future<CustomerOrganization?> loadOrganizationDetails(String id) async {
    _isLoading = true;
    _errorMessage = null;
    if (_selectedOrganization?.id != id) {
      _selectedOrganization = null;
      _selectedLicenseDetails = null;
    }
    notifyListeners();

    try {
      final org = await repository.getOrganizationById(id);
      _selectedOrganization = org;
      _selectedLicenseDetails = org == null
          ? null
          : await repository.getOrganizationLicenseDetails(id);
      return org;
    } catch (e) {
      _errorMessage = 'Failed to load organization details: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedOrganization(CustomerOrganization? org) {
    _selectedOrganization = org;
    notifyListeners();
  }

  Future<CustomerOrganization?> createOrganization(
    CreateOrganizationRequest request,
  ) async {
    _isActionLoading = true;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final created = await repository.createOrganization(request);
      await loadOrganizations();
      _selectedOrganization = created;
      return created;
    } catch (e) {
      _actionErrorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<CustomerOrganization?> updateOrganization(
    CustomerOrganization updatedOrg,
  ) async {
    _isActionLoading = true;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.updateOrganization(updatedOrg);
      await loadOrganizations();
      _selectedOrganization = updated;
      return updated;
    } catch (e) {
      _actionErrorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String id, OrganizationStatus newStatus) async {
    _isActionLoading = true;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.updateOrganizationStatus(id, newStatus);
      // Update in local lists
      final index = _allOrganizations.indexWhere((o) => o.id == id);
      if (index != -1) {
        _allOrganizations[index] = updated;
      }
      _applyFilter();
      if (_selectedOrganization?.id == id) {
        _selectedOrganization = updated;
      }
      return true;
    } catch (e) {
      _actionErrorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
