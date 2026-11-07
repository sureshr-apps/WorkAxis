import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/backend/account_callables.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/platform_users/data/mock_platform_users_repository.dart';
import 'package:workaxis/features/platform_users/data/sql_connect_platform_users_repository.dart';

import '../../contracts/platform_users_contract.dart';
import '../../helpers/fake_identity_server.dart';

OrganizationMember _admin(
  String id,
  String name,
  String username, {
  AccountStatus status = AccountStatus.active,
}) => OrganizationMember(
  id: id,
  authUid: id,
  organizationId: '',
  fullName: name,
  username: username,
  email: '$username@workaxis.example',
  role: UserRole.platformAdmin,
  branchIds: const [],
  status: status,
);

FakeIdentityServer _seededServer() => FakeIdentityServer([
  _admin('pa-david-warner', 'David Warner', 'dwarner'),
  _admin('pa-elena-lindqvist', 'Elena Lindqvist', 'elindqvist'),
  _admin('pa-marcus-sterling', 'Marcus Sterling', 'msterling'),
  _admin(
    'pa-devendra-patel',
    'Devendra Patel',
    'dpatel',
    status: AccountStatus.suspended,
  ),
  // A customer user must never appear in the platform administrator list.
  OrganizationMember(
    id: 'cust-1',
    authUid: 'cust-1',
    organizationId: 'org-acme',
    fullName: 'Customer Person',
    username: 'customer.person',
    email: 'c@example.com',
    role: UserRole.employee,
    branchIds: const ['br-01'],
    status: AccountStatus.active,
  ),
]);

SqlConnectPlatformUsersRepository _repo(FakeIdentityServer server) =>
    SqlConnectPlatformUsersRepository(
      dataSource: FakePlatformUsersDataSource(server),
      accounts: AccountCallables(server),
    );

void main() {
  runPlatformUsersContract('mock', MockPlatformUsersRepository.new);
  runPlatformUsersContract(
    'SQL Connect with fakes',
    () => _repo(_seededServer()),
  );

  group('SqlConnectPlatformUsersRepository specifics', () {
    late FakeIdentityServer server;
    late SqlConnectPlatformUsersRepository repo;

    setUp(() {
      server = _seededServer();
      repo = _repo(server);
    });

    test(
      'create provisions a platformAdmin through the callable only',
      () async {
        await repo.createAdministrator(
          administrator: adminDraft(email: 'n@workaxis.example'),
          initialPassword: 'Str0ng-Pass!',
        );
        final payload = server.callsTo('provisionUser').single.payload;
        expect(payload['role'], 'platformAdmin');
        expect(payload.containsKey('organizationId'), isFalse);
        expect(payload['requestId'], hasLength(36));
        expect(payload['password'], 'Str0ng-Pass!');
      },
    );

    test('a retried create reuses its idempotency key', () async {
      server.failNextCallWith = const NetworkException();
      await expectLater(
        repo.createAdministrator(
          administrator: adminDraft(username: 'retry.admin'),
          initialPassword: 'Str0ng-Pass!',
        ),
        throwsA(isA<NetworkException>()),
      );
      await repo.createAdministrator(
        administrator: adminDraft(username: 'retry.admin'),
        initialPassword: 'Str0ng-Pass!',
      );
      expect(
        server
            .callsTo('provisionUser')
            .map((c) => c.payload['requestId'])
            .toSet(),
        hasLength(1),
      );
    });

    test(
      'customer members are not visible as platform administrators',
      () async {
        expect(await repo.getAdministratorById('cust-1'), isNull);
        expect((await repo.getAdministratorsPage()).total, 4);
      },
    );

    test('status changes use setUserStatus with the auth uid', () async {
      await repo.updateAdministratorStatus(
        'pa-david-warner',
        AccountStatus.suspended,
      );
      expect(server.callsTo('setUserStatus').single.payload, {
        'targetUid': 'pa-david-warner',
        'status': 'suspended',
      });
    });
  });
}
