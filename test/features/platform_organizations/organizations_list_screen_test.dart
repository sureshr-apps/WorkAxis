import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/screens/organizations_list_screen.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_card_item.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organizations_table.dart';

Future<PlatformOrganizationsController> _pumpList(
  WidgetTester tester, {
  required Size size,
  PlatformOrganizationsController? controller,
  int pageSize = 25,
}) async {
  final c =
      controller ??
      PlatformOrganizationsController(
        repository: MockPlatformOrganizationsRepository(),
        pageSize: pageSize,
        searchDebounce: Duration.zero,
      );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const OrganizationsListScreen()),
      GoRoute(
        path: '/platform/organizations/:id/edit',
        builder: (_, state) =>
            Scaffold(body: Text('Edit ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/platform/organizations/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Details ${state.pathParameters['id']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ChangeNotifierProvider<PlatformOrganizationsController>.value(
      value: c,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('search box is seeded from the controller query', (tester) async {
    final controller = PlatformOrganizationsController(
      repository: MockPlatformOrganizationsRepository(),
      searchDebounce: Duration.zero,
    );
    await controller.loadOrganizations();
    controller.setSearchQuery('Apex');

    await _pumpList(
      tester,
      size: const Size(1280, 900),
      controller: controller,
    );

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, 'Apex');
    expect(find.text('Apex Logistics & Freight'), findsOneWidget);
    expect(find.text('Acme Corporation'), findsNothing);
  });

  testWidgets('table Edit action opens the edit route', (tester) async {
    await _pumpList(tester, size: const Size(1280, 900));

    expect(find.byType(OrganizationsTable), findsOneWidget);
    await tester.tap(find.byTooltip('Edit Acme Corporation'));
    await tester.pumpAndSettle();

    expect(find.text('Edit org-acme'), findsOneWidget);
  });

  testWidgets('card Edit action opens the edit route on phones', (
    tester,
  ) async {
    await _pumpList(tester, size: const Size(390, 844));

    expect(find.byType(OrganizationCardItem), findsWidgets);
    final edit = find.byTooltip('Edit Acme Corporation');
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();

    expect(find.text('Edit org-acme'), findsOneWidget);
  });

  testWidgets('Load more appends the next page from the controller', (
    tester,
  ) async {
    final controller = await _pumpList(
      tester,
      size: const Size(390, 844),
      pageSize: 3,
    );
    expect(controller.organizations, hasLength(3));

    final loadMore = find.widgetWithText(AppButton, 'Load more');
    await tester.scrollUntilVisible(
      loadMore,
      300,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(loadMore);
    await tester.pumpAndSettle();
    await tester.tap(loadMore);
    await tester.pumpAndSettle();

    expect(controller.organizations, hasLength(6));
    expect(controller.hasMore, isTrue);
  });

  testWidgets('empty search shows the reset action', (tester) async {
    final controller = await _pumpList(tester, size: const Size(1280, 900));

    await tester.enterText(find.byType(TextField).first, 'zzz-no-match');
    await tester.pumpAndSettle();

    expect(find.text('No matching customer organizations'), findsOneWidget);
    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();
    expect(controller.searchQuery, isEmpty);
    expect(find.text('Acme Corporation'), findsOneWidget);
  });

  for (final entry in const {
    'desktop': Size(1280, 900),
    'tablet': Size(768, 1024),
    'compact': Size(390, 844),
  }.entries) {
    testWidgets('list lays out without overflow on ${entry.key}', (
      tester,
    ) async {
      await _pumpList(tester, size: entry.value);
      expect(tester.takeException(), isNull);
      expect(find.text('Acme Corporation'), findsOneWidget);
    });
  }
}
