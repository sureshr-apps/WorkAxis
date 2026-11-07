import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/data/data_connect_returns_remote.dart';
import 'package:workaxis/features/returns/data/returns_remote.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';
import 'package:workaxis/features/returns/domain/services/returns_scope.dart';

/// Production [ReturnsRepository] using Firebase SQL Connect.
///
/// Employees use `ListMyReturns`, managers `ListReturnsByBranchPaged` for the
/// active branch, and Organization Admins `ListReturnsByOrgPaged` (one query
/// for the whole organization, optionally narrowed to a branch).
class SqlConnectReturnsRepository implements ReturnsRepository {
  SqlConnectReturnsRepository({
    WorkaxisConnectorConnector? connector,
    ReturnsRemote? remote,
    this._scope = const ReturnsScope(),
    Now? now,
  }) : _remote = remote ?? DataConnectReturnsRemote(connector: connector),
       _now = now ?? systemNow;

  /// Rows fetched per query.
  static const int pageSize = 100;

  final ReturnsRemote _remote;
  final ReturnsScope _scope;
  final Now _now;

  @override
  Future<List<ReturnItem>> getReturns({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnStatus? statusFilter,
  }) async {
    try {
      final scope = _scope.forRead(access, activeBranchId);
      final orgId = access.organization!.id;

      if (scope.ownOnly) {
        return await _remote.listMine(
          organizationId: orgId,
          employeeUid: access.user.id,
          limit: pageSize,
          status: statusFilter,
        );
      }

      if (access.user.role == UserRole.orgAdmin) {
        return await _remote.listByOrganization(
          organizationId: orgId,
          limit: pageSize,
          branchId: scope.branches.length == 1 && activeBranchId != null
              ? scope.branches.single.id
              : null,
          status: statusFilter,
        );
      }

      final perBranch = await Future.wait(
        scope.branches.map(
          (branch) => _remote.listByBranch(
            organizationId: orgId,
            branch: branch,
            limit: pageSize,
            status: statusFilter,
          ),
        ),
      );
      return [for (final rows in perBranch) ...rows]
        ..sort((a, b) => b.returnDate.compareTo(a.returnDate));
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<ReturnItem> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  }) async {
    try {
      final branch = _scope.forSubmit(access, branchId);
      final id = await _remote.submit(branchId: branch.id, input: input);
      final remarks = input.remarks?.trim();
      return ReturnItem(
        id: id,
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
        // Display value until the next load returns the server timestamp.
        returnDate: _now(),
        status: ReturnStatus.pending,
        billImageUrl: input.billImageUrl,
        remarks: remarks == null || remarks.isEmpty ? null : remarks,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<ReturnItem> reviewReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required ReturnItem returnItem,
    required ReturnStatus decision,
    String? reviewerNotes,
  }) async {
    try {
      final branch = _scope.forReview(access, activeBranchId, returnItem);
      if (decision == ReturnStatus.pending) {
        throw const DatabaseException(
          'Review decision must be approved or rejected.',
        );
      }
      if (returnItem.status != ReturnStatus.pending) {
        throw const DatabaseException(
          'Return already reviewed.',
          userMessage: 'This return has already been reviewed.',
        );
      }

      await _remote.review(
        returnId: returnItem.id,
        decision: decision,
        reviewerNotes: reviewerNotes,
      );

      // Re-read so reviewer name and review time are the server's values.
      final refreshed = await _remote.listByBranch(
        organizationId: access.organization!.id,
        branch: branch,
        limit: pageSize,
      );
      final updated = refreshed.where((r) => r.id == returnItem.id).firstOrNull;
      // The decision is already saved; if the row fell outside the first page,
      // reflect it locally rather than reporting a failure.
      return updated ??
          returnItem.copyWith(
            status: decision,
            reviewerNotes: reviewerNotes,
            reviewedBy: access.user.name,
          );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }
}
