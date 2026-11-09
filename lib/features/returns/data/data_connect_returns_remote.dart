import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/returns/data/returns_remote.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

/// [ReturnsRemote] backed by the generated SQL Connect SDK.
class DataConnectReturnsRemote implements ReturnsRemote {
  DataConnectReturnsRemote({this._connector});

  final WorkaxisConnectorConnector? _connector;

  WorkaxisConnectorConnector get _c =>
      _connector ?? WorkaxisConnectorConnector.instance;

  @override
  Future<List<ReturnItem>> listMine({
    required String organizationId,
    required String employeeUid,
    required int limit,
    int offset = 0,
    ReturnStatus? status,
  }) async {
    final builder = _c.listMyReturns(limit: limit, offset: offset);
    if (status != null) builder.status(status.name);
    final rows = (await builder.execute()).data.returnRecords;
    return [
      for (final r in rows)
        mapMyReturn(
          r,
          organizationId: organizationId,
          employeeUid: employeeUid,
        ),
    ];
  }

  @override
  Future<List<ReturnItem>> listByBranch({
    required String organizationId,
    required BranchSummary branch,
    required int limit,
    int offset = 0,
    ReturnStatus? status,
  }) async {
    final builder = _c.listReturnsByBranchPaged(
      branchId: branch.id,
      limit: limit,
      offset: offset,
    );
    if (status != null) builder.status(status.name);
    final rows = (await builder.execute()).data.returnRecords;
    return [
      for (final r in rows)
        mapBranchReturn(r, organizationId: organizationId, branch: branch),
    ];
  }

  @override
  Future<List<ReturnItem>> listByOrganization({
    required String organizationId,
    required int limit,
    int offset = 0,
    String? branchId,
    ReturnStatus? status,
  }) async {
    final builder = _c.listReturnsByOrgPaged(
      orgId: organizationId,
      limit: limit,
      offset: offset,
    );
    // Optional variables must be omitted, never sent as null.
    if (branchId != null) builder.branchId(branchId);
    if (status != null) builder.status(status.name);
    final rows = (await builder.execute()).data.returnRecords;
    return [
      for (final r in rows)
        mapOrganizationReturn(r, organizationId: organizationId),
    ];
  }

  @override
  Future<String> submit({
    required String branchId,
    required CreateReturnInput input,
  }) async {
    final builder = _c.submitReturn(
      branchId: branchId,
      productTitle: input.productTitle,
      returnReason: input.reason.name,
      quantity: input.quantity,
      unit: input.unit,
      invoiceNumber: input.invoiceNumber,
    );
    // Optional variables must be omitted, never sent as null.
    final billImageUrl = input.billImageUrl;
    if (billImageUrl != null && billImageUrl.isNotEmpty) {
      builder.billImageUrl(billImageUrl);
    }
    final remarks = input.remarks?.trim();
    if (remarks != null && remarks.isNotEmpty) builder.remarks(remarks);
    final result = await builder.execute();
    return result.data.returnRecord_insert.id;
  }

  @override
  Future<void> review({
    required String returnId,
    required ReturnStatus decision,
    String? reviewerNotes,
  }) async {
    final builder = _c.updateReturnRecordReview(
      id: returnId,
      status: decision.name,
    );
    final notes = reviewerNotes?.trim();
    if (notes != null && notes.isNotEmpty) builder.reviewerNotes(notes);
    final result = await builder.execute();
    if (result.data.returnRecord_update == null) {
      throw const NotFoundException('Return not found.');
    }
  }

  /// Maps a `ListMyReturns` row. The caller's uid is the submitter.
  static ReturnItem mapMyReturn(
    ListMyReturnsReturnRecords r, {
    required String organizationId,
    required String employeeUid,
  }) {
    return ReturnItem(
      id: r.id,
      organizationId: organizationId,
      branchId: r.branch.id,
      branchName: r.branch.name,
      employeeId: employeeUid,
      employeeName: r.employeeName,
      productTitle: r.productTitle ?? 'Return ${r.invoiceNumber}',
      reason: ReturnReason.parse(r.returnReason),
      quantity: r.quantity ?? 0,
      unit: r.unit ?? '',
      invoiceNumber: r.invoiceNumber,
      returnDate: r.createdAt.toDateTime(),
      status: _status(r.status),
      billImageUrl: r.billImageUrl,
      remarks: r.remarks,
      reviewerNotes: r.reviewerNotes,
      reviewedAt: r.reviewedAt?.toDateTime(),
      reviewedBy: r.reviewerName,
    );
  }

  /// Maps a `ListReturnsByBranchPaged` row. Legacy rows only have
  /// `customerName` (product title) and `amount` (quantity).
  static ReturnItem mapBranchReturn(
    ListReturnsByBranchPagedReturnRecords r, {
    required String organizationId,
    required BranchSummary branch,
  }) {
    return ReturnItem(
      id: r.id,
      organizationId: organizationId,
      branchId: branch.id,
      branchName: branch.name,
      employeeId: r.employeeUid ?? r.employeeId,
      employeeName: r.employeeName,
      productTitle: r.productTitle ?? r.customerName,
      reason: ReturnReason.parse(r.returnReason),
      quantity: r.quantity ?? r.amount,
      unit: r.unit ?? '',
      invoiceNumber: r.invoiceNumber,
      returnDate: r.createdAt.toDateTime(),
      status: _status(r.status),
      billImageUrl: r.billImageUrl,
      remarks: r.remarks,
      reviewerNotes: r.reviewerNotes,
      reviewedAt: r.reviewedAt?.toDateTime(),
      reviewedBy: r.reviewerName,
    );
  }

  /// Maps a `ListReturnsByOrgPaged` row (same legacy fallbacks as
  /// [mapBranchReturn]; the branch comes from the row).
  static ReturnItem mapOrganizationReturn(
    ListReturnsByOrgPagedReturnRecords r, {
    required String organizationId,
  }) {
    return ReturnItem(
      id: r.id,
      organizationId: organizationId,
      branchId: r.branch.id,
      branchName: r.branch.name,
      employeeId: r.employeeUid ?? r.employeeId,
      employeeName: r.employeeName,
      productTitle: r.productTitle ?? r.customerName,
      reason: ReturnReason.parse(r.returnReason),
      quantity: r.quantity ?? r.amount,
      unit: r.unit ?? '',
      invoiceNumber: r.invoiceNumber,
      returnDate: r.createdAt.toDateTime(),
      status: _status(r.status),
      billImageUrl: r.billImageUrl,
      remarks: r.remarks,
      reviewerNotes: r.reviewerNotes,
      reviewedAt: r.reviewedAt?.toDateTime(),
      reviewedBy: r.reviewerName,
    );
  }

  static ReturnStatus _status(String raw) {
    final parsed = ReturnStatus.tryParse(raw);
    if (parsed == null) {
      throw DatabaseException('Unknown return status "$raw".');
    }
    return parsed;
  }
}
