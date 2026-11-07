import 'dart:math';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';

/// Production implementation of [ReturnsRepository] using Firebase SQL Connect.
class SqlConnectReturnsRepository implements ReturnsRepository {
  SqlConnectReturnsRepository({
    WorkaxisConnectorConnector? connector,
  }) : _customConnector = connector;

  final WorkaxisConnectorConnector? _customConnector;
  WorkaxisConnectorConnector get _connector =>
      _customConnector ?? WorkaxisConnectorConnector.instance;

  final Random _random = Random();

  @override
  Future<List<ReturnItem>> getReturns({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnStatus? statusFilter,
  }) async {
    final effectiveBranchId = activeBranchId ??
        access.activeBranch?.branchId ??
        (access.assignedBranches.isNotEmpty ? access.assignedBranches.first.id : '');

    if (effectiveBranchId.isEmpty) {
      return const [];
    }

    try {
      final response =
          await _connector.listReturnsByBranch(branchId: effectiveBranchId).execute();

      var items = response.data.returnRecords
          .map((r) => _toReturnItem(access, effectiveBranchId, r))
          .toList();

      if (access.user.role == UserRole.employee) {
        items = items.where((r) => r.employeeId == access.user.id).toList();
      }

      if (statusFilter != null) {
        items = items.where((r) => r.status == statusFilter).toList();
      }

      return items;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to retrieve returns: ${e.toString()}');
    }
  }

  @override
  Future<ReturnItem> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  }) async {
    final effectiveBranch = branchId ??
        access.activeBranch?.branchId ??
        (access.assignedBranches.isNotEmpty ? access.assignedBranches.first.id : 'br-main');

    final orgId = access.organization?.id ?? 'org-default';
    final id = 'RET-${_random.nextInt(900000) + 100000}';

    try {
      await _connector
          .createReturnRecord(
            id: id,
            orgId: orgId,
            branchId: effectiveBranch,
            employeeId: access.user.id,
            employeeName: access.user.name,
            customerName: input.productTitle,
            invoiceNumber: input.invoiceNumber,
            returnReason: input.reason.name,
            amount: input.quantity,
          )
          .execute();

      return ReturnItem(
        id: id,
        organizationId: orgId,
        branchId: effectiveBranch,
        branchName: access.assignedBranches
                .where((b) => b.id == effectiveBranch)
                .map((b) => b.name)
                .firstOrNull ??
            (access.assignedBranches.isNotEmpty
                ? access.assignedBranches.first.name
                : 'Branch'),
        employeeId: access.user.id,
        employeeName: access.user.name,
        productTitle: input.productTitle,
        reason: input.reason,
        quantity: input.quantity,
        unit: input.unit,
        invoiceNumber: input.invoiceNumber,
        returnDate: DateTime.now(),
        status: ReturnStatus.pending,
        remarks: input.remarks,
        billImageUrl: input.billImageUrl,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to submit return: ${e.toString()}');
    }
  }

  @override
  Future<ReturnItem> reviewReturn({
    required String returnId,
    required ReturnStatus decision,
    required String reviewerNotes,
    required String reviewerName,
  }) async {
    try {
      await _connector
          .updateReturnRecordStatus(id: returnId, status: decision.name)
          .execute();

      return ReturnItem(
        id: returnId,
        organizationId: '',
        branchId: '',
        branchName: '',
        employeeId: '',
        employeeName: '',
        productTitle: 'Product Return',
        reason: ReturnReason.damaged,
        quantity: 1,
        unit: 'pcs',
        invoiceNumber: '',
        returnDate: DateTime.now(),
        status: decision,
        reviewerNotes: reviewerNotes,
        reviewedBy: reviewerName,
        reviewedAt: DateTime.now(),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to review return: ${e.toString()}');
    }
  }

  ReturnItem _toReturnItem(
    UserAccessContext access,
    String branchId,
    ListReturnsByBranchReturnRecords r,
  ) {
    final status = ReturnStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == r.status.toLowerCase(),
      orElse: () => ReturnStatus.pending,
    );
    final reason = ReturnReason.values.firstWhere(
      (re) => re.name.toLowerCase() == r.returnReason.toLowerCase(),
      orElse: () => ReturnReason.other,
    );

    final branchName = access.assignedBranches
        .where((b) => b.id == branchId)
        .map((b) => b.name)
        .firstOrNull ?? 'Branch';

    return ReturnItem(
      id: r.id,
      organizationId: access.organization?.id ?? '',
      branchId: branchId,
      branchName: branchName,
      employeeId: r.employeeId,
      employeeName: r.employeeName,
      productTitle: r.customerName,
      reason: reason,
      quantity: r.amount,
      unit: 'items',
      invoiceNumber: r.invoiceNumber,
      returnDate: r.createdAt.toDateTime(),
      status: status,
    );
  }
}
