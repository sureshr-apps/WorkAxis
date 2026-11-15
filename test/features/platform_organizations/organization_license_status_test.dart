import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/time/calendar_date.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_display.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_details/license/license_formatters.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

final DateTime _today = DateTime.utc(2026, 11, 7);

OrganizationLicense _license({
  required DateTime start,
  required DateTime expiry,
  OrganizationLicenseStatus status = OrganizationLicenseStatus.active,
  PlanStatus planStatus = PlanStatus.active,
}) => OrganizationLicense(
  id: 'lic-1',
  organizationId: 'org-1',
  startDate: start,
  expiryDate: expiry,
  negotiatedPrice: 120000,
  maintenancePrice: 18000,
  status: status,
  plan: OrganizationLicensePlan(
    id: 'plan-plus',
    planCode: 'PLN-1A2B3C4D5E6F-PLUS',
    name: 'Plus',
    level: 2,
    maxStores: 10,
    maxUsers: 50,
    status: planStatus,
  ),
);

void main() {
  group('status display', () {
    test('every server status has its label and chip tone', () {
      final expected = {
        OrganizationLicenseStatus.notAssigned: (
          'Not Assigned',
          StatusType.neutral,
        ),
        OrganizationLicenseStatus.notYetActive: (
          'Not Yet Active',
          StatusType.neutral,
        ),
        OrganizationLicenseStatus.active: ('Active', StatusType.active),
        OrganizationLicenseStatus.expiringSoon: (
          'Expiring Soon',
          StatusType.pending,
        ),
        OrganizationLicenseStatus.expired: ('Expired', StatusType.urgent),
      };
      for (final entry in expected.entries) {
        expect(entry.key.label, entry.value.$1, reason: '${entry.key}');
        expect(entry.key.chipType, entry.value.$2, reason: '${entry.key}');
      }
    });

    test('history event types have their operator-facing labels', () {
      expect(LicenseEventType.assigned.label, 'License Assigned');
      expect(LicenseEventType.planChanged.label, 'Plan Changed');
      expect(
        LicenseEventType.commercialTermsModified.label,
        'Commercial Terms Modified',
      );
      expect(LicenseEventType.renewed.label, 'License Renewed');
    });
  });

  group('contextual term line', () {
    test('a term that has not started says when it activates', () {
      final license = _license(
        start: DateTime.utc(2026, 11, 10),
        expiry: DateTime.utc(2027, 11, 9),
        status: OrganizationLicenseStatus.notYetActive,
      );
      expect(
        LicenseFormatters.termNote(license, _today),
        'Scheduled to activate in 3 days (2026-11-10)',
      );
    });

    test('a lapsed term says how long ago it expired', () {
      final license = _license(
        start: DateTime.utc(2025, 11, 7),
        expiry: DateTime.utc(2026, 11, 2),
        status: OrganizationLicenseStatus.expired,
      );
      expect(
        LicenseFormatters.termNote(license, _today),
        'Expired 5 days ago on 2026-11-02',
      );
    });

    test('a term ending within 30 days recommends renewal', () {
      final license = _license(
        start: DateTime.utc(2025, 11, 7),
        expiry: DateTime.utc(2026, 11, 17),
        status: OrganizationLicenseStatus.expiringSoon,
      );
      expect(
        LicenseFormatters.termNote(license, _today),
        'Expires in 10 days (2026-11-17) - Renewal recommended',
      );
    });

    test('exactly 30 days still recommends renewal, 31 days does not', () {
      final thirtyDays = _license(
        start: DateTime.utc(2025, 11, 7),
        expiry: DateTime.utc(2026, 12, 7),
      );
      final thirtyOneDays = _license(
        start: DateTime.utc(2025, 11, 7),
        expiry: DateTime.utc(2026, 12, 8),
      );
      expect(
        LicenseFormatters.termNote(thirtyDays, _today),
        endsWith('Renewal recommended'),
      );
      expect(
        LicenseFormatters.termNote(thirtyOneDays, _today),
        'Expires in 31 days (2026-12-08)',
      );
    });

    test('a single day is singular and expiring today is named', () {
      final oneDay = _license(
        start: DateTime.utc(2025, 11, 7),
        expiry: DateTime.utc(2026, 11, 8),
      );
      final today = _license(
        start: DateTime.utc(2025, 11, 7),
        expiry: DateTime.utc(2026, 11, 7),
      );
      expect(
        LicenseFormatters.termNote(oneDay, _today),
        'Expires in 1 day (2026-11-08) - Renewal recommended',
      );
      expect(
        LicenseFormatters.termNote(today, _today),
        'Expires today (2026-11-07) - Renewal recommended',
      );
    });
  });

  group('formatting', () {
    test('event timestamps are shown in India time', () {
      expect(
        LicenseFormatters.eventTime(DateTime.utc(2026, 11, 7, 5, 15)),
        '07 Nov 2026, 10:45 AM IST',
      );
    });

    test('money is INR with Indian digit grouping', () {
      expect(LicenseFormatters.money(120000), '₹1,20,000');
    });

    test('periods show both calendar dates', () {
      expect(
        LicenseFormatters.period(
          CalendarDate.parse('2026-11-07'),
          CalendarDate.parse('2027-11-06'),
        ),
        '2026-11-07 to 2027-11-06',
      );
    });
  });
}
