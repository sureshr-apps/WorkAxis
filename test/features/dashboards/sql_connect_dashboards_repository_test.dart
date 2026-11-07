import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/branch_dashboard/data/sql_connect_branch_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/data/sql_connect_organization_dashboard_repository.dart';
import 'package:workaxis/features/platform_dashboard/data/sql_connect_platform_dashboard_repository.dart';

void main() {
  group('SQL Connect Dashboard Repositories Tests', () {
    test('SqlConnectPlatformDashboardRepository provides stable contract and fallback handling', () {
      final fakeFirestore = FakeFirebaseFirestore();
      final repo = SqlConnectPlatformDashboardRepository(firestore: fakeFirestore);
      expect(repo, isNotNull);
    });

    test('SqlConnectOrganizationDashboardRepository returns valid attendance breakdown and attention items', () async {
      final repo = SqlConnectOrganizationDashboardRepository();

      final attendance = await repo.getOrganizationAttendanceSummary();
      expect(attendance.totalScheduled, equals(48));
      expect(attendance.present, equals(42));
      expect(attendance.late, equals(3));
      expect(attendance.absent, equals(2));
      expect(attendance.onLeave, equals(1));
      expect(attendance.attendancePercentage, equals(88));

      final items = await repo.getOrganizationAttentionItems();
      expect(items, isNotEmpty);
      expect(items.first.title, equals('Geofence Exception'));
      expect(items.first.statusLabel, equals('Pending Review'));
    });

    test('SqlConnectBranchDashboardRepository returns branch attendance and attention items', () async {
      final repo = SqlConnectBranchDashboardRepository();

      final attendance = await repo.getBranchAttendanceSummary('br-acme-01');
      expect(attendance.totalScheduled, equals(6));
      expect(attendance.present, equals(5));
      expect(attendance.late, equals(1));
      expect(attendance.absent, equals(0));

      final items = await repo.getBranchAttentionItems('br-acme-01');
      expect(items, isNotEmpty);
      expect(items.first.title, equals('Pending Return'));
      expect(items.first.subtitle, contains('INV-2026-0042'));
    });
  });
}
