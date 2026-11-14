import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/employee_home/presentation/screens/widgets/geofence_real_map_view.dart';

void main() {
  group('GeofenceRealMapView Tests', () {
    testWidgets('renders fallback map in test environment with coordinates', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 180,
              child: GeofenceRealMapView(
                latitude: 12.9716,
                longitude: 77.5946,
                geofenceRadiusMeters: 150,
                isWithinGeofence: true,
                branchName: 'Downtown Flagship',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GeofenceRealMapView), findsOneWidget);
      expect(find.textContaining('12.9716, 77.5946 (150m)'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('respects default coordinates when lat/long are null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 180,
              child: GeofenceRealMapView(
                latitude: null,
                longitude: null,
                geofenceRadiusMeters: null,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          '${GeofenceRealMapView.defaultLatitude.toStringAsFixed(4)}, ${GeofenceRealMapView.defaultLongitude.toStringAsFixed(4)} (${GeofenceRealMapView.defaultRadiusMeters}m)',
        ),
        findsOneWidget,
      );
    });
  });
}
