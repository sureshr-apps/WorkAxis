import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/domain/repositories/branch_management_repository.dart';

class BranchManagementController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  BranchManagementController({required this.repository});

  final BranchManagementRepository repository;
  int _scopeEpoch = 0;
  bool _isCurrentScope(int epoch) => epoch == _scopeEpoch && !isDisposed;

  final RequestGeneration _requests = RequestGeneration();
  List<BranchRecord> _branches = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _actionErrorMessage;
  KioskPairingToken? _pairingToken;
  List<BranchManagerOption> _managerOptions = const [];

  String _searchQuery = '';
  List<BranchRecord> _filteredBranches = const [];

  List<BranchRecord> get branches => _branches;

  /// Branches matching [searchQuery]; recomputed only when data or query change.
  List<BranchRecord> get filteredBranches => _filteredBranches;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String value) {
    if (value == _searchQuery) return;
    _searchQuery = value;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    final query = _searchQuery.trim().toLowerCase();
    _filteredBranches = query.isEmpty
        ? _branches
        : _branches
              .where(
                (branch) => '${branch.name} ${branch.code} ${branch.location}'
                    .toLowerCase()
                    .contains(query),
              )
              .toList(growable: false);
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  KioskPairingToken? get pairingToken => _pairingToken;
  List<BranchManagerOption> get managerOptions => _managerOptions;

  Future<void> loadBranches(UserAccessContext access) async {
    final token = _requests.next();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getBranches(access);
      if (!_requests.isCurrent(token)) return;
      _branches = result;
      _applyFilter();
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load branch settings. Try again.',
      );
    }
    _isLoading = false;
    notifyListeners();
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
    _requests.invalidate();
    _branches = const [];
    _filteredBranches = const [];
    _searchQuery = '';
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    _actionErrorMessage = null;
    _pairingToken = null;
    _managerOptions = const [];
    notifyListeners();
  }

  Future<BranchRecord?> getBranch(UserAccessContext access, String id) async {
    final epoch = _scopeEpoch;
    try {
      final branch = await repository.getBranch(access, id);
      return _isCurrentScope(epoch) ? branch : null;
    } catch (e, st) {
      if (!_isCurrentScope(epoch)) return null;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'This branch could not be loaded.',
      );
      notifyListeners();
      return null;
    }
  }

  Future<void> loadManagerOptions(UserAccessContext access) async {
    final epoch = _scopeEpoch;
    try {
      final options = await repository.getBranchManagers(access);
      if (!_isCurrentScope(epoch)) return;
      _managerOptions = options;
      notifyListeners();
    } catch (e, st) {
      if (!_isCurrentScope(epoch)) return;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Branch manager options could not be loaded.',
      );
      notifyListeners();
    }
  }

  Future<BranchRecord?> saveBranch({
    required UserAccessContext access,
    required BranchRecord branch,
  }) async {
    final epoch = _scopeEpoch;
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final saved = await repository.saveBranch(access: access, branch: branch);
      if (!_isCurrentScope(epoch)) return null;
      await loadBranches(access);
      if (!_isCurrentScope(epoch)) return null;
      return saved;
    } catch (e, st) {
      if (!_isCurrentScope(epoch)) return null;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback:
            'The branch could not be saved. Check its details and try again.',
      );
      return null;
    } finally {
      if (_isCurrentScope(epoch)) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<KioskPairingToken?> createPairingToken({
    required UserAccessContext access,
    required String branchId,
  }) async {
    final epoch = _scopeEpoch;
    _isSaving = true;
    _actionErrorMessage = null;
    _pairingToken = null;
    notifyListeners();
    try {
      final pairingToken = await repository.createKioskPairingToken(
        access: access,
        branchId: branchId,
      );
      if (!_isCurrentScope(epoch)) return null;
      _pairingToken = pairingToken;
      await loadBranches(access);
      if (!_isCurrentScope(epoch)) return null;
      return _pairingToken;
    } catch (e, st) {
      if (!_isCurrentScope(epoch)) return null;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'A pairing code could not be generated.',
      );
      return null;
    } finally {
      if (_isCurrentScope(epoch)) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  Future<bool> completePairing({
    required UserAccessContext access,
    required String branchId,
  }) async {
    final epoch = _scopeEpoch;
    try {
      await repository.completeKioskPairing(access: access, branchId: branchId);
      if (!_isCurrentScope(epoch)) return false;
      await loadBranches(access);
      if (!_isCurrentScope(epoch)) return false;
      return true;
    } catch (e, st) {
      if (!_isCurrentScope(epoch)) return false;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'The kiosk could not be paired.',
      );
      notifyListeners();
      return false;
    }
  }
}
