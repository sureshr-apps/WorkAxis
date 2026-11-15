import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_card_item.dart';

CustomerOrganization _org() => CustomerOrganization(
  id: 'org',
  name: 'Apple',
  code: 'ORG-1',
  status: OrganizationStatus.active,
  branchCount: 1,
  employeeCount: 2,
  createdAt: DateTime(2026, 11, 14),
);

Future<_Taps> _pump(WidgetTester tester, {required double width}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final taps = _Taps();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OrganizationCardItem(
            organization: _org(),
            onTap: () => taps.open++,
            onEdit: () => taps.edit++,
            onDelete: () => taps.delete++,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return taps;
}

class _Taps {
  int open = 0;
  int edit = 0;
  int delete = 0;
}

void main() {
  group('OrganizationCardItem on a smartphone', () {
    testWidgets('shows a chevron and no edit, delete or details actions', (
      tester,
    ) async {
      await _pump(tester, width: 390);

      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.text('Details'), findsNothing);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('tapping anywhere on the card opens the organization', (
      tester,
    ) async {
      final taps = await _pump(tester, width: 390);

      await tester.tap(find.text('Apple'));
      await tester.tap(find.text('ORG-1'));
      await tester.tap(find.text('hubs'));
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));

      expect(taps.open, 4);
      expect(taps.edit, 0);
      expect(taps.delete, 0);
    });

    testWidgets('has no overflow at 360dp with large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, width: 360);

      expect(tester.takeException(), isNull);
    });
  });

  group('OrganizationCardItem on a tablet', () {
    testWidgets('keeps edit and delete actions, without a Details button', (
      tester,
    ) async {
      final taps = await _pump(tester, width: 700);

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.text('Details'), findsNothing);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(taps.edit, 1);
      expect(taps.delete, 1);
    });
  });
}
