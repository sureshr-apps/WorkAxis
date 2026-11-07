import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/data/mock_platform_users_repository.dart';
import 'package:workaxis/features/platform_users/domain/administrator_activity_label.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/platform_users/presentation/screens/platform_administrator_details_screen.dart';
import 'package:workaxis/features/platform_users/presentation/screens/platform_administrator_form_screen.dart';
import 'package:workaxis/features/platform_users/presentation/screens/platform_users_list_screen.dart';

/// Repository whose status and password changes always fail.
class _FailingMutationsRepository extends MockPlatformUsersRepository {
  @override
  Future<PlatformAdministrator> updateAdministratorStatus(
    String id,
    AccountStatus status,
  ) => Future.error(StateError('backend unavailable'));

  @override
  Future<void> resetAdministratorPassword({
    required String id,
    required String newPassword,
  }) => Future.error(StateError('backend unavailable'));
}

void main() {
  late PlatformUsersController controller;

  setUp(() {
    controller = PlatformUsersController(
      repository: MockPlatformUsersRepository(),
    );
  });

  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester, Widget screen, {Size? size}) async {
    tester.view.physicalSize = size ?? const Size(1280, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider<PlatformUsersController>.value(
        value: controller,
        child: MaterialApp(home: screen),
      ),
    );
  }

  group('AdministratorActivityLabel', () {
    final now = DateTime(2026, 11, 7, 12);

    test('formats relative time against the injected clock', () {
      expect(AdministratorActivityLabel.short(null, now), 'Never');
      expect(
        AdministratorActivityLabel.short(
          now.subtract(const Duration(minutes: 5)),
          now,
        ),
        '5m ago',
      );
      expect(
        AdministratorActivityLabel.short(
          now.subtract(const Duration(hours: 3)),
          now,
        ),
        '3h ago',
      );
      expect(
        AdministratorActivityLabel.short(
          now.subtract(const Duration(days: 1)),
          now,
        ),
        'Yesterday',
      );
      expect(
        AdministratorActivityLabel.sentence(
          now.subtract(const Duration(days: 4)),
          now,
        ),
        'Active 4d ago',
      );
      expect(AdministratorActivityLabel.sentence(null, now), 'Never signed in');
    });

    test('never shows negative minutes for future timestamps', () {
      expect(
        AdministratorActivityLabel.short(
          now.add(const Duration(minutes: 2)),
          now,
        ),
        '0m ago',
      );
    });
  });

  testWidgets('search field is seeded from the controller filter', (
    tester,
  ) async {
    await controller.loadAdministrators();
    controller.setSearchQuery('Warner');

    await pump(tester, const PlatformUsersListScreen());
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, 'Warner');
  });

  testWidgets('a failed status change surfaces the action error', (
    tester,
  ) async {
    controller.dispose();
    controller = PlatformUsersController(
      repository: _FailingMutationsRepository(),
    );
    await controller.loadAdministrators();
    final administrator = controller.administrators.firstWhere(
      (a) => a.status == AccountStatus.active,
    );

    await pump(
      tester,
      PlatformAdministratorDetailsScreen(administratorId: administrator.id),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Suspend access'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Suspend access').last);
    await tester.pumpAndSettle();

    expect(controller.actionErrorMessage, isNotNull);
    expect(find.text(controller.actionErrorMessage!), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset password validates, calls the controller and confirms', (
    tester,
  ) async {
    await controller.loadAdministrators();
    final administrator = controller.administrators.first;

    await pump(
      tester,
      PlatformAdministratorDetailsScreen(administratorId: administrator.id),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset password'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
    await tester.pumpAndSettle();
    expect(find.text('Password must be 8-128 characters.'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'NewSecret!2026');
    await tester.enterText(fields.at(1), 'NewSecret!2026');
    await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
    await tester.pumpAndSettle();

    expect(
      find.text('Password reset for ${administrator.fullName}.'),
      findsOneWidget,
    );
  });

  testWidgets('details never flash a previously selected administrator', (
    tester,
  ) async {
    await controller.loadAdministrators();
    final first = controller.administrators.first;
    final second = controller.administrators[1];
    await controller.loadAdministrator(first.id);

    await pump(
      tester,
      PlatformAdministratorDetailsScreen(administratorId: second.id),
    );

    // First frame: loader, not the stale selection.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(first.fullName), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text(second.fullName), findsWidgets);
  });

  testWidgets('form validates optional contact fields only when provided', (
    tester,
  ) async {
    await pump(tester, const PlatformAdministratorFormScreen());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Jo Kim');
    await tester.enterText(fields.at(1), 'jk');
    await tester.enterText(fields.at(2), 'not-an-email');
    await tester.enterText(fields.at(4), 'short');
    await tester.ensureVisible(find.text('Create Administrator'));
    await tester.tap(find.text('Create Administrator'));
    await tester.pumpAndSettle();

    expect(find.text('Username must be 3-50 characters.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Password must be 8-128 characters.'), findsOneWidget);

    await tester.enterText(fields.at(2), '');
    await tester.ensureVisible(find.text('Create Administrator'));
    await tester.tap(find.text('Create Administrator'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsNothing);
  });

  for (final size in const [Size(390, 844), Size(768, 1024), Size(1280, 900)]) {
    testWidgets('list renders without overflow at ${size.width.toInt()}dp', (
      tester,
    ) async {
      await pump(tester, const PlatformUsersListScreen(), size: size);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
