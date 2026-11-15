import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';
import 'package:workaxis/core/storage/attachment_uploader.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/data/data_connect_returns_remote.dart';
import 'package:workaxis/features/returns/data/returns_remote.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
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

  /// Rows fetched per query.
  static const int pageSize = 100;

  final ReturnsRemote _remote;
  final ReturnsScope _scope;
  final Now _now;

  /// Uploads the bill photo before a return is saved. Null skips uploading.
  final AttachmentUploader? _attachments;

  @override
  Future<List<ReturnItem>> getReturns({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnStatus? statusFilter,
  }) async {
    try {
      final scope = _scope.forRead(access, activeBranchId);
      final orgId = access.organization!.id;

      final all = <ReturnItem>[];
      var offset = 0;
      while (true) {
        final List<ReturnItem> page;
        if (scope.ownOnly) {
          page = await _remote.listMine(
            organizationId: orgId,
            employeeUid: access.user.id,
            limit: pageSize,
            offset: offset,
            status: statusFilter,
          );
        } else if (access.user.role == UserRole.orgAdmin) {
          page = await _remote.listByOrganization(
            organizationId: orgId,
            limit: pageSize,
            offset: offset,
            branchId: activeBranchId,
            status: statusFilter,
          );
        } else {
          page = await _remote.listByBranch(
            organizationId: orgId,
            branch: scope.branches.single,
            limit: pageSize,
            offset: offset,
            status: statusFilter,
          );
        }
        all.addAll(page);
        if (page.length < pageSize) break;
        offset += page.length;
      }
      return all..sort((a, b) => b.returnDate.compareTo(a.returnDate));
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
      final createdList = <ReturnItem>[];
      for (final line in input.items) {
        final combinedRemarks = [
          if (input.remarks != null && input.remarks!.trim().isNotEmpty)
            input.remarks!.trim(),
          if (line.remarks != null && line.remarks!.trim().isNotEmpty)
            line.remarks!.trim(),
        ].join(' - ');
        final singleInput = CreateReturnInput(
          branchId: branch.id,
          branchName: branch.name,
          billNumber: input.billNumber,
          invoiceNumber: input.invoiceNumber,
          returnDate: input.returnDate,
          productTitle: line.productTitle,
          quantity: line.quantity,
          unit: line.unit,
          reason: line.reason,
          billImageUrl: billImage,
          remarks: combinedRemarks.isEmpty ? null : combinedRemarks,
        );
        final id = await _remote.submit(
          branchId: branch.id,
          input: singleInput,
        );
        createdList.add(
          ReturnItem(
            id: id,
            organizationId: access.organization!.id,
            branchId: branch.id,
            branchName: branch.name,
            employeeId: access.user.id,
            employeeName: access.user.name,
            productTitle: line.productTitle,
            reason: line.reason,
            quantity: line.quantity,
            unit: line.unit,
            billNumber: input.billNumber,
            invoiceNumber: input.invoiceNumber,
            // Display value until the next load returns the server timestamp.
            returnDate: input.returnDate ?? _now(),
            status: ReturnStatus.pending,
            billImageUrl: billImage,
            remarks: singleInput.remarks,
          ),
        );
      }
      return createdList;
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
