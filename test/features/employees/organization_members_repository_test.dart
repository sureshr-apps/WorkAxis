import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/backend/account_callables.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/data/sql_connect_organization_members_repository.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

import '../../contracts/acme_scenario.dart';
import '../../contracts/organization_members_contract.dart';
import '../../helpers/fake_identity_server.dart';

void main() {
  runOrganizationMembersContract(
    'mock',
    () => MockOrganizationMembersRepository(
      accessDataSource: MockAccessDataSource(),
    ),
  );

  runOrganizationMembersContract('SQL Connect with fakes', () {
    final server = FakeIdentityServer(acmeMemberSeed());
    return SqlConnectOrganizationMembersRepository(
      dataSource: FakeMembersDataSource(server),
      accounts: AccountCallables(server),
    );
  });

  group('SqlConnectOrganizationMembersRepository specifics', () {
    late FakeIdentityServer server;
    late SqlConnectOrganizationMembersRepository repo;

    setUp(() {
      server = FakeIdentityServer(acmeMemberSeed());
      repo = SqlConnectOrganizationMembersRepository(
        dataSource: FakeMembersDataSource(server),
        accounts: AccountCallables(server),
      );
    });

    test('create goes through provisionUser with an idempotency key', () async {
      await repo.saveMember(
        access: orgAdminAccess(),
        member: memberDraft(email: 'new@example.com', phone: '+91 98765 43210'),
        initialPassword: 'Str0ng-Pass!',
      );
      final call = server.callsTo('provisionUser').single;
      expect(call.payload['requestId'], hasLength(36));
      expect(call.payload['role'], 'employee');
      expect(call.payload['organizationId'], 'org-acme');
      expect(call.payload['phone'], '+919876543210');
      expect(call.payload['branchIds'], ['br-02']);
    });

    test('a retried create reuses the same requestId', () async {
      server.failNextCallWith = const NetworkException();
      final draft = memberDraft(username: 'retry.me');
      await expectLater(
        repo.saveMember(
          access: orgAdminAccess(),
          member: draft,
          initialPassword: 'Str0ng-Pass!',
        ),
        throwsA(isA<NetworkException>()),
      );
      await repo.saveMember(
        access: orgAdminAccess(),
        member: draft,
        initialPassword: 'Str0ng-Pass!',
      );
      final ids = server
          .callsTo('provisionUser')
          .map((c) => c.payload['requestId'])
          .toSet();
      expect(ids, hasLength(1));
      expect(server.all.where((m) => m.username == 'retry.me'), hasLength(1));
    });

    test('update sends only the changed fields and never the role', () async {
      final existing = server.byId('user-emp-02')!;
      await repo.saveMember(
        access: orgAdminAccess(),
        member: existing.copyWith(fullName: 'Alexandra Chen'),
        initialPassword: '',
      );
      final payload = server.callsTo('updateUserAccount').single.payload;
      expect(payload['targetUid'], 'user-emp-02');
      expect(payload['fullName'], 'Alexandra Chen');
      expect(payload.containsKey('role'), isFalse);
      expect(payload.containsKey('branchIds'), isFalse);
      expect(payload.containsKey('email'), isFalse);
      expect(payload.containsKey('phone'), isFalse);
    });

    test('clearing the phone sends an explicit null', () async {
      final existing = server.byId('user-emp-02')!;
      await repo.saveMember(
        access: orgAdminAccess(),
        member: existing.copyWith(clearPhone: true),
        initialPassword: '',
      );
      final payload = server.callsTo('updateUserAccount').single.payload;
      expect(payload.containsKey('phone'), isTrue);
      expect(payload['phone'], isNull);
    });

    test('policy violations never reach the server', () async {
      await expectLater(
        repo.saveMember(
          access: orgAdminAccess(),
          member: memberDraft(role: UserRole.platformOwner),
          initialPassword: 'Str0ng-Pass!',
        ),
        throwsA(isA<AppException>()),
      );
      expect(server.calls, isEmpty);
    });

    test('synthetic login emails are never displayed', () async {
      final created = await repo.saveMember(
        access: orgAdminAccess(),
        member: memberDraft(username: 'quiet.user'),
        initialPassword: 'Str0ng-Pass!',
      );
      expect(created.email, isEmpty);
      final page = await repo.getMembersPage(access: orgAdminAccess());
      expect(page.items.every((m) => !m.email.endsWith('.invalid')), isTrue);
    });

    test('backend failures surface as typed errors without raw text', () async {
      final source = FakeMembersDataSource(server)
        ..failWith = StateError('host=10.0.0.5 password=hunter2');
      final failing = SqlConnectOrganizationMembersRepository(
        dataSource: source,
        accounts: AccountCallables(server),
      );
      await expectLater(
        failing.getMembersPage(access: orgAdminAccess()),
        throwsA(
          isA<AppException>().having(
            (e) => e.userMessage,
            'userMessage',
            isNot(contains('hunter2')),
          ),
        ),
      );
    });

    test('accounts without a sign-in identity cannot be changed', () async {
      final orphan = server.byId('user-emp-02')!;
      final repoWithOrphan = SqlConnectOrganizationMembersRepository(
        dataSource: _OrphanSource(server, 'user-emp-02'),
        accounts: AccountCallables(server),
      );
      await expectLater(
        repoWithOrphan.saveMember(
          access: orgAdminAccess(),
          member: orphan.copyWith(fullName: 'X Y'),
          initialPassword: '',
        ),
        throwsA(isA<AppException>()),
      );
      expect(server.calls, isEmpty);
    });

    test(
      'profile fields including dailyWorkHours hydrate from Firestore',
      () async {
        final fakeFirestore = FakeFirebaseFirestore();
        await fakeFirestore.collection('users').doc('user-emp-02').set({
          'dailyWorkHours': 9.0,
          'shiftHours': '9:00 AM - 6:00 PM',
          'employeeCode': 'EMP-OLD',
          'dateOfBirth': '1995-05-15',
          'gender': 'Male',
          'address': '123 Test St, Bangalore',
          'profilePhotoUrl': 'https://example.com/avatar.jpg',
          'designation': 'Senior Branch Manager',
          'joiningDate': '2023-01-10',
          'relievingDate': '2025-12-31',
          'assetDetails': 'MacBook Pro M3',
        });
        await fakeFirestore
            .collection('employee_private')
            .doc('user-emp-02')
            .set({
              'organizationId': 'org-acme',
              'salary': 75000.0,
              'aadhaarNumber': '123456789012',
              'aadhaarPhotoUrl': 'https://example.com/aadhaar.jpg',
            });

        final repoWithFirestore = SqlConnectOrganizationMembersRepository(
          dataSource: FakeMembersDataSource(server),
          accounts: AccountCallables(server),
          firestore: fakeFirestore,
        );

        final member = await repoWithFirestore.getMember(
          access: orgAdminAccess(),
          memberId: 'user-emp-02',
        );

        expect(member, isNotNull);
        expect(member!.dailyWorkHours, 9.0);
        expect(member.shiftHours, '9:00 AM - 6:00 PM');
        // SQL is authoritative: the stale Firestore value must not override it.
        expect(member.employeeCode, server.byId('user-emp-02')!.employeeCode);
        expect(member.employeeCode, isNot('EMP-OLD'));
        expect(member.aadhaarNumber, '123456789012');
        expect(member.aadhaarPhotoUrl, 'https://example.com/aadhaar.jpg');
        expect(member.dateOfBirth, DateTime(1995, 5, 15));
        expect(member.gender, 'Male');
        expect(member.address, '123 Test St, Bangalore');
        expect(member.profilePhotoUrl, 'https://example.com/avatar.jpg');
        expect(member.designation, 'Senior Branch Manager');
        expect(member.joiningDate, DateTime(2023, 1, 10));
        expect(member.relievingDate, DateTime(2025, 12, 31));
        expect(member.salary, 75000.0);
        expect(member.assetDetails, 'MacBook Pro M3');

        // Test page enrichment as well (which runs on refresh)
        final page = await repoWithFirestore.getMembersPage(
          access: orgAdminAccess(),
        );
        final enrichedInPage = page.items.firstWhere(
          (m) => m.id == 'user-emp-02',
        );
        expect(enrichedInPage.dailyWorkHours, 9.0);
        expect(enrichedInPage.designation, 'Senior Branch Manager');
        expect(enrichedInPage.salary, 75000.0);
      },
    );

    test(
      'a denied employee_private read leaves salary and Aadhaar null',
      () async {
        final fakeFirestore = _DenyPrivateFirestore();
        await fakeFirestore.collection('users').doc('user-emp-02').set({
          'designation': 'Cashier',
          // Legacy docs may still carry the values; they are never read from here.
          'salary': 1.0,
          'aadhaarNumber': '999999999999',
        });
        final managerRepo = SqlConnectOrganizationMembersRepository(
          dataSource: FakeMembersDataSource(server),
          accounts: AccountCallables(server),
          firestore: fakeFirestore,
        );

        final member = await managerRepo.getMember(
          access: orgAdminAccess(),
          memberId: 'user-emp-02',
        );
        expect(member!.designation, 'Cashier');
        expect(member.salary, isNull);
        expect(member.aadhaarNumber, isNull);
        expect(member.aadhaarPhotoUrl, isNull);

        final page = await managerRepo.getMembersPage(access: orgAdminAccess());
        final listed = page.items.firstWhere((m) => m.id == 'user-emp-02');
        expect(listed.designation, 'Cashier');
        expect(listed.salary, isNull);
      },
    );

    test('editing without private access sends no salary or Aadhaar', () async {
      final managerRepo = SqlConnectOrganizationMembersRepository(
        dataSource: FakeMembersDataSource(server),
        accounts: AccountCallables(server),
        firestore: _DenyPrivateFirestore(),
      );
      final loaded = await managerRepo.getMember(
        access: orgAdminAccess(),
        memberId: 'user-emp-02',
      );
      await managerRepo.saveMember(
        access: orgAdminAccess(),
        member: loaded!.copyWith(fullName: 'Renamed'),
        initialPassword: '',
      );
      final payload = server.callsTo('updateUserAccount').single.payload;
      expect(payload.containsKey('salary'), isFalse);
      expect(payload.containsKey('aadhaarNumber'), isFalse);
      expect(payload.containsKey('aadhaarPhotoUrl'), isFalse);
      expect(payload.containsKey('employeeCode'), isFalse);
    });

    test(
      'create without an employee ID carries the server-assigned one',
      () async {
        final saved = await repo.saveMember(
          access: orgAdminAccess(),
          member: memberDraft(email: 'auto@example.com'),
          initialPassword: 'Str0ng-Pass!',
        );
        final payload = server.callsTo('provisionUser').single.payload;
        expect(payload.containsKey('employeeCode'), isFalse);
        expect(saved.employeeCode, startsWith('EMP-'));
        expect(saved.employeeCode, isNot('EMP-10001'));
      },
    );

    test('falls back gracefully to defaults when Firestore document does not exist', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final repoWithFirestore = SqlConnectOrganizationMembersRepository(
        dataSource: FakeMembersDataSource(server),
        accounts: AccountCallables(server),
        firestore: fakeFirestore,
      );

      final member = await repoWithFirestore.getMember(
        access: orgAdminAccess(),
        memberId: 'user-emp-02',
      );

      expect(member, isNotNull);
      expect(member!.dailyWorkHours, 8.0);
    });
  });
}

/// Firestore whose `employee_private` reads are rejected, like a Branch Manager.
class _DenyPrivateFirestore extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path == 'employee_private') {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    return super.collection(path);
  }
}

/// Returns [orphanId] without an auth uid, like a seed row never provisioned.
class _OrphanSource extends FakeMembersDataSource {
  _OrphanSource(super.server, this.orphanId);

  final String orphanId;

  @override
  Future<OrganizationMember?> getById(String memberId) async {
    final m = await super.getById(memberId);
    if (m == null || memberId != orphanId) return m;
    return OrganizationMember(
      id: m.id,
      organizationId: m.organizationId,
      fullName: m.fullName,
      username: m.username,
      email: m.email,
      phone: m.phone,
      role: m.role,
      branchIds: m.branchIds,
      status: m.status,
    );
  }
}
