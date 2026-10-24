import 'package:flutter/foundation.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/domain/repositories/branch_management_repository.dart';

class BranchManagementController extends ChangeNotifier {
  BranchManagementController({required this.repository});

  final BranchManagementRepository repository;
  List<BranchRecord> _branches = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _actionErrorMessage;
  KioskPairingToken? _pairingToken;
  List<BranchManagerOption> _managerOptions = const [];

  List<BranchRecord> get branches => _branches;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  KioskPairingToken? get pairingToken => _pairingToken;
  List<BranchManagerOption> get managerOptions => _managerOptions;

  Future<void> loadBranches(UserAccessContext access) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _branches = await repository.getBranches(access);
    } catch (_) {
      _errorMessage = 'Could not load branch settings. Try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BranchRecord?> getBranch(UserAccessContext access, String id) async {
    try {
      return await repository.getBranch(access, id);
    } catch (_) {
      _actionErrorMessage = 'This branch could not be loaded.';
      notifyListeners();
      return null;
    }
  }

  Future<void> loadManagerOptions(UserAccessContext access) async {
    try {
      _managerOptions = await repository.getBranchManagers(access);
      notifyListeners();
    } catch (_) {
      _actionErrorMessage = 'Branch manager options could not be loaded.';
      notifyListeners();
    }
  }

  Future<BranchRecord?> saveBranch({
    required UserAccessContext access,
    required BranchRecord branch,
  }) async {
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final saved = await repository.saveBranch(access: access, branch: branch);
      await loadBranches(access);
      return saved;
    } catch (_) {
      _actionErrorMessage =
          'The branch could not be saved. Check its details and try again.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<KioskPairingToken?> createPairingToken({
    required UserAccessContext access,
    required String branchId,
  }) async {
    _isSaving = true;
    _actionErrorMessage = null;
    _pairingToken = null;
    notifyListeners();
    try {
      _pairingToken = await repository.createKioskPairingToken(
        access: access,
        branchId: branchId,
      );
      await loadBranches(access);
      return _pairingToken;
    } catch (_) {
      _actionErrorMessage = 'A pairing code could not be generated.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> completePairing({
    required UserAccessContext access,
    required String branchId,
  }) async {
    try {
      await repository.completeKioskPairing(access: access, branchId: branchId);
      await loadBranches(access);
      return true;
    } catch (_) {
      _actionErrorMessage = 'The kiosk could not be paired.';
      notifyListeners();
      return false;
    }
  }
}
