import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/data/sql_connect_platform_users_remote_data_source.dart';

import '../../helpers/fake_data_gateway.dart';

Map<String, dynamic> _admin() => {
  'id': 'm1',
  'authUid': 'u1',
  'fullName': 'Priya',
  'username': 'priya',
  'email': 'priya@example.com',
  'phone': '+911111111111',
  'role': 'platformAdmin',
  'status': 'active',
  'createdAt': '2026-02-02T10:00:00.000Z',
};

void main() {
  late FakeDataGateway gateway;
  late SqlConnectPlatformUsersRemoteDataSource source;

  setUp(() {
    gateway = FakeDataGateway();
    source = SqlConnectPlatformUsersRemoteDataSource(gateway: gateway);
  });

  test('listPage omits unset filters and maps admins', () async {
    gateway.respond('ListPlatformMembersPaged', {
      'organizationMembers': [_admin()],
      'total': [
        {'_count': 3},
      ],
    });

    final page = await source.listPage(limit: 20, offset: 40);

    expect(gateway.singleVarsOf('ListPlatformMembersPaged'), {
      'limit': 20,
      'offset': 40,
    });
    expect(page.total, 3);
    final a = page.items.single;
    expect(a.fullName, 'Priya');
    expect(a.status, AccountStatus.active);
    expect(a.createdAt, DateTime.utc(2026, 2, 2, 10));
  });

  test('count requests one row filtered by status', () async {
    gateway.respond('ListPlatformMembersPaged', {
      'organizationMembers': <dynamic>[],
      'total': [
        {'_count': 5},
      ],
    });

    final n = await source.count(status: AccountStatus.suspended);

    expect(n, 5);
    expect(gateway.singleVarsOf('ListPlatformMembersPaged'), {
      'limit': 1,
      'offset': 0,
      'status': 'suspended',
    });
  });

  test('getById only returns platform administrators', () async {
    gateway.respond('GetMemberById', {'organizationMember': _admin()});
    expect((await source.getById('m1'))!.username, 'priya');
    expect(gateway.singleVarsOf('GetMemberById'), {'id': 'm1'});

    gateway.respond('GetMemberById', {
      'organizationMember': {..._admin(), 'role': 'employee'},
    });
    expect(await source.getById('m2'), isNull);

    gateway.respond('GetMemberById', {'organizationMember': null});
    expect(await source.getById('m3'), isNull);
  });
}
