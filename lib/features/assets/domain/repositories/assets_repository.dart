import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/assets/domain/models/asset_queue.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';

/// Read and manage assets assigned to employees.
///
/// Implementations enforce role and branch scope. UI visibility is not the
/// authorization boundary.
abstract interface class AssetsRepository {
  /// One page of [queue], ordered by holder name, asset name, then id.
  ///
  /// [query] narrows by asset name, category, tag, serial number, holder
  /// name, or branch name (case-insensitive substring). Throws
  /// `AccessDeniedException` when the role may not read [queue], and
  /// `BranchAuthorizationException` when a Branch Manager has no active
  /// branch.
  Future<PageResult<EmployeeAsset>> getAssetsPage({
    required UserAccessContext access,
    required AssetQueue queue,
    String? activeBranchId,
    String? query,
    int offset = 0,
    int limit = defaultPageSize,
  });

  Future<EmployeeAsset> saveAsset({
    required UserAccessContext access,
    required EmployeeAsset asset,
    String? activeBranchId,
  });

  /// Records the signed-in employee's acknowledgment for one assigned asset.
  Future<EmployeeAsset> acknowledgeAsset({
    required UserAccessContext access,
    required String assetId,
  });

  Future<void> deleteAsset({
    required UserAccessContext access,
    required String assetId,
    String? activeBranchId,
  });
}
