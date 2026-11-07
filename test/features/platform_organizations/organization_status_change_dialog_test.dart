import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_data_source.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_status_dialogs.dart';

Future<void> _open(
  WidgetTester tester,
  WidgetBuilder builder, {
  Size size = const Size(390, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showDialog<bool>(context: context, builder: builder),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  final org = MockPlatformOrganizationsDataSource().getById('org-acme')!;

  testWidgets('suspend failure keeps the dialog open with a neutral message', (
    tester,
  ) async {
    await _open(
      tester,
      (_) => SuspendOrganizationDialog(
        organization: org,
        onConfirm: () async => false,
      ),
    );

    await tester.tap(find.text('Suspend Organization'));
    await tester.pumpAndSettle();

    expect(
      find.text('The organization could not be suspended. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('Cluster'), findsNothing);
    expect(find.text('Suspend Organization?'), findsOneWidget);
  });

  testWidgets('server failure text from the caller replaces the default', (
    tester,
  ) async {
    await _open(
      tester,
      (_) => ReactivateOrganizationDialog(
        organization: org,
        onConfirm: () async => false,
        failureMessage: () => 'Three member accounts could not be updated.',
      ),
    );

    await tester.tap(find.text('Reactivate Organization'));
    await tester.pumpAndSettle();

    expect(
      find.text('Three member accounts could not be updated.'),
      findsOneWidget,
    );
  });

  testWidgets('success closes the dialog', (tester) async {
    await _open(
      tester,
      (_) => SuspendOrganizationDialog(
        organization: org,
        onConfirm: () async => true,
      ),
    );

    await tester.tap(find.text('Suspend Organization'));
    await tester.pumpAndSettle();

    expect(find.text('Suspend Organization?'), findsNothing);
  });

  testWidgets('dialog scrolls instead of overflowing on a short screen', (
    tester,
  ) async {
    await _open(
      tester,
      (_) => SuspendOrganizationDialog(
        organization: org,
        onConfirm: () async => false,
      ),
      size: const Size(320, 320),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });
}
