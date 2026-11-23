import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/data/mock_returns_data_source.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/models/return_status_counts.dart';
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
  Future<PageResult<ReturnItem>> getReturnsPage({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnQueue? queue,
    ReturnStatus? status,
    String? query,
    int offset = 0,
    int limit = defaultPageSize,
  }) async {
    final scoped = _inScope(access, activeBranchId, queue);
    await _latency();
    final text = query?.trim().toLowerCase() ?? '';
    final matches =
        scoped
            .where((r) => status == null || r.status == status)
            .where((r) => text.isEmpty || _searchText(r).contains(text))
            .toList()
          // Same order as the server: newest return date first.
          ..sort((a, b) {
            final byDate = b.returnDate.compareTo(a.returnDate);
            return byDate != 0 ? byDate : b.id.compareTo(a.id);
          });
    final start = offset.clamp(0, matches.length);
    final end = (start + limit).clamp(0, matches.length);
    return PageResult(
      items: List.unmodifiable(matches.sublist(start, end)),
      total: matches.length,
      offset: start,
    );
  }

  @override
  Future<ReturnStatusCounts> getReturnCounts({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnQueue? queue,
  }) async {
    final scoped = _inScope(access, activeBranchId, queue);
    await _latency();
    int count(ReturnStatus status) =>
        scoped.where((r) => r.status == status).length;
    return ReturnStatusCounts(
      pending: count(ReturnStatus.pending),
      approved: count(ReturnStatus.approved),
      rejected: count(ReturnStatus.rejected),
    );
  }

  @override
  Future<ReturnItem?> getReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required String returnId,
  }) async {
    final scoped = _inScope(access, activeBranchId, null);
    await _latency();
    return scoped.where((r) => r.id == returnId).firstOrNull;
  }

  /// Returns the caller may read, before status and search filters.
  List<ReturnItem> _inScope(
    UserAccessContext access,
    String? activeBranchId,
    ReturnQueue? queue,
  ) {
    final scope = _scope.forRead(access, activeBranchId);
    final orgId = access.organization!.id;
    final branchIds = scope.branches.map((b) => b.id).toSet();
    final managerQueue = access.user.role == UserRole.branchManager
        ? queue
        : null;
    return _dataSource.returns
        .where((r) {
          if (r.organizationId != orgId) return false;
          if (scope.ownOnly) return r.employeeId == access.user.id;
          return branchIds.contains(r.branchId);
        })
        .where(
          (r) => switch (managerQueue) {
            null => true,
            ReturnQueue.mine => r.wasSubmittedBy(access.user.id),
            ReturnQueue.others => !r.wasSubmittedBy(access.user.id),
          },
        )
        .toList();
  }

  static String _searchText(ReturnItem r) => [
    r.productTitle,
    r.invoiceNumber,
    r.billNumber ?? '',
    r.employeeName,
    r.branchName,
  ].join(' ').toLowerCase();

  @override
  Future<ReturnItem> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  }) async {
    final results = await submitReturnBatch(
      access: access,
      branchId: branchId,
      input: input.toBatch(),
    );
    return results.first;
  }

  @override
  Future<List<ReturnItem>> submitReturnBatch({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnBatchInput input,
  }) async {
    final branch = _scope.forSubmit(access, branchId);
    await _latency();
    final items = <ReturnItem>[];
    for (final line in input.items) {
      final combinedRemarks = [
        if (input.remarks != null && input.remarks!.trim().isNotEmpty)
          input.remarks!.trim(),
        if (line.remarks != null && line.remarks!.trim().isNotEmpty)
          line.remarks!.trim(),
      ].join(' - ');
      final item = ReturnItem(
        id: 'RET-NEW-${++_created}',
        organizationId: access.organization!.id,
        branchId: branch.id,
        branchName: branch.name,
        employeeId: access.user.id,
        employeeName: access.user.name,
        submittedByUid: access.user.id,
        productTitle: line.productTitle,
        reason: line.reason,
        quantity: line.quantity,
        unit: line.unit,
        billNumber: input.billNumber,
        invoiceNumber: input.invoiceNumber,
        returnDate: input.returnDate ?? _now(),
        status: ReturnStatus.pending,
        billImageUrl: input.billImageUrl,
        remarks: combinedRemarks.isEmpty ? null : combinedRemarks,
      );
      _dataSource.addReturn(item);
      items.add(item);
    }
    return items;
  }

  @override
  Future<void> updateReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required ReturnItem returnItem,
    required CreateReturnInput input,
  }) async {
    _scope.forUpdate(access, activeBranchId, returnItem);
    await _latency();
    _dataSource.updateReturn(returnId: returnItem.id, input: input);
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
