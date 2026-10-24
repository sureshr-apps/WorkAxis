import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/settings/presentation/screens/organization_settings_screen.dart';
import 'package:workaxis/features/settings/presentation/screens/platform_settings_screen.dart';

void main() {
  late MockAccessDataSource accessDataSource;
  late MockAccessRepository accessRepository;
  late AccessController accessController;

  setUp(() {
    accessDataSource = MockAccessDataSource();
    accessRepository = MockAccessRepository(
      dataSource: accessDataSource,
      delay: Duration.zero,
    );
    accessController = AccessController(accessRepository: accessRepository);
  });

  tearDown(() {
    accessController.dispose();
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

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const PlatformSettingsScreen(),
      ),
    );

    await tester.pump();
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
          ChangeNotifierProvider<AccessController>.value(value: accessController),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OrganizationSettingsScreen(),
        ),
      ),
    );

    await tester.pump();
  }

  group('Platform Settings Screen Tests', () {
    testWidgets('renders all configuration sections on desktop', (tester) async {
      await pumpPlatformSettingsScreen(tester, width: 1200);

      expect(find.text('Platform Settings'), findsOneWidget);
      expect(find.text('Platform Environment & Topology'), findsOneWidget);
      expect(find.text('Authentication & Session Policies'), findsOneWidget);
      expect(find.text('Maintenance Window'), findsOneWidget);
      expect(find.text('Recent System Audit Trail'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on smartphone (390x844) with zero overflow', (tester) async {
      await pumpPlatformSettingsScreen(tester, width: 390, height: 844);

      expect(find.text('Platform Settings'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet (768x1024) with zero overflow', (tester) async {
      await pumpPlatformSettingsScreen(tester, width: 768, height: 1024);

      expect(find.text('Platform Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('saving changes shows success snackbar', (tester) async {
      await pumpPlatformSettingsScreen(tester, width: 1200);

      final saveButton = find.text('Save Changes');
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Platform configuration saved successfully.'), findsOneWidget);
    });
  });

  group('Organization Settings Screen Tests', () {
    testWidgets('renders all organization settings sections on desktop', (tester) async {
      await pumpOrganizationSettingsScreen(tester, width: 1200);

      expect(find.text('Organization Settings'), findsOneWidget);
      expect(find.text('Organization Information'), findsOneWidget);
      expect(find.text('Attendance & Geofencing Policies'), findsOneWidget);
      expect(find.text('Automated Operational Digests'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on smartphone (390x844) with zero overflow', (tester) async {
      await pumpOrganizationSettingsScreen(tester, width: 390, height: 844);

      expect(find.text('Organization Settings'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet (768x1024) with zero overflow', (tester) async {
      await pumpOrganizationSettingsScreen(tester, width: 768, height: 1024);

      expect(find.text('Organization Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('saving organization settings displays success snackbar', (tester) async {
      await pumpOrganizationSettingsScreen(tester, width: 1200);

      final saveButton = find.text('Save Changes');
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Organization operational settings saved successfully.'), findsOneWidget);
    });
  });
}
