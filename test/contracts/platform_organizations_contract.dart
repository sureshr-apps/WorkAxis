import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_draft.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_admin_rules.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';

/// Behaviour every [PlatformOrganizationsRepository] must provide.
void runPlatformOrganizationsContract(
  String label,
  PlatformOrganizationsRepository Function() create,
) {
  group('PlatformOrganizationsRepository contract ($label)', () {
    late PlatformOrganizationsRepository repo;
    setUp(() => repo = create());

    test('getOrganizationById returns the organization or null', () async {
      final org = await repo.getOrganizationById('org-acme');
      expect(org, isNotNull);
      expect(org!.name, 'Acme Corporation');
      expect(await repo.getOrganizationById('missing'), isNull);
    });

    test('pages through every organization with a stable total', () async {
      final seen = <String>[];
      var offset = 0;
      while (true) {
        final page = await repo.getOrganizationsPage(limit: 3, offset: offset);
        expect(page.total, 7);
        seen.addAll(page.items.map((o) => o.id));
        if (!page.hasMore) break;
        offset = page.nextOffset;
      }
      expect(seen.toSet().length, 7);
      expect(seen.length, 7);
    });

    test('filters by status and name', () async {
      final suspended = await repo.getOrganizationsPage(
        statusFilter: OrganizationStatus.suspended,
      );
      expect(suspended.total, 2);
      expect(suspended.items.every((o) => o.status.isSuspended), isTrue);

      final byName = await repo.getOrganizationsPage(query: 'Apex');
      expect(byName.items.single.id, 'org-apex');
    });

    test('status counts cover every organization', () async {
      final counts = await repo.getStatusCounts();
      expect(counts.total, 7);
      expect(counts.suspended, 2);
      expect(counts.active, 5);
    });

    test(
      'create returns what was saved, including every collected field',
      () async {
        final created = await repo.createOrganization(
          const CreateOrganizationRequest(
            name: '  Zenith Retail  ',
            description: 'Retail chain',
            category: 'Retail',
            taxIdentification: 'GSTIN-123',
            contactName: 'Zed Zenith',
            contactEmail: 'zed@zenith.example',
            contactPhone: '+91 98765 43210',
            address: '1 Main Street',
          ),
        );
        expect(created.id, isNotEmpty);
        expect(created.code, isNotEmpty);
        expect(created.name, 'Zenith Retail');
        expect(created.status, OrganizationStatus.active);
        expect(created.description, 'Retail chain');
        expect(created.category, 'Retail');
        expect(created.taxIdentification, 'GSTIN-123');
        expect(created.contactName, 'Zed Zenith');
        expect(created.contactEmail, 'zed@zenith.example');
        expect(created.contactPhone, '+91 98765 43210');
        expect(created.address, '1 Main Street');

        final fetched = await repo.getOrganizationById(created.id);
        expect(fetched?.description, 'Retail chain');
        expect(fetched?.category, 'Retail');
      },
    );

    test('create validates the name and contact email', () async {
      await expectLater(
        repo.createOrganization(const CreateOrganizationRequest(name: '  ')),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repo.createOrganization(
          const CreateOrganizationRequest(name: 'Ok', contactEmail: 'nope'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      'update round-trips description and category without prefixes',
      () async {
        final existing = (await repo.getOrganizationById('org-acme'))!;
        final saved = await repo.updateOrganization(
          existing.copyWith(
            description: 'New description',
            category: 'Logistics',
            contactEmail: 'ops@acme.example',
          ),
        );
        expect(saved.description, 'New description');
        expect(saved.category, 'Logistics');
        expect(saved.contactEmail, 'ops@acme.example');
        // Saving twice must not accumulate any encoding.
        final again = await repo.updateOrganization(saved);
        expect(again.description, 'New description');
        expect(again.category, 'Logistics');
      },
    );

    test('update never changes the status', () async {
      final existing = (await repo.getOrganizationById('org-acme'))!;
      final saved = await repo.updateOrganization(
        existing.copyWith(status: OrganizationStatus.suspended),
      );
      expect(saved.status, OrganizationStatus.active);
    });

    test('suspends and reactivates through the status operation', () async {
      final suspended = await repo.updateOrganizationStatus(
        'org-acme',
        OrganizationStatus.suspended,
      );
      expect(suspended.status, OrganizationStatus.suspended);
      expect((await repo.getStatusCounts()).suspended, 3);

      final restored = await repo.updateOrganizationStatus(
        'org-acme',
        OrganizationStatus.active,
      );
      expect(restored.status, OrganizationStatus.active);
    });

    test('license details exist for licensed organizations only', () async {
      final license = await repo.getOrganizationLicenseDetails('org-acme');
      expect(license, isNotNull);
      expect(license!.history, isNotEmpty);
      expect(await repo.getOrganizationLicenseDetails('org-crestline'), isNull);
    });

    group('administrators', () {
      const draft = OrganizationAdminDraft(
        name: 'Nina Rao',
        username: 'nina.rao',
        initialPassword: 'password1',
      );

      test(
        'create adds an admin with a server id; email and phone optional',
        () async {
          final before = (await repo.getOrganizationById('org-acme'))!;
          final org = await repo.createOrganizationAdmin('org-acme', draft);
          expect(org.admins.length, before.admins.length + 1);
          final added = org.admins.firstWhere((a) => a.username == 'nina.rao');
          expect(added.id, isNotEmpty);
          expect(added.email, isEmpty);
          expect(added.phone, isEmpty);
          expect(added.status, OrganizationAdminStatus.active);
        },
      );

      test('create reports one error per invalid field', () async {
        await expectLater(
          repo.createOrganizationAdmin(
            'org-acme',
            const OrganizationAdminDraft(
              name: '',
              username: 'x',
              email: 'nope',
              phone: '12',
              initialPassword: 'short',
            ),
          ),
          throwsA(
            isA<OrganizationAdminValidationException>().having(
              (e) => e.fieldErrors.keys.toSet(),
              'fields',
              {'name', 'username', 'email', 'phone', 'password'},
            ),
          ),
        );
      });

      test('update changes contact details and can clear the phone', () async {
        final created = await repo.createOrganizationAdmin(
          'org-acme',
          const OrganizationAdminDraft(
            name: 'Nina Rao',
            username: 'nina.rao',
            phone: '+919876543210',
            initialPassword: 'password1',
          ),
        );
        final admin = created.admins.firstWhere(
          (a) => a.username == 'nina.rao',
        );
        final renamed = await repo.updateOrganizationAdmin(
          'org-acme',
          admin.copyWith(name: 'Nina R. Rao', email: 'nina@acme.test'),
        );
        final after = renamed.admins.firstWhere((a) => a.id == admin.id);
        expect(after.name, 'Nina R. Rao');
        expect(after.email, 'nina@acme.test');

        final cleared = await repo.updateOrganizationAdmin(
          'org-acme',
          OrganizationAdminUser(
            id: after.id,
            name: after.name,
            username: after.username,
            email: after.email,
            phone: '',
            authUid: after.authUid,
          ),
        );
        expect(cleared.admins.firstWhere((a) => a.id == admin.id).phone, '');
      });

      test('suspend and restore round trip', () async {
        final org = await repo.getOrganizationById('org-acme');
        final admin = org!.admins.first;
        final suspended = await repo.setOrganizationAdminStatus(
          'org-acme',
          admin.id,
          OrganizationAdminStatus.suspended,
        );
        expect(
          suspended.admins.firstWhere((a) => a.id == admin.id).status,
          OrganizationAdminStatus.suspended,
        );
        final restored = await repo.setOrganizationAdminStatus(
          'org-acme',
          admin.id,
          OrganizationAdminStatus.active,
        );
        expect(
          restored.admins.firstWhere((a) => a.id == admin.id).status,
          OrganizationAdminStatus.active,
        );
      });

      test('the last active admin cannot be suspended', () async {
        final org = await repo.getOrganizationById('org-apex');
        expect(org!.admins, hasLength(1));
        await expectLater(
          repo.setOrganizationAdminStatus(
            'org-apex',
            org.admins.single.id,
            OrganizationAdminStatus.suspended,
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.userMessage,
              'message',
              OrganizationAdminRules.lastActiveAdminMessage,
            ),
          ),
        );
        final unchanged = await repo.getOrganizationById('org-apex');
        expect(unchanged!.admins.single.status, OrganizationAdminStatus.active);
      });

      test('reset password validates the password', () async {
        final org = await repo.getOrganizationById('org-acme');
        await expectLater(
          repo.resetOrganizationAdminPassword(
            organizationId: 'org-acme',
            adminId: org!.admins.first.id,
            newPassword: 'short',
          ),
          throwsA(isA<ValidationException>()),
        );
        await repo.resetOrganizationAdminPassword(
          organizationId: 'org-acme',
          adminId: org.admins.first.id,
          newPassword: 'longenough1',
        );
      });
    });
  });
}
