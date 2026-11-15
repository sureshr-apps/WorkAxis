import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/features/access/data/access_remote_data_source.dart';
import 'package:workaxis/features/access/domain/models/access_member_record.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// [AccessRemoteDataSource] backed by the data gateway
/// (`GetMyMember`, `ListMyBranchAssignments`, `ListBranchesByOrg`).
class SqlConnectAccessRemoteDataSource implements AccessRemoteDataSource {
  SqlConnectAccessRemoteDataSource({required this._gateway});

  final DataGateway _gateway;

  @override
  Future<AccessMemberRecord?> fetchMyMember() async {
    final data = await _gateway.call('GetMyMember');
    final member = data.objects('organizationMembers').firstOrNull;
    if (member == null) return null;
    final org = member.optObject('organization');
    final role = member.string('role');
    final status = member.string('status');
    return AccessMemberRecord(
      memberId: member.string('id'),
      authUid: member.optString('authUid'),
      role: UserRole.values.where((r) => r.name == role).firstOrNull,
      status: AccountStatus.values.where((s) => s.name == status).firstOrNull,
      organization: org == null
          ? null
          : OrganizationSummary(
              id: org.string('id'),
              name: org.string('name'),
              code: org.string('code'),
              isActive: org.string('status') == 'active',
            ),
    );
  }

  @override
  Future<List<BranchSummary>> fetchMyAssignedBranches() async {
    final data = await _gateway.call('ListMyBranchAssignments');
    return [
      for (final assignment in data.objects('userBranchAssignments'))
        _summary(assignment.object('branch')),
    ];
  }

  @override
  Future<List<BranchSummary>> fetchOrganizationBranches(
    String organizationId,
  ) async {
    final data = await _gateway.call('ListBranchesByOrg', {
      'orgId': organizationId,
    });
    return [
      for (final branch in data.objects('branches'))
        _summary(branch, organizationId: organizationId),
    ];
  }

  BranchSummary _summary(Map<String, dynamic> b, {String? organizationId}) {
    return BranchSummary(
      id: b.string('id'),
      organizationId: organizationId ?? b.object('organization').string('id'),
      name: b.string('name'),
      code: b.string('code'),
      location: b.optString('location') ?? '',
      latitude: b.optNumber('latitude'),
      longitude: b.optNumber('longitude'),
      geofenceRadiusMeters: b.optInt('geofenceRadiusMeters'),
      isActive: b.string('status') == 'active',
    );
  }
}
