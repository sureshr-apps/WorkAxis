import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/assets/domain/models/asset_queue.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Search, ordering, and queue-membership rules of the asset listings.
///
/// Mirrors the server listings (`List*EmployeeAssets`) so the mock backend
/// and in-place list updates after a save agree with what a reload returns.
abstract final class AssetListingPolicy {
  /// Case-insensitive substring match on asset name, category, tag, serial
  /// number, holder name, and branch name. A blank [query] matches all.
  static bool matchesQuery(EmployeeAsset asset, String? query) {
    final needle = query?.trim().toLowerCase() ?? '';
    if (needle.isEmpty) return true;
    return [
      asset.name,
      asset.category,
      asset.assetTag,
      asset.serialNumber ?? '',
      asset.employeeName,
      asset.branchName,
    ].any((field) => field.toLowerCase().contains(needle));
  }

  /// Listing order: holder name, then asset name, then id.
  static int compare(EmployeeAsset a, EmployeeAsset b) {
    final byHolder = _compareText(a.employeeName, b.employeeName);
    if (byHolder != 0) return byHolder;
    final byName = _compareText(a.name, b.name);
    if (byName != 0) return byName;
    return a.id.compareTo(b.id);
  }

  /// Whether [asset] belongs to [queue] for [access] at [activeBranchId].
  ///
  /// Used for in-place list updates only; the server remains the authority.
  static bool belongsToQueue(
    EmployeeAsset asset,
    AssetQueue queue,
    UserAccessContext access, {
    String? activeBranchId,
  }) {
    final isOwn =
        asset.employeeUid == access.user.id ||
        asset.employeeId == access.user.id;
    final branchId = activeBranchId ?? access.activeBranch?.branchId;
    // Only a Branch Manager's own listing is narrowed to the active branch.
    final isBranchScoped = access.user.role == UserRole.branchManager;
    return switch (queue) {
      AssetQueue.mine =>
        isOwn && (!isBranchScoped || asset.branchId == branchId),
      AssetQueue.branchEmployees => !isOwn && asset.branchId == branchId,
      AssetQueue.organization =>
        asset.organizationId == access.organization?.id,
    };
  }

  static int _compareText(String a, String b) {
    final folded = a.toLowerCase().compareTo(b.toLowerCase());
    return folded != 0 ? folded : a.compareTo(b);
  }
}
