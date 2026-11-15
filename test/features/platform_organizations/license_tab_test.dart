import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/calendar_date.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/platform_organizations/data/mock_organization_license_store.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_data_source.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_requests.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/organization_license_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_formatters.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/organization_license_tab.dart';

import '../../helpers/fixed_clock.dart';

/// Pumps the license tab for [orgId] with a loaded controller. The mock store
/// runs on the fixed test clock (2026-11-07), so terms and copy are stable.
Future<
  ({
    MockPlatformOrganizationsRepository repository,
    OrganizationLicenseController controller,
  })
>
_pumpTab(
  WidgetTester tester,
  String orgId, {
  Size size = const Size(1280, 900),
  double textScale = 1.0,
}) async {
  final repository = MockPlatformOrganizationsRepository(
    dataSource: MockPlatformOrganizationsDataSource(
      licenses: MockOrganizationLicenseStore(now: fixedNow),
    ),
  );
  final organization = (await repository.getOrganizationById(orgId))!;
  final controller = OrganizationLicenseController(repository: repository);
  await controller.load(orgId);

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: OrganizationLicenseTab(
            organization: organization,
            controller: controller,
            now: fixedNow,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (repository: repository, controller: controller);
}

Future<void> _openAction(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// The dialog's own submit button (the tab behind it has the same labels).
Finder _dialogButton(String label) => find.descendant(
  of: find.byType(Dialog),
  matching: find.widgetWithText(AppButton, label),
);

void main() {
  group('summary', () {
    testWidgets(
      'shows plan, status badge, period and the contextual term line',
      (tester) async {
        final license = (await _pumpTab(
          tester,
          'org-acme',
        )).controller.licenseFor('org-acme')!;

        expect(find.text('ACTIVE'), findsOneWidget);
        expect(find.text(license.plan.name), findsWidgets);
        expect(find.text('LEVEL 2'), findsOneWidget);
        expect(
          find.text(
            LicenseFormatters.period(license.startDate, license.expiryDate),
          ),
          // The summary and the history row both show the period.
          findsWidgets,
        );
        expect(
          find.text(
            LicenseFormatters.termNote(
              license,
              CalendarDate.of(BusinessTime.today(fixedNow)),
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('Expires in 305 days (2027-09-08)'), findsOneWidget);
        expect(find.text('₹1,20,000'), findsWidgets);
        expect(find.text('₹18,000'), findsWidgets);
      },
    );

    testWidgets('the three actions are offered on a licensed organization', (
      tester,
    ) async {
      await _pumpTab(tester, 'org-acme');

      expect(find.text('Change Plan'), findsOneWidget);
      expect(find.text('Modify Commercial Terms'), findsOneWidget);
      expect(find.text('Renew License'), findsOneWidget);
    });

    testWidgets(
      'Change Plan is disabled with a reason when no higher plan is active',
      (tester) async {
        final pumped = await _pumpTab(tester, 'org-acme');
        await pumped.controller.changePlan(
          const ChangeLicensePlanRequest(
            targetPlanId: 'plan-enterprise',
            negotiatedPrice: 200000,
            maintenancePrice: 30000,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'No higher active plan is available for this organization.',
          ),
          findsOneWidget,
        );
        final button = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Change Plan'),
        );
        expect(button.onPressed, isNull);
      },
    );
  });

  group('plan details', () {
    testWidgets('shows stores and users from the live plan', (tester) async {
      await _pumpTab(tester, 'org-acme');

      expect(find.text('PLAN ENTITLEMENTS'), findsOneWidget);
      expect(find.text('Maximum Stores'), findsOneWidget);
      expect(find.text('10'), findsWidgets);
      expect(find.text('Maximum Users'), findsOneWidget);
      expect(find.text('50'), findsWidgets);
    });
  });

  group('history', () {
    testWidgets('renders the newest event first', (tester) async {
      final pumped = await _pumpTab(tester, 'org-acme');
      await pumped.controller.modifyCommercialTerms(
        const ModifyCommercialTermsRequest(
          negotiatedPrice: 125000,
          maintenancePrice: 18000,
        ),
      );
      await tester.pumpAndSettle();

      final newest = tester.getCenter(find.text('COMMERCIAL TERMS MODIFIED'));
      final oldest = tester.getCenter(find.text('LICENSE ASSIGNED'));
      expect(newest.dy, lessThan(oldest.dy));
    });
  });

  group('Change Plan dialog', () {
    testWidgets('lists only active plans strictly above the current level', (
      tester,
    ) async {
      await _pumpTab(tester, 'org-acme');
      await _openAction(tester, 'Change Plan');

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.textContaining('Enterprise · Level 3'), findsWidgets);
      expect(find.textContaining('Basic · Level 1'), findsNothing);
      expect(find.textContaining('Legacy Pilot'), findsNothing);
      expect(find.textContaining('Plus · Level 2'), findsNothing);
    });
  });

  group('Assign License dialog', () {
    testWidgets('empty state opens the dialog, which validates inline', (
      tester,
    ) async {
      await _pumpTab(tester, 'org-crestline');

      expect(find.text('No license assigned'), findsOneWidget);
      await _openAction(tester, 'Assign License');
      expect(find.byType(Dialog), findsOneWidget);

      // Only the negotiated price is entered; the maintenance price is missing.
      await tester.enterText(find.byType(TextField).first, '75000');
      await tester.tap(_dialogButton('Assign License'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Enter a valid annual maintenance price (whole rupees, 0 or more).',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Enter a valid one-time price (whole rupees, 0 or more).'),
        findsNothing,
      );
      // The entered value is kept after a validation failure.
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '75000',
      );
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('a whole-rupee price is required for the one-time price too', (
      tester,
    ) async {
      await _pumpTab(tester, 'org-crestline');
      await _openAction(tester, 'Assign License');

      await tester.tap(_dialogButton('Assign License'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid one-time price (whole rupees, 0 or more).'),
        findsOneWidget,
      );
    });
  });

  group('layout', () {
    for (final entry in const {
      'desktop': Size(1280, 900),
      'tablet': Size(768, 1024),
      'compact': Size(390, 844),
    }.entries) {
      testWidgets('lays out without overflow on ${entry.key}', (tester) async {
        await _pumpTab(tester, 'org-acme', size: entry.value);
        expect(tester.takeException(), isNull);
        expect(find.text('LICENSE HISTORY'), findsOneWidget);
      });
    }

    testWidgets(
      '360dp with 1.3x text has no overflow in the tab or its dialogs',
      (tester) async {
        await _pumpTab(
          tester,
          'org-acme',
          size: const Size(360, 800),
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);

        for (final action in [
          'Change Plan',
          'Modify Commercial Terms',
          'Renew License',
        ]) {
          await _openAction(tester, action);
          expect(find.byType(Dialog), findsOneWidget, reason: action);
          expect(tester.takeException(), isNull, reason: action);
          await tester.ensureVisible(find.text('Cancel'));
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(find.byType(Dialog), findsNothing, reason: action);
        }
      },
    );

    testWidgets('360dp with 1.3x text: the assign dialog fits', (tester) async {
      await _pumpTab(
        tester,
        'org-crestline',
        size: const Size(360, 800),
        textScale: 1.3,
      );
      await _openAction(tester, 'Assign License');
      expect(tester.takeException(), isNull);
    });
  });
}
