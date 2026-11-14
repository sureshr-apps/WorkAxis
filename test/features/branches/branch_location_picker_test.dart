import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/branches/presentation/screens/widgets/branch_editor_dialog.dart';
import 'package:workaxis/features/branches/presentation/screens/widgets/branch_location_picker.dart';

void main() {
  group('BranchLocationPicker Widget Tests', () {
    testWidgets('renders fallback picker with default button in test environment', (
      tester,
    ) async {
      double? selectedLat;
      double? selectedLng;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: BranchLocationPicker(
              latitude: null,
              longitude: null,
              geofenceRadiusMeters: 150,
              onLocationSelected: (lat, lng) {
                selectedLat = lat;
                selectedLng = lng;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Select location on map'), findsOneWidget);
      expect(find.text('No location selected'), findsOneWidget);
      expect(find.byKey(const Key('test_select_location_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('test_select_location_btn')));
      await tester.pump();

      expect(selectedLat, equals(BranchLocationPicker.defaultLatitude));
      expect(selectedLng, equals(BranchLocationPicker.defaultLongitude));
    });

    testWidgets('picking location on map updates BranchEditorDialog coordinates', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: BranchEditorDialog(
              organizationId: 'org-test',
              managerOptions: const [],
              isSaving: false,
              onSave: (record) async => record,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the interactive picker button inside BranchEditorDialog
      final pickerBtn = find.byKey(const Key('test_select_location_btn'));
      expect(pickerBtn, findsOneWidget);

      await tester.tap(pickerBtn);
      await tester.pumpAndSettle();

      // Verify that Latitude and Longitude fields have been updated automatically
      expect(find.widgetWithText(TextField, '12.971600'), findsOneWidget);
      expect(find.widgetWithText(TextField, '77.594600'), findsOneWidget);
    });
  });
}
