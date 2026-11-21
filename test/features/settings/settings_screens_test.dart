import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/settings/data/mock_settings_repository.dart';
import 'package:workaxis/features/settings/domain/models/organization_settings.dart';
import 'package:workaxis/features/settings/presentation/controllers/settings_controller.dart';
import 'package:workaxis/features/settings/presentation/screens/organization_settings_screen.dart';
import 'package:workaxis/features/settings/presentation/screens/platform_settings_screen.dart';

void main() {
  late MockAccessDataSource accessDataSource;
  late MockAccessRepository accessRepository;
  late AccessController accessController;
  late SettingsController settingsController;

  setUp(() {
    settingsController = SettingsController(
      repository: MockSettingsRepository(delay: Duration.zero),
    );
    accessDataSource = MockAccessDataSource();
    accessRepository = MockAccessRepository(
      dataSource: accessDataSource,
      delay: Duration.zero,
    );
    accessController = AccessController(accessRepository: accessRepository);
  });

  tearDown(() {
    accessController.dispose();
    settingsController.dispose();
  });

  Future<void> pumpPlatformSettingsScreen(
    WidgetTester tester, {
    double width = 1200,
    double height = 900,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await accessController.resolveAccess(
      const AppUser(
        id: 'user-po-01',
        name: 'Platform Owner',
        username: 'platform.owner',
        role: UserRole.platformOwner,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AccessController>.value(
            value: accessController,
          ),
          ChangeNotifierProvider<SettingsController>.value(
            value: settingsController,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PlatformSettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> pumpOrganizationSettingsScreen(
    WidgetTester tester, {
    double width = 1200,
    double height = 900,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await accessController.resolveAccess(
      const AppUser(
        id: 'user-oa-01',
        name: 'Jordan Lee',
        username: 'jordan.lee',
        role: UserRole.orgAdmin,
        organizationId: 'org-acme',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AccessController>.value(
            value: accessController,
          ),
          ChangeNotifierProvider<SettingsController>.value(
            value: settingsController,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OrganizationSettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('Platform Settings Screen Tests', () {
    testWidgets('renders all configuration sections on desktop', (
      tester,
    ) async {
      await pumpPlatformSettingsScreen(tester, width: 1200);

      expect(find.text('Platform Settings'), findsOneWidget);
      expect(find.text('Platform Environment & Topology'), findsOneWidget);
      expect(find.text('Authentication & Session Policies'), findsOneWidget);
      expect(find.text('Maintenance Window'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on smartphone (390x844) with zero overflow', (
      tester,
    ) async {
      await pumpPlatformSettingsScreen(tester, width: 390, height: 844);

      expect(find.text('Platform Settings'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet (768x1024) with zero overflow', (
      tester,
    ) async {
      await pumpPlatformSettingsScreen(tester, width: 768, height: 1024);

      expect(find.text('Platform Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unsupported platform policy changes cannot be saved', (
      tester,
    ) async {
      await pumpPlatformSettingsScreen(tester, width: 1200);

      final saveButton = find.text('Save Changes');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Platform configuration saved.'), findsNothing);
      expect(settingsController.lastSaveSucceeded, isFalse);
    });
  });

  group('Organization Settings Screen Tests', () {
    testWidgets('renders all organization settings sections on desktop', (
      tester,
    ) async {
      await pumpOrganizationSettingsScreen(tester, width: 1200);

      expect(find.text('Organization Settings'), findsOneWidget);
      expect(find.text('Organization Information'), findsOneWidget);
      expect(find.text('Asset Management'), findsOneWidget);
      expect(find.text('Require employee acknowledgment'), findsOneWidget);
      expect(find.text('Attendance & Geofencing Policies'), findsOneWidget);
      expect(find.text('Automated Operational Digests'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on smartphone (390x844) with zero overflow', (
      tester,
    ) async {
      await pumpOrganizationSettingsScreen(tester, width: 390, height: 844);

      expect(find.text('Organization Settings'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet (768x1024) with zero overflow', (
      tester,
    ) async {
      await pumpOrganizationSettingsScreen(tester, width: 768, height: 1024);

      expect(find.text('Organization Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('saving organization settings displays success snackbar', (
      tester,
    ) async {
      await pumpOrganizationSettingsScreen(tester, width: 1200);

      final saveButton = find.text('Save Changes');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Organization settings saved.'), findsOneWidget);
      expect(
        settingsController.organizationSettings,
        OrganizationSettings.defaults,
      );
    });

    testWidgets('asset acknowledgment defaults on and can be disabled', (
      tester,
    ) async {
      await pumpOrganizationSettingsScreen(tester, width: 1200);

      final toggle = find.byWidgetPredicate(
        (widget) =>
            widget is SwitchListTile &&
            (widget.title as Text?)?.data == 'Require employee acknowledgment',
      );
      expect(toggle, findsOneWidget);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(
        settingsController
            .organizationSettings
            ?.requireEmployeeAssetAcknowledgement,
        isFalse,
      );
    });

    testWidgets('attendance and digest preferences can all be disabled', (
      tester,
    ) async {
      await pumpOrganizationSettingsScreen(tester, width: 1200);

      SwitchListTile toggleFor(String title) => tester.widget<SwitchListTile>(
        find.byWidgetPredicate(
          (widget) =>
              widget is SwitchListTile &&
              (widget.title as Text?)?.data == title,
        ),
      );

      final titles = [
        'Require selfie for attendance',
        'Require Device GPS Fix for Attendance',
        'Allow Mid-Shift Break Recording',
        'Daily Morning Attendance Digest',
        'High-Value Product Return Alerts',
      ];
      for (final title in titles) {
        final toggle = find.byWidgetPredicate(
          (widget) =>
              widget is SwitchListTile &&
              (widget.title as Text?)?.data == title,
        );
        expect(toggle, findsOneWidget);
        expect(toggleFor(title).value, isTrue);
        expect(toggleFor(title).onChanged, isNotNull);
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(toggleFor(title).value, isFalse);
      }

      final saveButton = find.text('Save Changes');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      final saved = settingsController.organizationSettings!;
      expect(saved.requireAttendanceSelfie, isFalse);
      expect(saved.requireGeolocation, isFalse);
      expect(saved.allowBreaks, isFalse);
      expect(saved.dailyDigest, isFalse);
      expect(saved.returnAlerts, isFalse);
    });
  });
}
