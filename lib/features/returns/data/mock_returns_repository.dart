import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/returns/data/mock_returns_data_source.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';
import 'package:workaxis/features/returns/domain/services/returns_scope.dart';

/// In-memory [ReturnsRepository] enforcing the same scoping as production
/// (via [ReturnsScope]) so tests exercise the real access rules.
class MockReturnsRepository implements ReturnsRepository {
  MockReturnsRepository({
    MockReturnsDataSource? dataSource,
    this._scope = const ReturnsScope(),
    Now? now,
    this.delay = const Duration(milliseconds: 50),
  }) : _now = now ?? systemNow,
       _dataSource = dataSource ?? MockReturnsDataSource(now: now);

  final MockReturnsDataSource _dataSource;
  final ReturnsScope _scope;
  final Now _now;
  final Duration delay;
  int _created = 0;

  Future<void> _latency() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<List<ReturnItem>> getReturns({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnStatus? statusFilter,
  }) async {
    final scope = _scope.forRead(access, activeBranchId);
    await _latency();
    final orgId = access.organization!.id;
    final branchIds = scope.branches.map((b) => b.id).toSet();

    return _dataSource.returns
        .where((r) {
          if (r.organizationId != orgId) return false;
          if (scope.ownOnly) return r.employeeId == access.user.id;
          return branchIds.contains(r.branchId);
        })
        .where((r) => statusFilter == null || r.status == statusFilter)
        .toList();
  }

  @override
  Future<ReturnItem> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  }) async {
    final branch = _scope.forSubmit(access, branchId);
    await _latency();
    final remarks = input.remarks?.trim();
    final item = ReturnItem(
      id: 'RET-NEW-${++_created}',
      organizationId: access.organization!.id,
      branchId: branch.id,
      branchName: branch.name,
      employeeId: access.user.id,
      employeeName: access.user.name,
      productTitle: input.productTitle,
      reason: input.reason,
      quantity: input.quantity,
      unit: input.unit,
      invoiceNumber: input.invoiceNumber,
      returnDate: _now(),
      status: ReturnStatus.pending,
      billImageUrl: input.billImageUrl,
      remarks: remarks == null || remarks.isEmpty ? null : remarks,
    );
    _dataSource.addReturn(item);
    return item;
  }

  @override
  Future<ReturnItem> reviewReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required ReturnItem returnItem,
    required ReturnStatus decision,
    String? reviewerNotes,
  }) async {
    _scope.forReview(access, activeBranchId, returnItem);
    if (decision == ReturnStatus.pending) {
      throw const DatabaseException(
        'Review decision must be approved or rejected.',
      );
    }
    await _latency();
    final stored = _dataSource.returns
        .where((r) => r.id == returnItem.id)
        .firstOrNull;
    if (stored == null || stored.organizationId != access.organization!.id) {
      throw const NotFoundException('Return not found.');
    }
    if (stored.status != ReturnStatus.pending) {
      throw const DatabaseException(
        'Return already reviewed.',
        userMessage: 'This return has already been reviewed.',
      );
    }
    return _dataSource.updateStatus(
      returnId: stored.id,
      status: decision,
      reviewerNotes: reviewerNotes?.trim(),
      reviewerName: access.user.name,
    );
  }
}
