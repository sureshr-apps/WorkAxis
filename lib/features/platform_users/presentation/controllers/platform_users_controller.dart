import 'package:flutter/foundation.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/errors/platform_users_failure.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/domain/repositories/platform_users_repository.dart';

/// Coordinates list, form, and access-status state for Platform Users.
class PlatformUsersController extends ChangeNotifier {
  PlatformUsersController({required this.repository});

  final PlatformUsersRepository repository;

  List<PlatformAdministrator> _allAdministrators = [];
  List<PlatformAdministrator> _administrators = [];
  PlatformAdministrator? _selectedAdministrator;
  AccountStatus? _statusFilter;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _actionErrorMessage;

  List<PlatformAdministrator> get administrators => _administrators;
  PlatformAdministrator? get selectedAdministrator => _selectedAdministrator;
  AccountStatus? get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  int get totalCount => _allAdministrators.length;
  int get activeCount => _countFor(AccountStatus.active);
  int get suspendedCount => _countFor(AccountStatus.suspended);

  int _countFor(AccountStatus status) =>
      _allAdministrators.where((item) => item.status == status).length;

  Future<void> loadAdministrators() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _allAdministrators = [...await repository.getAdministrators()];
      _applyFilters();
    } catch (_) {
      _errorMessage = 'Could not load platform administrators. Try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setStatusFilter(AccountStatus? status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  Future<PlatformAdministrator?> loadAdministrator(String id) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedAdministrator = null;
    notifyListeners();
    try {
      _selectedAdministrator = await repository.getAdministratorById(id);
      if (_selectedAdministrator == null) {
        _errorMessage = 'This platform administrator could not be found.';
      }
      return _selectedAdministrator;
    } catch (_) {
      _errorMessage = 'Could not load this platform administrator. Try again.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PlatformAdministrator?> createAdministrator({
    required PlatformAdministrator administrator,
    required String initialPassword,
  }) async {
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final created = await repository.createAdministrator(
        administrator: administrator,
        initialPassword: initialPassword,
      );
      _refreshAfterMutation(created, isNew: true);
      return created;
    } catch (error) {
      _actionErrorMessage = _friendlyError(error);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<PlatformAdministrator?> updateAdministrator(
    PlatformAdministrator administrator,
  ) async {
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final updated = await repository.updateAdministrator(administrator);
      _refreshAfterMutation(updated);
      return updated;
    } catch (error) {
      _actionErrorMessage = _friendlyError(error);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<PlatformAdministrator?> updateStatus(
    String id,
    AccountStatus status,
  ) async {
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final updated = await repository.updateAdministratorStatus(id, status);
      _refreshAfterMutation(updated);
      return updated;
    } catch (error) {
      _actionErrorMessage = _friendlyError(error);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearActionError() {
    _actionErrorMessage = null;
    notifyListeners();
  }

  void _refreshAfterMutation(
    PlatformAdministrator changed, {
    bool isNew = false,
  }) {
    _allAdministrators = [..._allAdministrators];
    final index = _allAdministrators.indexWhere(
      (item) => item.id == changed.id,
    );
    if (index == -1 && isNew) {
      _allAdministrators = [changed, ..._allAdministrators];
    } else if (index >= 0) {
      _allAdministrators[index] = changed;
    }
    _selectedAdministrator = changed;
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();
    _administrators = _allAdministrators
        .where((administrator) {
          if (_statusFilter != null && administrator.status != _statusFilter) {
            return false;
          }
          if (query.isEmpty) return true;
          return administrator.fullName.toLowerCase().contains(query) ||
              administrator.username.toLowerCase().contains(query) ||
              administrator.email.toLowerCase().contains(query) ||
              (administrator.phone?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);
  }

  String _friendlyError(Object error) {
    if (error is PlatformUsersFailure) return error.message;
    return 'The requested change could not be completed. Try again.';
  }
}
