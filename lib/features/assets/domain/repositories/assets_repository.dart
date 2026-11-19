import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';

/// Read and manage assets assigned to employees.
///
/// Implementations enforce role and branch scope. UI visibility is not the
/// authorization boundary.
abstract interface class AssetsRepository {
  Future<List<EmployeeAsset>> getAssets({
    required UserAccessContext access,
    String? activeBranchId,
  });

  Future<EmployeeAsset> saveAsset({
    required UserAccessContext access,
    required EmployeeAsset asset,
    String? activeBranchId,
  });

  Future<void> deleteAsset({
    required UserAccessContext access,
    required String assetId,
    String? activeBranchId,
  });
}
