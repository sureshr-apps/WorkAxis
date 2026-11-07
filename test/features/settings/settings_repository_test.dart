import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/settings/data/firestore_settings_repository.dart';
import 'package:workaxis/features/settings/data/mock_settings_repository.dart';
import 'package:workaxis/features/settings/domain/models/organization_settings.dart';
import 'package:workaxis/features/settings/domain/models/platform_settings.dart';
import 'package:workaxis/features/settings/domain/repositories/settings_repository.dart';
import 'package:workaxis/features/settings/domain/validators/settings_validators.dart';
import 'package:workaxis/features/settings/presentation/controllers/settings_controller.dart';

import '../../helpers/access_fixtures.dart';

const _org = OrganizationSettings(
  geofenceRadiusMeters: 200,
  gracePeriodMinutes: 10,
  allowBreaks: false,
  requireGeolocation: true,
  dailyDigest: false,
  returnAlerts: true,
  operationsEmail: 'ops@acme.example',
  emergencyPhone: '+919876543210',
);

void _contract(String name, SettingsRepository Function() create) {
  group('SettingsRepository contract: $name', () {
    late SettingsRepository repo;
    setUp(() => repo = create());

    test('a missing document resolves to the defaults', () async {
      expect(
        await repo.getOrganizationSettings(access: orgAdminAccess()),
        OrganizationSettings.defaults,
      );
      expect(
        await repo.getPlatformSettings(access: platformAccess()),
        PlatformSettings.defaults,
      );
    });

    test('saved organization settings round-trip', () async {
      await repo.saveOrganizationSettings(
        access: orgAdminAccess(),
        settings: _org,
      );
      expect(
        await repo.getOrganizationSettings(access: orgAdminAccess()),
        _org,
      );
    });

    test('organizations are isolated from each other', () async {
      await repo.saveOrganizationSettings(
        access: orgAdminAccess(),
        settings: _org,
      );
      expect(
        await repo.getOrganizationSettings(
          access: orgAdminAccess(org: otherOrg, branchIds: const []),
        ),
        OrganizationSettings.defaults,
      );
    });

    test('only Organization Admins use organization settings', () async {
      for (final access in [
        branchManagerAccess(),
        employeeAccess(),
        platformAccess(),
      ]) {
        await expectLater(
          repo.getOrganizationSettings(access: access),
          throwsA(isA<AccessDeniedException>()),
        );
        await expectLater(
          repo.saveOrganizationSettings(access: access, settings: _org),
          throwsA(isA<AccessDeniedException>()),
        );
      }
    });

    test('platform settings: owner writes, admin reads only', () async {
      const settings = PlatformSettings(
        sessionTimeoutMinutes: 30,
        maxLoginAttempts: 4,
        maintenanceMode: true,
        enforceStrongPasswords: false,
      );
      await repo.savePlatformSettings(
        access: platformAccess(),
        settings: settings,
      );
      final admin = platformAccess(
        role: UserRole.platformAdmin,
        id: 'user-pa-01',
      );
      expect(await repo.getPlatformSettings(access: admin), settings);
      await expectLater(
        repo.savePlatformSettings(access: admin, settings: settings),
        throwsA(isA<AccessDeniedException>()),
      );
      await expectLater(
        repo.getPlatformSettings(access: orgAdminAccess()),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('invalid values are rejected and not stored', () async {
      await expectLater(
        repo.saveOrganizationSettings(
          access: orgAdminAccess(),
          settings: _org.copyWith(geofenceRadiusMeters: 5),
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        await repo.getOrganizationSettings(access: orgAdminAccess()),
        OrganizationSettings.defaults,
      );
    });
  });
}

void main() {
  _contract('mock', () => MockSettingsRepository(delay: Duration.zero));
  _contract(
    'Firestore (fake)',
    () => FirestoreSettingsRepository(firestore: FakeFirebaseFirestore()),
  );

  group('FirestoreSettingsRepository documents', () {
    late FakeFirebaseFirestore db;
    late FirestoreSettingsRepository repo;
    setUp(() {
      db = FakeFirebaseFirestore();
      repo = FirestoreSettingsRepository(firestore: db);
    });

    test('writes organization_settings/{orgId} with audit fields', () async {
      await repo.saveOrganizationSettings(
        access: orgAdminAccess(),
        settings: _org,
      );
      final data =
          (await db.collection('organization_settings').doc('org-acme').get())
              .data()!;
      expect(data['geofenceRadiusMeters'], 200);
      expect(data['organizationId'], 'org-acme');
      expect(data['updatedBy'], 'user-oa-01');
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('writes platform_settings/global', () async {
      await repo.savePlatformSettings(
        access: platformAccess(),
        settings: PlatformSettings.defaults,
      );
      final doc = await db.collection('platform_settings').doc('global').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['updatedBy'], 'user-po-01');
    });

    test(
      'a partial document is completed from the documented defaults',
      () async {
        await db.collection('organization_settings').doc('org-acme').set({
          'geofenceRadiusMeters': 300,
        });
        final loaded = await repo.getOrganizationSettings(
          access: orgAdminAccess(),
        );
        expect(loaded.geofenceRadiusMeters, 300);
        expect(
          loaded.gracePeriodMinutes,
          OrganizationSettings.defaults.gracePeriodMinutes,
        );
      },
    );
  });

  group('SettingsValidators', () {
    test('geofence radius range', () {
      OrganizationSettings withRadius(int r) =>
          OrganizationSettings.defaults.copyWith(geofenceRadiusMeters: r);
      expect(SettingsValidators.organization(withRadius(10)), isEmpty);
      expect(SettingsValidators.organization(withRadius(5000)), isEmpty);
      expect(
        SettingsValidators.organization(withRadius(9)),
        contains(SettingsField.geofenceRadius),
      );
      expect(
        SettingsValidators.organization(withRadius(5001)),
        contains(SettingsField.geofenceRadius),
      );
    });

    test('grace period range', () {
      OrganizationSettings withGrace(int g) =>
          OrganizationSettings.defaults.copyWith(gracePeriodMinutes: g);
      expect(SettingsValidators.organization(withGrace(0)), isEmpty);
      expect(SettingsValidators.organization(withGrace(120)), isEmpty);
      expect(
        SettingsValidators.organization(withGrace(-1)),
        contains(SettingsField.gracePeriod),
      );
      expect(
        SettingsValidators.organization(withGrace(121)),
        contains(SettingsField.gracePeriod),
      );
    });

    test('session timeout and lockout attempts ranges', () {
      PlatformSettings p({int timeout = 60, int attempts = 5}) =>
          PlatformSettings.defaults.copyWith(
            sessionTimeoutMinutes: timeout,
            maxLoginAttempts: attempts,
          );
      expect(SettingsValidators.platform(p()), isEmpty);
      expect(
        SettingsValidators.platform(p(timeout: 4)),
        contains(SettingsField.sessionTimeout),
      );
      expect(
        SettingsValidators.platform(p(timeout: 1441)),
        contains(SettingsField.sessionTimeout),
      );
      expect(
        SettingsValidators.platform(p(attempts: 2)),
        contains(SettingsField.maxLoginAttempts),
      );
      expect(
        SettingsValidators.platform(p(attempts: 11)),
        contains(SettingsField.maxLoginAttempts),
      );
    });

    test('contact email and phone are optional but validated when present', () {
      OrganizationSettings with_({String? email, String? phone}) =>
          OrganizationSettings.defaults.copyWith(
            operationsEmail: email,
            emergencyPhone: phone,
          );
      expect(SettingsValidators.organization(with_()), isEmpty);
      expect(
        SettingsValidators.organization(with_(email: '', phone: '')),
        isEmpty,
      );
      expect(
        SettingsValidators.organization(with_(email: 'nope')),
        contains(SettingsField.operationsEmail),
      );
      expect(
        SettingsValidators.organization(with_(phone: '9876543210')),
        contains(SettingsField.emergencyPhone),
      );
      expect(
        SettingsValidators.organization(with_(phone: '+91 98765-43210')),
        isEmpty,
      );
    });
  });

  group('SettingsController', () {
    late SettingsController controller;
    setUp(() {
      controller = SettingsController(
        repository: MockSettingsRepository(delay: Duration.zero),
      );
    });
    tearDown(() => controller.dispose());

    test('loads organization settings', () async {
      expect(controller.organizationStatus, SettingsLoadStatus.initial);
      await controller.loadOrganization(access: orgAdminAccess());
      expect(controller.organizationStatus, SettingsLoadStatus.loaded);
      expect(controller.organizationSettings, OrganizationSettings.defaults);
    });

    test('a load failure exposes a safe message and no values', () async {
      await controller.loadOrganization(access: employeeAccess());
      expect(controller.organizationStatus, SettingsLoadStatus.error);
      expect(controller.loadErrorMessage, isNotNull);
      expect(controller.organizationSettings, isNull);
    });

    test('save validates first and keeps field errors', () async {
      await controller.loadOrganization(access: orgAdminAccess());
      final saved = await controller.saveOrganization(
        access: orgAdminAccess(),
        settings: _org.copyWith(gracePeriodMinutes: 500),
      );
      expect(saved, isFalse);
      expect(controller.validationErrors, contains(SettingsField.gracePeriod));
      expect(controller.lastSaveSucceeded, isFalse);
      expect(controller.organizationSettings, OrganizationSettings.defaults);
    });

    test('save success updates state and flags saved', () async {
      await controller.loadOrganization(access: orgAdminAccess());
      final saved = await controller.saveOrganization(
        access: orgAdminAccess(),
        settings: _org,
      );
      expect(saved, isTrue);
      expect(controller.lastSaveSucceeded, isTrue);
      expect(controller.isSaving, isFalse);
      expect(controller.organizationSettings, _org);
      controller.clearSaveState();
      expect(controller.lastSaveSucceeded, isFalse);
    });

    test('a denied save reports an error and does not claim success', () async {
      await controller.loadPlatform(
        access: platformAccess(role: UserRole.platformAdmin),
      );
      final saved = await controller.savePlatform(
        access: platformAccess(role: UserRole.platformAdmin),
        settings: PlatformSettings.defaults,
      );
      expect(saved, isFalse);
      expect(controller.saveErrorMessage, isNotNull);
      expect(controller.lastSaveSucceeded, isFalse);
      expect(controller.platformSettings, PlatformSettings.defaults);
    });

    test('reset clears everything, including in-flight work', () async {
      await controller.loadOrganization(access: orgAdminAccess());
      await controller.saveOrganization(
        access: orgAdminAccess(),
        settings: _org,
      );

      controller.reset();

      expect(controller.organizationSettings, isNull);
      expect(controller.organizationStatus, SettingsLoadStatus.initial);
      expect(controller.lastSaveSucceeded, isFalse);
      expect(controller.validationErrors, isEmpty);
    });
  });
}
