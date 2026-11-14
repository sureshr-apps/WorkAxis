import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/access/data/access_remote_data_source.dart';
import 'package:workaxis/features/access/domain/models/access_member_record.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// [AccessRemoteDataSource] backed by Firebase SQL Connect.
class SqlConnectAccessRemoteDataSource implements AccessRemoteDataSource {
  SqlConnectAccessRemoteDataSource({WorkaxisConnectorConnector? connector})
    : _customConnector = connector;

  final WorkaxisConnectorConnector? _customConnector;
  WorkaxisConnectorConnector get _connector =>
      _customConnector ?? WorkaxisConnectorConnector.instance;

  @override
  Future<AccessMemberRecord?> fetchMyMember() async {
    final result = await _connector.getMyMember().execute();
    final member = result.data.organizationMembers.firstOrNull;
    if (member == null) return null;
    final org = member.organization;
    return AccessMemberRecord(
      memberId: member.id,
      authUid: member.authUid,
      role: UserRole.values.where((r) => r.name == member.role).firstOrNull,
      status: AccountStatus.values
          .where((s) => s.name == member.status)
          .firstOrNull,
      organization: org == null
          ? null
          : OrganizationSummary(
              id: org.id,
              name: org.name,
              code: org.code,
              isActive: org.status == 'active',
            ),
    );
  }

  @override
  Future<List<BranchSummary>> fetchMyAssignedBranches() async {
    final result = await _connector.listMyBranchAssignments().execute();
    return result.data.userBranchAssignments
        .map((a) => a.branch)
        .map(
          (b) => BranchSummary(
            id: b.id,
            organizationId: b.organization.id,
            name: b.name,
            code: b.code,
            location: b.location ?? '',
            latitude: b.latitude,
            longitude: b.longitude,
            geofenceRadiusMeters: b.geofenceRadiusMeters,
            isActive: b.status == 'active',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<BranchSummary>> fetchOrganizationBranches(
    String organizationId,
  ) async {
    final result = await _connector
        .listBranchesByOrg(orgId: organizationId)
        .execute();
    return result.data.branches
        .map(
          (b) => BranchSummary(
            id: b.id,
            organizationId: organizationId,
            name: b.name,
            code: b.code,
            location: b.location ?? '',
            latitude: b.latitude,
            longitude: b.longitude,
            geofenceRadiusMeters: b.geofenceRadiusMeters,
            isActive: b.status == 'active',
          ),
        )
        .toList(growable: false);
  }
}
