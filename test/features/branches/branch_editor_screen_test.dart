import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/branches/presentation/screens/branch_editor_screen.dart';

import '../../helpers/fallback_maps.dart';

void main() {
  Future<List<BranchRecord>> pumpEditor(
    WidgetTester tester, {
    BranchRecord? branch,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final saved = <BranchRecord>[];
    await tester.pumpWidget(
      MaterialApp(
        builder: fallbackMapsBuilder,
        theme: AppTheme.light,
        home: Scaffold(
          body: BranchEditorScreen(
            branch: branch,
            organizationId: 'org-1',
            managerOptions: const [],
            isSaving: false,
            onClose: () {},
            onSaved: () {},
            backLabel: 'Branch Management',
            onSave: (record) async {
              saved.add(record);
              return record;
            },
          ),
        ),
      ),
    );
    return saved;
  }

  const fieldIndex = {'Branch name': 0, 'District or address': 2};

  Future<void> fill(WidgetTester tester, String label, String text) async {
    await tester.enterText(find.byType(TextField).at(fieldIndex[label]!), text);
  }

  testWidgets('new branch starts with empty coordinates', (tester) async {
    await pumpEditor(tester);
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    final texts = fields.map((f) => f.controller?.text).toList();
    // name, code, location, radius, latitude, longitude
    expect(texts[4], '');
    expect(texts[5], '');
  });

  testWidgets('requires a map location before creating a branch', (
    tester,
  ) async {
    final saved = await pumpEditor(tester);
    await fill(tester, 'Branch name', 'Test');
    await fill(tester, 'District or address', 'Somewhere');
    await tester.tap(find.text('Create branch'));
    await tester.pump();

    expect(find.text('Select the branch location on the map.'), findsOneWidget);
    expect(saved, isEmpty);
  });

  testWidgets('saves coordinates selected through the map picker', (
    tester,
  ) async {
    final saved = await pumpEditor(tester);
    await fill(tester, 'Branch name', 'Test');
    await fill(tester, 'District or address', 'Somewhere');
    await tester.tap(find.byKey(const Key('test_select_location_btn')));
    await tester.pump();
    await tester.tap(find.text('Create branch'));
    await tester.pump();

    expect(saved, hasLength(1));
    expect(saved.single.latitude, 12.9716);
    expect(saved.single.longitude, 77.5946);
    expect(saved.single.hasGeofence, isTrue);
  });

  testWidgets('surfaces the controller error when save fails', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        builder: fallbackMapsBuilder,
        theme: AppTheme.light,
        home: Scaffold(
          body: BranchEditorScreen(
            branch: const BranchRecord(
              summary: BranchSummary(
                id: 'b1',
                organizationId: 'org-1',
                name: 'Main',
                code: 'MN',
                location: 'Here',
                activeEmployeeCount: 0,
                isActive: true,
              ),
              geofenceRadiusMeters: 100,
              managerIds: [],
              kioskStatus: KioskPairingStatus.notPaired,
            ),
            organizationId: 'org-1',
            managerOptions: const [],
            isSaving: false,
            onClose: () {},
            onSaved: () {},
            backLabel: 'Branch Management',
            readActionError: () => 'Code already in use.',
            onSave: (_) async => null,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Code already in use.'), findsOneWidget);
  });
}
