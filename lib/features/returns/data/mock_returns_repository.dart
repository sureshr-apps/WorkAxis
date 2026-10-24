import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/data/mock_returns_data_source.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';

class MockReturnsRepository implements ReturnsRepository {
  final MockReturnsDataSource _dataSource;

  MockReturnsRepository({MockReturnsDataSource? dataSource})
      : _dataSource = dataSource ?? MockReturnsDataSource();

  @override
  Future<List<ReturnItem>> getReturns({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnStatus? statusFilter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final all = _dataSource.returns;
    final role = access.user.role;

    Iterable<ReturnItem> filtered = all;

    if (role == UserRole.employee) {
      filtered = filtered.where(
        (r) =>
            r.employeeId == access.user.id ||
            r.employeeName == access.user.name ||
            r.employeeId == 'emp-101' ||
            r.employeeName == 'Marcus Vance',
      );
    } else if (role == UserRole.branchManager) {
      if (activeBranchId != null) {
        filtered = filtered.where((r) => r.branchId == activeBranchId);
      }
    } else if (role == UserRole.orgAdmin) {
      filtered = filtered.where(
        (r) => r.organizationId == access.organization?.id || r.organizationId == 'org-freshgrocer',
      );
    }

    if (statusFilter != null) {
      filtered = filtered.where((r) => r.status == statusFilter);
    }

    return filtered.toList();
  }

  @override
  Future<ReturnItem> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final newId = 'RET-00${_dataSource.returns.length + 1}';
    final branchName = access.assignedBranches.firstWhere(
      (b) => b.id == (branchId ?? access.assignedBranches.firstOrNull?.id),
      orElse: () => access.assignedBranches.isNotEmpty ? access.assignedBranches.first : access.assignedBranches.first,
    ).name;

    final item = ReturnItem(
      id: newId,
      organizationId: access.organization?.id ?? 'org-freshgrocer',
      branchId: branchId ?? access.assignedBranches.firstOrNull?.id ?? 'branch-dt-01',
      branchName: branchName,
      employeeId: access.user.id,
      employeeName: access.user.name.isNotEmpty ? access.user.name : 'Marcus Vance',
      productTitle: input.productTitle,
      reason: input.reason,
      quantity: input.quantity,
      unit: input.unit,
      invoiceNumber: input.invoiceNumber,
      returnDate: DateTime.now(),
      status: ReturnStatus.pending,
      billImageUrl: input.billImageUrl,
      remarks: input.remarks,
    );

    _dataSource.addReturn(item);
    return item;
  }

  @override
  Future<ReturnItem> reviewReturn({
    required String returnId,
    required ReturnStatus decision,
    required String reviewerNotes,
    required String reviewerName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _dataSource.updateStatus(
      returnId: returnId,
      status: decision,
      reviewerNotes: reviewerNotes,
      reviewerName: reviewerName,
    );
  }
}
