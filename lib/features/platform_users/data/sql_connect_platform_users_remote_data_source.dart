import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/data/platform_users_remote_data_source.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';

/// [PlatformUsersRemoteDataSource] backed by the data gateway
/// (`ListPlatformMembersPaged`, `GetMemberById`). SQL is authoritative for
/// platform administrators; the Firestore profile is only a projection.
class SqlConnectPlatformUsersRemoteDataSource
    implements PlatformUsersRemoteDataSource {
  SqlConnectPlatformUsersRemoteDataSource({required this._gateway});

  final DataGateway _gateway;

  @override
  Future<PageResult<PlatformAdministrator>> listPage({
    required int limit,
    required int offset,
    String? nameContains,
    AccountStatus? status,
  }) async {
    final data = await _list(
      limit: limit,
      offset: offset,
      nameContains: nameContains,
      status: status,
    );
    return PageResult(
      items: [for (final m in data.objects('organizationMembers')) _admin(m)],
      total: data.countOf('total'),
      offset: offset,
    );
  }

  @override
  Future<int> count({AccountStatus? status}) async {
    final data = await _list(limit: 1, offset: 0, status: status);
    return data.countOf('total');
  }

  @override
  Future<PlatformAdministrator?> getById(String id) async {
    final data = await _gateway.call('GetMemberById', {'id': id});
    final m = data.optObject('organizationMember');
    if (m == null || m.string('role') != 'platformAdmin') return null;
    return _admin(m);
  }

  Future<Map<String, dynamic>> _list({
    required int limit,
    required int offset,
    String? nameContains,
    AccountStatus? status,
  }) {
    return _gateway.call('ListPlatformMembersPaged', {
      'limit': limit,
      'offset': offset,
      // Unset optional variables are omitted, never sent as null.
      if (nameContains != null && nameContains.trim().isNotEmpty)
        'nameContains': nameContains.trim(),
      'status': ?status?.name,
    });
  }

  PlatformAdministrator _admin(Map<String, dynamic> m) {
    return PlatformAdministrator(
      id: m.string('id'),
      authUid: m.optString('authUid'),
      fullName: m.string('fullName'),
      username: m.string('username'),
      email: LoginEmail.displayable(m.string('email')),
      phone: m.optString('phone'),
      status: _status(m.string('status')),
      createdAt: m.dateTime('createdAt'),
    );
  }

  /// Unknown statuses map to suspended (fail closed).
  AccountStatus _status(String value) =>
      AccountStatus.values.where((s) => s.name == value).firstOrNull ??
      AccountStatus.suspended;
}
