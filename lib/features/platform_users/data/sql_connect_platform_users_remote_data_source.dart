import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/data/platform_users_remote_data_source.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';

/// [PlatformUsersRemoteDataSource] backed by Firebase SQL Connect
/// (`ListPlatformMembersPaged`, `GetMemberById`). SQL is authoritative for
/// platform administrators; the Firestore profile is only a projection.
class SqlConnectPlatformUsersRemoteDataSource
    implements PlatformUsersRemoteDataSource {
  SqlConnectPlatformUsersRemoteDataSource({
    WorkaxisConnectorConnector? connector,
  }) : _customConnector = connector;

  final WorkaxisConnectorConnector? _customConnector;
  WorkaxisConnectorConnector get _connector =>
      _customConnector ?? WorkaxisConnectorConnector.instance;

  @override
  Future<PageResult<PlatformAdministrator>> listPage({
    required int limit,
    required int offset,
    String? nameContains,
    AccountStatus? status,
  }) async {
    final data = (await _builder(
      limit: limit,
      offset: offset,
      nameContains: nameContains,
      status: status,
    ).execute()).data;
    return PageResult(
      items: [
        for (final m in data.organizationMembers)
          PlatformAdministrator(
            id: m.id,
            authUid: m.authUid,
            fullName: m.fullName,
            username: m.username,
            email: LoginEmail.displayable(m.email),
            phone: m.phone,
            status: _status(m.status),
            createdAt: m.createdAt.toDateTime(),
          ),
      ],
      total: data.total.firstOrNull?.count_ ?? 0,
      offset: offset,
    );
  }

  @override
  Future<int> count({AccountStatus? status}) async {
    final data = (await _builder(
      limit: 1,
      offset: 0,
      status: status,
    ).execute()).data;
    return data.total.firstOrNull?.count_ ?? 0;
  }

  @override
  Future<PlatformAdministrator?> getById(String id) async {
    final m = (await _connector.getMemberById(id: id).execute())
        .data
        .organizationMember;
    if (m == null || m.role != 'platformAdmin') return null;
    return PlatformAdministrator(
      id: m.id,
      authUid: m.authUid,
      fullName: m.fullName,
      username: m.username,
      email: LoginEmail.displayable(m.email),
      phone: m.phone,
      status: _status(m.status),
      createdAt: m.createdAt.toDateTime(),
    );
  }

  ListPlatformMembersPagedVariablesBuilder _builder({
    required int limit,
    required int offset,
    String? nameContains,
    AccountStatus? status,
  }) {
    var builder = _connector.listPlatformMembersPaged(
      limit: limit,
      offset: offset,
    );
    if (nameContains != null && nameContains.trim().isNotEmpty) {
      builder = builder.nameContains(nameContains.trim());
    }
    if (status != null) builder = builder.status(status.name);
    return builder;
  }

  /// Unknown statuses map to suspended (fail closed).
  AccountStatus _status(String value) =>
      AccountStatus.values.where((s) => s.name == value).firstOrNull ??
      AccountStatus.suspended;
}
