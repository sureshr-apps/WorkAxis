import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/idempotent_creates.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/returns/data/returns_remote.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/models/return_status_counts.dart';

/// [ReturnsRemote] backed by the data gateway (`ListMyReturns`,
/// `ListReturnsByBranchPaged`, `ListReturnsByOrgPaged`,
/// `GetReturnStatusCounts`, `GetReturnById`, `SubmitReturnBatch`,
/// `UpdateReturnRecordReview`).
class DataConnectReturnsRemote implements ReturnsRemote {
  DataConnectReturnsRemote({required this._gateway, IdempotentCreates? creates})
    : _creates = creates ?? IdempotentCreates();

  final DataGateway _gateway;
  final IdempotentCreates _creates;

  @override
  Future<PageResult<ReturnItem>> listMine({
    required String organizationId,
    required String employeeUid,
    required int limit,
    int offset = 0,
    ReturnStatus? status,
    String? query,
  }) async {
    final data = await _gateway.call(
      'ListMyReturns',
      _listVars(limit: limit, offset: offset, status: status, query: query),
    );
    return _page(
      data,
      offset,
      (r) => mapMyReturn(
        r,
        organizationId: organizationId,
        employeeUid: employeeUid,
      ),
    );
  }

  @override
  Future<PageResult<ReturnItem>> listByBranch({
    required String organizationId,
    required BranchSummary branch,
    required int limit,
    int offset = 0,
    ReturnQueue? queue,
    ReturnStatus? status,
    String? query,
  }) async {
    final data = await _gateway.call('ListReturnsByBranchPaged', {
      'branchId': branch.id,
      'submitter': ?queue?.name,
      ..._listVars(limit: limit, offset: offset, status: status, query: query),
    });
    return _page(
      data,
      offset,
      (r) => mapBranchReturn(r, organizationId: organizationId, branch: branch),
    );
  }

  @override
  Future<PageResult<ReturnItem>> listByOrganization({
    required String organizationId,
    required int limit,
    int offset = 0,
    String? branchId,
    ReturnStatus? status,
    String? query,
  }) async {
    final data = await _gateway.call('ListReturnsByOrgPaged', {
      'orgId': organizationId,
      'branchId': ?branchId,
      ..._listVars(limit: limit, offset: offset, status: status, query: query),
    });
    return _page(
      data,
      offset,
      (r) => mapOrganizationReturn(r, organizationId: organizationId),
    );
  }

  @override
  Future<ReturnStatusCounts> countMine() => _counts({'scope': 'mine'});

  @override
  Future<ReturnStatusCounts> countByBranch({
    required String branchId,
    ReturnQueue? queue,
  }) => _counts({
    'scope': 'branch',
    'branchId': branchId,
    'submitter': ?queue?.name,
  });

  @override
  Future<ReturnStatusCounts> countByOrganization({
    required String organizationId,
    String? branchId,
  }) => _counts({
    'scope': 'organization',
    'orgId': organizationId,
    'branchId': ?branchId,
  });

  @override
  Future<ReturnItem?> getById({
    required String organizationId,
    required String returnId,
  }) async {
    final data = await _gateway.call('GetReturnById', {'id': returnId});
    final row = data.optObject('returnRecord');
    return row == null
        ? null
        : mapOrganizationReturn(row, organizationId: organizationId);
  }

  Future<ReturnStatusCounts> _counts(Map<String, dynamic> vars) async {
    final data = await _gateway.call('GetReturnStatusCounts', vars);
    final counts = data.object('counts');
    return ReturnStatusCounts(
      pending: counts.optInt('pending') ?? 0,
      approved: counts.optInt('approved') ?? 0,
      rejected: counts.optInt('rejected') ?? 0,
    );
  }

  /// Paging and filter variables; optional ones are omitted, never null.
  static Map<String, dynamic> _listVars({
    required int limit,
    required int offset,
    ReturnStatus? status,
    String? query,
  }) {
    final text = query?.trim();
    return {
      'limit': limit,
      'offset': offset,
      'status': ?status?.name,
      if (text != null && text.isNotEmpty) 'query': text,
    };
  }

