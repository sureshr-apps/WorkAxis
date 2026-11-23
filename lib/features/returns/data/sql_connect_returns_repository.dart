import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';
import 'package:workaxis/core/storage/attachment_uploader.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/data/data_connect_returns_remote.dart';
import 'package:workaxis/features/returns/data/returns_remote.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/models/return_status_counts.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';
import 'package:workaxis/features/returns/domain/services/returns_scope.dart';

/// Production [ReturnsRepository] using the data gateway.
///
/// Employees use `ListMyReturns`, managers `ListReturnsByBranchPaged` for the
/// active branch, and Organization Admins `ListReturnsByOrgPaged` (one query
/// for the whole organization, optionally narrowed to a branch).
class SqlConnectReturnsRepository implements ReturnsRepository {
  SqlConnectReturnsRepository({
    DataGateway? gateway,
    ReturnsRemote? remote,
    this._scope = const ReturnsScope(),
    Now? now,
    this._attachments,
  }) : assert(
         gateway != null || remote != null,
         'Provide a data gateway or a remote.',
       ),
       _remote = remote ?? DataConnectReturnsRemote(gateway: gateway!),
       _now = now ?? systemNow;

  final ReturnsRemote _remote;
  final ReturnsScope _scope;
  final Now _now;

  /// Uploads the bill photo before a return is saved. Null skips uploading.
  final AttachmentUploader? _attachments;

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
    try {
      final scope = _scope.forRead(access, activeBranchId);
      final orgId = access.organization!.id;
      if (scope.ownOnly) {
        return await _remote.listMine(
          organizationId: orgId,
          employeeUid: access.user.id,
          limit: limit,
          offset: offset,
          status: status,
          query: query,
        );
      }
      if (access.user.role == UserRole.orgAdmin) {
        return await _remote.listByOrganization(
          organizationId: orgId,
          limit: limit,
          offset: offset,
          branchId: activeBranchId,
          status: status,
          query: query,
        );
      }
      return await _remote.listByBranch(
        organizationId: orgId,
        branch: scope.branches.single,
        limit: limit,
        offset: offset,
        queue: queue,
        status: status,
        query: query,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<ReturnStatusCounts> getReturnCounts({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnQueue? queue,
  }) async {
    try {
      final scope = _scope.forRead(access, activeBranchId);
      if (scope.ownOnly) return await _remote.countMine();
      if (access.user.role == UserRole.orgAdmin) {
        return await _remote.countByOrganization(
          organizationId: access.organization!.id,
          branchId: activeBranchId,
        );
      }
      return await _remote.countByBranch(
        branchId: scope.branches.single.id,
        queue: queue,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<ReturnItem?> getReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required String returnId,
  }) async {
    try {
      final scope = _scope.forRead(access, activeBranchId);
      final item = await _remote.getById(
        organizationId: access.organization!.id,
        returnId: returnId,
      );
      if (item == null) return null;
      // The server already scoped the row; keep a Branch Manager to the
      // active branch, as the list does.
      if (!scope.ownOnly &&
          access.user.role == UserRole.branchManager &&
          !scope.branches.any((b) => b.id == item.branchId)) {
        return null;
      }
      return item;
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
    try {
      final branch = _scope.forSubmit(access, branchId);
      // Upload the bill photo once for the whole bill, before any line is
      // saved, so no line ever carries a local device path.
      final billImage =
          await _attachments?.ensureStored(
            input.billImageUrl,
            organizationId: access.organization!.id,
            kind: AttachmentKind.returnBill,
          ) ??
          input.billImageUrl;
      final stored = CreateReturnBatchInput(
        branchId: branch.id,
        branchName: branch.name,
        billNumber: input.billNumber,
        invoiceNumber: input.invoiceNumber,
        returnDate: input.returnDate,
        billImageUrl: billImage,
        remarks: input.remarks,
        items: input.items,
      );
      // One call: the server saves every line of the bill or none of them.
      final ids = await _remote.submitBatch(branchId: branch.id, input: stored);
      final lines = stored.toCreateReturnInputs();
      if (ids.length != lines.length) {
        throw const DatabaseException('Return batch response is incomplete.');
      }
      return [
        for (var i = 0; i < lines.length; i++)
          ReturnItem(
            id: ids[i],
            organizationId: access.organization!.id,
            branchId: branch.id,
            branchName: branch.name,
            employeeId: access.user.id,
            employeeName: access.user.name,
            submittedByUid: access.user.id,
            productTitle: lines[i].productTitle,
            reason: lines[i].reason,
            quantity: lines[i].quantity,
            unit: lines[i].unit,
            billNumber: input.billNumber,
            invoiceNumber: input.invoiceNumber,
            // Display value until the next load returns the server value.
            returnDate: input.returnDate ?? _now(),
            status: ReturnStatus.pending,
            billImageUrl: billImage,
            remarks: lines[i].remarks,
          ),
      ];
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<void> updateReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required ReturnItem returnItem,
    required CreateReturnInput input,
  }) async {
    try {
      final branch = _scope.forUpdate(access, activeBranchId, returnItem);
      final billImage =
          await _attachments?.ensureStored(
            input.billImageUrl,
            organizationId: access.organization!.id,
            kind: AttachmentKind.returnBill,
          ) ??
          input.billImageUrl;
      await _remote.update(
        returnId: returnItem.id,
        input: CreateReturnInput(
          invoiceNumber: input.invoiceNumber.trim(),
          productTitle: input.productTitle.trim(),
          quantity: input.quantity,
          unit: input.unit,
          reason: input.reason,
          billImageUrl: billImage,
          remarks: input.remarks?.trim().isEmpty ?? true
              ? null
              : input.remarks?.trim(),
          branchId: branch.id,
          branchName: branch.name,
        ),
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
      final updated = await _remote.getById(
        organizationId: access.organization!.id,
        returnId: returnItem.id,
      );
      // The decision is already saved; if the re-read fails to find the row,
      // reflect it locally rather than reporting a failure.
      return updated?.copyWith(branchName: branch.name) ??
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
