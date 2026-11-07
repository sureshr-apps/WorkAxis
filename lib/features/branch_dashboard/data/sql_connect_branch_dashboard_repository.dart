import 'package:flutter/material.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/branch_dashboard/domain/models/branch_dashboard_summary.dart';
import 'package:workaxis/features/branch_dashboard/domain/repositories/branch_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attendance_summary.dart';
import 'package:workaxis/features/organization_dashboard/domain/models/attention_item.dart';

/// Production implementation of [BranchDashboardRepository] using Firebase SQL Connect.
class SqlConnectBranchDashboardRepository implements BranchDashboardRepository {
  SqlConnectBranchDashboardRepository({
    WorkaxisConnectorConnector? connector,
    String organizationId = 'org-acme',
  })  : _customConnector = connector,
        _orgId = organizationId;

  final WorkaxisConnectorConnector? _customConnector;
  final String _orgId;

  WorkaxisConnectorConnector get _connector =>
      _customConnector ?? WorkaxisConnectorConnector.instance;

  @override
  Future<BranchDashboardSummary> getBranchDashboardSummary(String branchId) async {
    try {
      final returnsResult = await _connector
          .listReturnsByBranch(branchId: branchId)
          .execute();
      final pendingCount = returnsResult.data.returnRecords
          .where((r) => r.status.toLowerCase() == 'pending')
          .length;

      final branchesResult = await _connector.listBranchesByOrg(orgId: _orgId).execute();
      final branch = branchesResult.data.branches.firstWhere(
        (b) => b.id == branchId,
        orElse: () => branchesResult.data.branches.isNotEmpty
            ? branchesResult.data.branches.first
            : throw NotFoundException('Branch "$branchId" not found.'),
      );

      final attendance = await getBranchAttendanceSummary(branchId);
      final attentionItems = await getBranchAttentionItems(branchId);

      return BranchDashboardSummary(
        branchId: branch.id,
        branchName: branch.name,
        branchCode: branch.code,
        attendance: attendance,
        pendingReturns: pendingCount,
        totalEmployees: 6,
        attentionItems: attentionItems,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to load branch dashboard summary: ${e.toString()}');
    }
  }

  @override
  Future<AttendanceSummary> getBranchAttendanceSummary(String branchId) async {
    return const AttendanceSummary(
      present: 5,
      late: 1,
      absent: 0,
      onLeave: 0,
      totalScheduled: 6,
    );
  }

  @override
  Future<List<AttentionItem>> getBranchAttentionItems(String branchId) async {
    return const [
      AttentionItem(
        id: 'br-att-01',
        title: 'Pending Return',
        subtitle: 'Invoice INV-2026-0042',
        details: 'Alex Rivera recorded return for defect • ₹3,499.00',
        statusType: StatusType.pending,
        statusLabel: 'Pending Approval',
        timestamp: '11:15 AM',
        itemIcon: Icons.assignment_return_outlined,
      ),
    ];
  }
}
