import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/settings/data/mock_settings_repository.dart';
import 'package:workaxis/features/settings/domain/models/platform_settings.dart';
import 'package:workaxis/features/settings/presentation/controllers/settings_controller.dart';
import 'package:workaxis/features/settings/presentation/screens/platform_settings_screen.dart';

/// Repository whose platform load or save can be made to fail.
class _FlakySettingsRepository extends MockSettingsRepository {
  _FlakySettingsRepository() : super(delay: Duration.zero);

  bool failLoad = false;
  bool failSave = false;

  @override
  Future<PlatformSettings> getPlatformSettings({
    required UserAccessContext access,
  }) {
    if (failLoad) return Future.error(StateError('offline'));
    return super.getPlatformSettings(access: access);
  }

  @override
  Future<PlatformSettings> savePlatformSettings({
    required UserAccessContext access,
    required PlatformSettings settings,
  }) {
    if (failSave) return Future.error(StateError('offline'));
    return super.savePlatformSettings(access: access, settings: settings);
  }
}

void main() {
  late _FlakySettingsRepository repository;
  late SettingsController settings;
  late AccessController access;

  setUp(() async {
    repository = _FlakySettingsRepository();
    settings = SettingsController(repository: repository);
    access = AccessController(
      accessRepository: MockAccessRepository(
        dataSource: MockAccessDataSource(),
        delay: Duration.zero,
      ),
    );
    await access.resolveAccess(
      const AppUser(
        id: 'user-po-01',
        name: 'Platform Owner',
        username: 'platform.owner',
        role: UserRole.platformOwner,
      ),
    );
  });

  tearDown(() {
    access.dispose();
    settings.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(1200, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AccessController>.value(value: access),
          ChangeNotifierProvider<SettingsController>.value(value: settings),
        ],
        child: const MaterialApp(home: PlatformSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unsupported platform policy controls are read-only', (
    tester,
  ) async {
    await pump(tester);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((field) => field.enabled == false),
      isTrue,
    );
    expect(
      tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .every((tile) => tile.onChanged == null),
      isTrue,
    );
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(settings.lastSaveSucceeded, isFalse);
    expect(
      find.textContaining('Policy changes are not available yet'),
      findsOneWidget,
    );
  });

  testWidgets('a failed load shows an error state with retry', (tester) async {
    repository.failLoad = true;
    await pump(tester);

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    repository.failLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Authentication & Session Policies'), findsOneWidget);
  });

  testWidgets('no hardcoded audit trail is rendered', (tester) async {
    await pump(tester);
    expect(find.text('Recent System Audit Trail'), findsNothing);
    expect(find.text('Alex Vance'), findsNothing);
  });

  for (final size in const [Size(390, 844), Size(768, 1024), Size(1280, 900)]) {
    testWidgets('renders without overflow at ${size.width.toInt()}dp', (
      tester,
    ) async {
      await pump(tester, size: size);
      expect(tester.takeException(), isNull);
    });
  }
}
