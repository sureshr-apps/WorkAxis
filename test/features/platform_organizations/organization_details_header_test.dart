import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_details_header.dart';

CustomerOrganization _org({OrganizationStatus? status}) => CustomerOrganization(
  id: 'org',
  name: 'Apple',
  code: 'ORG-1',
  status: status ?? OrganizationStatus.active,
  branchCount: 1,
  employeeCount: 2,
  createdAt: DateTime(2026, 11, 14),
);

class _Calls {
  int edit = 0;
  int status = 0;
  int delete = 0;
  int copy = 0;
}

Future<_Calls> _pump(
  WidgetTester tester, {
  required double width,
  OrganizationStatus? status,
  bool withDelete = true,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final calls = _Calls();
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 1200),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: OrganizationDetailsHeader(
              organization: _org(status: status),
              planName: null,
              isActionLoading: false,
              onEdit: () => calls.edit++,
              onToggleStatus: () => calls.status++,
              onCopyCode: () => calls.copy++,
              onDelete: withDelete ? () => calls.delete++ : null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return calls;
}

void main() {
  group('OrganizationDetailsHeader on a phone', () {
    testWidgets('groups edit and status, with delete in the corner', (
      tester,
    ) async {
      final calls = await _pump(tester, width: 390);

      expect(find.widgetWithText(OutlinedButton, 'Edit'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Suspend'), findsOneWidget);
      // Delete is a direct icon in the header corner, not a row of its own.
      expect(find.byTooltip('Delete Apple'), findsOneWidget);
      expect(find.byTooltip('More actions for Apple'), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Suspend'));
      expect(calls.edit, 1);
      expect(calls.status, 1);
      expect(calls.delete, 0);
    });

    testWidgets('the delete icon calls onDelete in one tap', (tester) async {
      final calls = await _pump(tester, width: 390);

      await tester.tap(find.byTooltip('Delete Apple'));
      await tester.pumpAndSettle();

      expect(calls.delete, 1);
    });

    testWidgets('the delete icon is at least 48dp and sits top right', (
      tester,
    ) async {
      await _pump(tester, width: 390);

      final delete = find.byTooltip('Delete Apple');
      expect(tester.getSize(delete).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(delete).height, greaterThanOrEqualTo(48));
      // Same row as the name, aligned to the right edge of the card.
      expect(
        tester.getCenter(delete).dy,
        lessThan(tester.getCenter(find.text('Edit')).dy),
      );
      expect(tester.getTopRight(delete).dx, greaterThan(390 * 0.8));
    });

    testWidgets('tapping the organization code copies it', (tester) async {
      final calls = await _pump(tester, width: 390);

      expect(find.text('ORG-1'), findsOneWidget);
      await tester.tap(find.text('ORG-1'));

      expect(calls.copy, 1);
    });

    testWidgets('shows no delete icon when deleting is not allowed', (
      tester,
    ) async {
      await _pump(tester, width: 390, withDelete: false);
      expect(find.byTooltip('Delete Apple'), findsNothing);
    });

    testWidgets('offers Reactivate for a suspended organization', (
      tester,
    ) async {
      await _pump(tester, width: 390, status: OrganizationStatus.suspended);
      expect(find.widgetWithText(OutlinedButton, 'Reactivate'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Suspend'), findsNothing);
    });

    testWidgets('does not overflow at 360dp with large text', (tester) async {
      await _pump(tester, width: 360, textScale: 1.3);
      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(OutlinedButton, 'Edit'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Suspend'), findsOneWidget);
    });
  });

  group('OrganizationDetailsHeader on a wide layout', () {
    testWidgets('keeps the inline delete button', (tester) async {
      await _pump(tester, width: 1280);
      expect(
        find.widgetWithText(OutlinedButton, 'Edit Organization'),
        findsOneWidget,
      );
      expect(find.byTooltip('Delete Apple'), findsOneWidget);
    });
  });
}
