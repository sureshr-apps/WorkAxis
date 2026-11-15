import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/returns/data/returns_remote.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

/// [ReturnsRemote] backed by the data gateway (`ListMyReturns`,
/// `ListReturnsByBranchPaged`, `ListReturnsByOrgPaged`, `SubmitReturn`,
/// `UpdateReturnRecordReview`).
class DataConnectReturnsRemote implements ReturnsRemote {
  DataConnectReturnsRemote({required this._gateway});

  final DataGateway _gateway;

  @override
  Future<List<ReturnItem>> listMine({
    required String organizationId,
    required String employeeUid,
    required int limit,
    int offset = 0,
    ReturnStatus? status,
  }) async {
    final data = await _gateway.call('ListMyReturns', {
      'limit': limit,
      'offset': offset,
      // Optional variables must be omitted, never sent as null.
      'status': ?status?.name,
    });
    return [
      for (final r in data.objects('returnRecords'))
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
    final data = await _gateway.call('ListReturnsByBranchPaged', {
      'branchId': branch.id,
      'limit': limit,
      'offset': offset,
      'status': ?status?.name,
    });
    return [
      for (final r in data.objects('returnRecords'))
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
    final data = await _gateway.call('ListReturnsByOrgPaged', {
      'orgId': organizationId,
      'limit': limit,
      'offset': offset,
      'branchId': ?branchId,
      'status': ?status?.name,
    });
    return [
      for (final r in data.objects('returnRecords'))
        mapOrganizationReturn(r, organizationId: organizationId),
    ];
  }

  @override
  Future<String> submit({
    required String branchId,
    required CreateReturnInput input,
  }) async {
    final billImageUrl = input.billImageUrl;
    final remarks = input.remarks?.trim();
    final data = await _gateway.call('SubmitReturn', {
      'branchId': branchId,
      'productTitle': input.productTitle,
      'returnReason': input.reason.name,
      'quantity': input.quantity,
      'unit': input.unit,
      'invoiceNumber': input.invoiceNumber,
      // Optional variables must be omitted, never sent as null.
      if (billImageUrl != null && billImageUrl.isNotEmpty)
        'billImageUrl': billImageUrl,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    });
    return data.object('returnRecord_insert').string('id');
  }

  @override
  Future<void> review({
    required String returnId,
    required ReturnStatus decision,
    String? reviewerNotes,
  }) async {
    final notes = reviewerNotes?.trim();
    final data = await _gateway.call('UpdateReturnRecordReview', {
      'id': returnId,
      'status': decision.name,
      if (notes != null && notes.isNotEmpty) 'reviewerNotes': notes,
    });
    if (data.optObject('returnRecord_update') == null) {
      throw const NotFoundException('Return not found.');
    }
  }

  /// Maps a `ListMyReturns` row. The caller's uid is the submitter.
  static ReturnItem mapMyReturn(
    Map<String, dynamic> r, {
    required String organizationId,
    required String employeeUid,
  }) {
    final branch = r.object('branch');
    final invoiceNumber = r.string('invoiceNumber');
    return ReturnItem(
      id: r.string('id'),
      organizationId: organizationId,
      branchId: branch.string('id'),
      branchName: branch.string('name'),
      employeeId: employeeUid,
      employeeName: r.string('employeeName'),
      productTitle: r.optString('productTitle') ?? 'Return $invoiceNumber',
      reason: ReturnReason.parse(r.string('returnReason')),
      quantity: r.optNumber('quantity') ?? 0,
      unit: r.optString('unit') ?? '',
      invoiceNumber: invoiceNumber,
      returnDate: r.dateTime('createdAt'),
      status: _status(r.string('status')),
      billImageUrl: r.optString('billImageUrl'),
      remarks: r.optString('remarks'),
      reviewerNotes: r.optString('reviewerNotes'),
      reviewedAt: r.optDateTime('reviewedAt'),
      reviewedBy: r.optString('reviewerName'),
    );
  }

  /// Maps a `ListReturnsByBranchPaged` row. Legacy rows only have
  /// `customerName` (product title) and `amount` (quantity).
  static ReturnItem mapBranchReturn(
    Map<String, dynamic> r, {
    required String organizationId,
    required BranchSummary branch,
  }) {
    return _mapManagedReturn(
      r,
      organizationId: organizationId,
      branchId: branch.id,
      branchName: branch.name,
    );
  }

  /// Maps a `ListReturnsByOrgPaged` row (same legacy fallbacks as
  /// [mapBranchReturn]; the branch comes from the row).
  static ReturnItem mapOrganizationReturn(
    Map<String, dynamic> r, {
    required String organizationId,
  }) {
    final branch = r.object('branch');
    return _mapManagedReturn(
      r,
      organizationId: organizationId,
      branchId: branch.string('id'),
      branchName: branch.string('name'),
    );
  }

  static ReturnItem _mapManagedReturn(
    Map<String, dynamic> r, {
    required String organizationId,
    required String branchId,
    required String branchName,
  }) {
    return ReturnItem(
      id: r.string('id'),
      organizationId: organizationId,
      branchId: branchId,
      branchName: branchName,
      employeeId: r.optString('employeeUid') ?? r.string('employeeId'),
      employeeName: r.string('employeeName'),
      productTitle: r.optString('productTitle') ?? r.string('customerName'),
      reason: ReturnReason.parse(r.string('returnReason')),
      quantity: r.optNumber('quantity') ?? r.number('amount'),
      unit: r.optString('unit') ?? '',
      invoiceNumber: r.string('invoiceNumber'),
      returnDate: r.dateTime('createdAt'),
      status: _status(r.string('status')),
      billImageUrl: r.optString('billImageUrl'),
      remarks: r.optString('remarks'),
      reviewerNotes: r.optString('reviewerNotes'),
      reviewedAt: r.optDateTime('reviewedAt'),
      reviewedBy: r.optString('reviewerName'),
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