  static PageResult<ReturnItem> _page(
    Map<String, dynamic> data,
    int offset,
    ReturnItem Function(Map<String, dynamic> row) map,
  ) => PageResult(
    items: [for (final r in data.objects('returnRecords')) map(r)],
    total: data.countOf('total'),
    offset: offset,
  );

  @override
  Future<List<String>> submitBatch({
    required String branchId,
    required CreateReturnBatchInput input,
  }) async {
    final billImageUrl = input.billImageUrl;
    final billNumber = input.billNumber?.trim();
    final returnDate = input.returnDate;
    final vars = {
      'branchId': branchId,
      'invoiceNumber': input.invoiceNumber,
      // Optional variables must be omitted, never sent as null.
      if (billNumber != null && billNumber.isNotEmpty) 'billNumber': billNumber,
      // The picked calendar date is the business date (Asia/Kolkata).
      if (returnDate != null) 'returnDate': BusinessTime.keyOfDate(returnDate),
      if (billImageUrl != null && billImageUrl.isNotEmpty)
        'billImageUrl': billImageUrl,
      'items': [
        for (final line in input.toCreateReturnInputs()) _lineVars(line),
      ],
    };
    // A retried bill reuses its requestId, so it is never saved twice.
    final data = await _creates.run(
      'SubmitReturnBatch',
      vars,
      (withId) => _gateway.call('SubmitReturnBatch', withId),
    );
    return [
      for (final row in data.objects('returnRecord_inserts')) row.string('id'),
    ];
  }

  static Map<String, Object> _lineVars(CreateReturnInput line) {
    final remarks = line.remarks?.trim();
    return {
      'productTitle': line.productTitle,
      'returnReason': line.reason.name,
      'quantity': line.quantity,
      'unit': line.unit,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    };
  }

  @override
  Future<void> update({
    required String returnId,
    required CreateReturnInput input,
  }) async {
    final billImageUrl = input.billImageUrl;
    final remarks = input.remarks?.trim();
    final data = await _gateway.call('UpdateReturnRecord', {
      'id': returnId,
      'productTitle': input.productTitle.trim(),
      'quantity': input.quantity,
      'unit': input.unit,
      'invoiceNumber': input.invoiceNumber.trim(),
      'returnReason': input.reason.name,
      if (billImageUrl != null && billImageUrl.isNotEmpty)
        'billImageUrl': billImageUrl,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    });
    if (data.optObject('returnRecord_update') == null) {
      throw const NotFoundException('Return not found.');
    }
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
      submittedByUid: employeeUid,
      productTitle: r.optString('productTitle') ?? 'Return $invoiceNumber',
      reason: ReturnReason.parse(r.string('returnReason')),
      quantity: r.optNumber('quantity') ?? 0,
      unit: r.optString('unit') ?? '',
      billNumber: r.optString('billNumber'),
      invoiceNumber: invoiceNumber,
      returnDate: _returnDate(r),
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
      submittedByUid: r.optString('employeeUid'),
      productTitle: r.optString('productTitle') ?? r.string('customerName'),
      reason: ReturnReason.parse(r.string('returnReason')),
      quantity: r.optNumber('quantity') ?? r.number('amount'),
      unit: r.optString('unit') ?? '',
      billNumber: r.optString('billNumber'),
      invoiceNumber: r.string('invoiceNumber'),
      returnDate: _returnDate(r),
      status: _status(r.string('status')),
      billImageUrl: r.optString('billImageUrl'),
      remarks: r.optString('remarks'),
      reviewerNotes: r.optString('reviewerNotes'),
      reviewedAt: r.optDateTime('reviewedAt'),
      reviewedBy: r.optString('reviewerName'),
    );
  }

  /// The business return date; rows saved before it was captured fall back
  /// to their creation time.
  static DateTime _returnDate(Map<String, dynamic> r) =>
      r.optDateOnly('returnDate') ?? r.dateTime('createdAt');

  static ReturnStatus _status(String raw) {
    final parsed = ReturnStatus.tryParse(raw);
    if (parsed == null) {
      throw DatabaseException('Unknown return status "$raw".');
    }
    return parsed;
  }
}
