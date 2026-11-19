import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';
import 'package:workaxis/features/assets/domain/repositories/assets_repository.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

class AssetsController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  AssetsController({required this.repository, required this.membersRepository});

  final AssetsRepository repository;
  final OrganizationMembersRepository membersRepository;
  final RequestGeneration _requests = RequestGeneration();
  int _scopeGeneration = 0;

  List<EmployeeAsset> _assets = const [];
  List<OrganizationMember> _members = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String _query = '';
  String? _errorMessage;
  String? _actionErrorMessage;

  List<EmployeeAsset> get assets => _assets;
  List<OrganizationMember> get members => _members;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  String get query => _query;

  List<EmployeeAsset> get filteredAssets {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _assets;
    return _assets
        .where((asset) {
          final searchable =
              '${asset.name} ${asset.category} ${asset.assetTag} '
                      '${asset.serialNumber ?? ''} ${asset.employeeName} '
                      '${asset.branchName}'
                  .toLowerCase();
          return searchable.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> load(UserAccessContext access, {String? activeBranchId}) async {
    final scopeGeneration = ++_scopeGeneration;
    final request = _requests.next();
    _isLoading = true;
    _errorMessage = null;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final assets = await repository.getAssets(
        access: access,
        activeBranchId: activeBranchId,
      );
      final members = access.user.role == UserRole.employee
          ? const <OrganizationMember>[]
          : await membersRepository.getMembers(
              access: access,
              activeBranchId: activeBranchId,
              maxItems: 500,
            );
      if (!_requests.isCurrent(request) ||
          scopeGeneration != _scopeGeneration) {
        return;
      }
      _assets = assets;
      _members = members
          .where((member) => member.role == UserRole.employee)
          .toList(growable: false);
    } catch (error, stackTrace) {
      if (!_requests.isCurrent(request) ||
          scopeGeneration != _scopeGeneration) {
        return;
      }
      _errorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'Assets could not be loaded. Please try again.',
      );
    } finally {
      if (_requests.isCurrent(request) && scopeGeneration == _scopeGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<bool> saveAsset(
    UserAccessContext access,
    EmployeeAsset asset, {
    String? activeBranchId,
  }) async {
    final scopeGeneration = _scopeGeneration;
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final saved = await repository.saveAsset(
        access: access,
        asset: asset,
        activeBranchId: activeBranchId,
      );
      if (scopeGeneration != _scopeGeneration) return false;
      final index = _assets.indexWhere((current) => current.id == saved.id);
      if (index == -1) {
        _assets = [..._assets, saved];
      } else {
        final updated = [..._assets];
        updated[index] = saved;
        _assets = updated;
      }
      return true;
    } catch (error, stackTrace) {
      if (scopeGeneration != _scopeGeneration) return false;
      _actionErrorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'The asset could not be saved. Please try again.',
      );
      return false;
    } finally {
      if (scopeGeneration == _scopeGeneration) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<bool> deleteAsset(
    UserAccessContext access,
    EmployeeAsset asset, {
    String? activeBranchId,
  }) async {
    final scopeGeneration = _scopeGeneration;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      await repository.deleteAsset(
        access: access,
        assetId: asset.id,
        activeBranchId: activeBranchId,
      );
      if (scopeGeneration != _scopeGeneration) return false;
      _assets = _assets.where((item) => item.id != asset.id).toList();
      return true;
    } catch (error, stackTrace) {
      if (scopeGeneration != _scopeGeneration) return false;
      _actionErrorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'The asset could not be deleted. Please try again.',
      );
      return false;
    } finally {
      if (scopeGeneration == _scopeGeneration) notifyListeners();
    }
  }

  void clearActionError() {
    _actionErrorMessage = null;
    notifyListeners();
  }

  @override
  void reset() {
    _scopeGeneration++;
    _requests.invalidate();
    _assets = const [];
    _members = const [];
    _isLoading = false;
    _isSaving = false;
    _query = '';
    _errorMessage = null;
    _actionErrorMessage = null;
    notifyListeners();
  }
}
