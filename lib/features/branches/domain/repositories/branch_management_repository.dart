import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';

abstract interface class BranchManagementRepository {
  Future<List<BranchRecord>> getBranches(UserAccessContext access);
  Future<BranchRecord?> getBranch(UserAccessContext access, String id);
  Future<List<BranchManagerOption>> getBranchManagers(UserAccessContext access);
  Future<BranchRecord> saveBranch({
    required UserAccessContext access,
    required BranchRecord branch,
  });
  Future<KioskPairingToken> createKioskPairingToken({
    required UserAccessContext access,
    required String branchId,
  });
  Future<void> completeKioskPairing({
    required UserAccessContext access,
    required String branchId,
  });
}
