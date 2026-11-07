import 'package:workaxis/features/branches/domain/models/branch_record.dart';

/// Remote branch reads and field writes. Thin seam over SQL Connect so the
/// repository can be unit-tested with a fake. Manager assignments and kiosk
/// pairing are not here: they use account callables.
abstract interface class BranchesRemoteDataSource {
  Future<List<BranchRecord>> listByOrganization(String organizationId);

  /// Null when the branch does not exist or is not visible to the caller.
  Future<BranchRecord?> getById(String id);

  /// Inserts the branch (server assigns the id) and returns that id.
  Future<String> add(BranchRecord branch, {required String organizationId});

  Future<void> update(BranchRecord branch);
}
