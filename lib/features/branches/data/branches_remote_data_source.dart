import 'package:workaxis/features/branches/domain/models/branch_record.dart';

/// Remote branch reads. Thin seam over the data gateway so the repository can
/// be unit-tested with a fake. Every branch write (fields, manager assignments)
/// goes through the `saveBranch` callable and kiosk pairing through its own
/// callable, so none of them are here.
abstract interface class BranchesRemoteDataSource {
  Future<List<BranchRecord>> listByOrganization(String organizationId);

  /// Null when the branch does not exist or is not visible to the caller.
  Future<BranchRecord?> getById(String id);
}
