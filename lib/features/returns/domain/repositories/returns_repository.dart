import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

abstract interface class ReturnsRepository {
  Future<List<ReturnItem>> getReturns({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnStatus? statusFilter,
  });

  Future<ReturnItem> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  });

  Future<ReturnItem> reviewReturn({
    required String returnId,
    required ReturnStatus decision,
    required String reviewerNotes,
    required String reviewerName,
  });
}
