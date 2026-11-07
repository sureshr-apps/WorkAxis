import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_draft.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/data/sql_connect_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/domain/license_event_parser.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';

import '../../contracts/platform_organizations_contract.dart';
import '../../helpers/fake_callable_functions.dart';
import '../../helpers/fake_organizations_data_source.dart';

void main() {
  runPlatformOrganizationsContract(
    'mock',
    MockPlatformOrganizationsRepository.new,
  );

  runPlatformOrganizationsContract('SQL Connect with fakes', () {
    final source = FakeOrganizationsDataSource();
    return SqlConnectPlatformOrganizationsRepository(
      dataSource: source,
      functions: _statusFunctions(source, FakeCallableFunctions()),
    );
  });

  group('SqlConnectPlatformOrganizationsRepository specifics', () {
    late FakeOrganizationsDataSource source;
    late FakeCallableFunctions functions;
    late SqlConnectPlatformOrganizationsRepository repo;

    setUp(() {
      source = FakeOrganizationsDataSource();
      functions = _statusFunctions(source, FakeCallableFunctions());
      repo = SqlConnectPlatformOrganizationsRepository(
        dataSource: source,
        functions: functions,
      );
    });

    test('status changes use the setOrganizationStatus callable', () async {
      await repo.updateOrganizationStatus(
        'org-acme',
        OrganizationStatus.suspended,
      );
      expect(functions.payloadsOf('setOrganizationStatus').single, {
        'organizationId': 'org-acme',
        'status': 'suspended',
      });
    });

    test('a partially applied suspension is reported, not hidden', () async {
      functions.handlers['setOrganizationStatus'] = (p) async => {
        'organizationId': p['organizationId'],
        'status': p['status'],
        'membersUpdated': 3,
        'membersFailed': 2,
      };
      await expectLater(
        repo.updateOrganizationStatus('org-acme', OrganizationStatus.suspended),
        throwsA(
          isA<AppException>().having(
            (e) => e.userMessage,
            'userMessage',
            contains('2 member accounts'),
          ),
        ),
      );
    });

    test('generates an unguessable organization code, never an id', () async {
      final a = await repo.createOrganization(
        const CreateOrganizationRequest(name: 'A'),
      );
      final b = await repo.createOrganization(
        const CreateOrganizationRequest(name: 'B'),
      );
      expect(a.code, matches(RegExp(r'^ORG-[A-Z2-9]{6}$')));
      expect(a.code, isNot(b.code));
      expect(a.id, startsWith('srv-org-'));
    });

    test('update does not send the status field', () async {
      final existing = (await repo.getOrganizationById('org-acme'))!;
      await repo.updateOrganization(existing);
      expect(functions.calls, isEmpty);
      expect(source.updates, hasLength(1));
    });

    test(
      'admin management uses the account callables with the org id',
      () async {
        await repo.createOrganizationAdmin(
          'org-acme',
          const OrganizationAdminDraft(
            name: 'Nina Rao',
            username: 'nina.rao',
            phone: '+91 98765 43210',
            initialPassword: 'password1',
          ),
        );
        final payload = functions.payloadsOf('provisionUser').single;
        expect(payload['role'], 'orgAdmin');
        expect(payload['organizationId'], 'org-acme');
        expect(payload['phone'], '+919876543210');
        expect(payload.containsKey('email'), isFalse);
        expect(payload['requestId'], isNotEmpty);
      },
    );

    test('an admin without a sign-in identity cannot be changed', () async {
      source.addAdminWithoutIdentity('org-acme');
      await expectLater(
        repo.setOrganizationAdminStatus(
          'org-acme',
          'orphan',
          OrganizationAdminStatus.suspended,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
    test('backend failures do not leak raw text', () async {
      final repoWithFailure = SqlConnectPlatformOrganizationsRepository(
        dataSource: _ThrowingSource(),
        functions: functions,
      );
      await expectLater(
        repoWithFailure.getOrganizationById('x'),
        throwsA(
          isA<AppException>().having(
            (e) => e.userMessage,
            'userMessage',
            isNot(contains('10.0.0.5')),
          ),
        ),
      );
    });
  });

  group('LicenseEventParser', () {
    test('parses level and validity period', () {
      expect(LicenseEventParser.level('Level 2'), 2);
      expect(LicenseEventParser.level('Gold'), isNull);
      final period = LicenseEventParser.period('2026-11-07 to 2027-11-07')!;
      expect(period.start, DateTime(2026, 11, 7));
      expect(period.end, DateTime(2027, 11, 7));
      expect(LicenseEventParser.period('1 Year'), isNull);
    });
  });
}

FakeCallableFunctions _statusFunctions(
  FakeOrganizationsDataSource source,
  FakeCallableFunctions functions,
) {
  functions.handlers['setOrganizationStatus'] = (payload) async {
    source.setStatus(
      payload['organizationId'] as String,
      OrganizationStatus.fromString(payload['status'] as String),
    );
    return {
      'organizationId': payload['organizationId'],
      'status': payload['status'],
      'membersUpdated': 0,
      'membersFailed': 0,
    };
  };
  functions.handlers['provisionUser'] = (p) async {
    final id = source.addAdmin(
      p['organizationId'] as String,
      name: p['fullName'] as String,
      username: p['username'] as String,
      email: p['email'] as String? ?? '',
      phone: p['phone'] as String? ?? '',
    );
    return {'uid': 'uid-$id', 'memberId': id, 'username': p['username']};
  };
  functions.handlers['updateUserAccount'] = (p) async {
    source.changeAdmin(
      p['targetUid'] as String,
      name: p['fullName'] as String?,
      email: p['email'] as String?,
      phone: p.containsKey('phone') ? (p['phone'] as String? ?? '') : null,
    );
    return {'uid': p['targetUid']};
  };
  functions.handlers['setUserStatus'] = (p) async {
    source.changeAdmin(
      p['targetUid'] as String,
      status: p['status'] == 'active'
          ? OrganizationAdminStatus.active
          : OrganizationAdminStatus.suspended,
    );
    return {'uid': p['targetUid']};
  };
  functions.handlers['resetUserPassword'] = (p) async => {
    'uid': p['targetUid'],
  };
  return functions;
}

class _ThrowingSource extends FakeOrganizationsDataSource {
  @override
  Future<Never> getById(String id) => throw StateError('host=10.0.0.5');
}
