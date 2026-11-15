import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/time/calendar_date.dart';
import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';
import 'package:workaxis/features/platform_organizations/domain/organization_license_rules.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';

LicensePlan _plan(String id, int level, PlanStatus status) => LicensePlan(
  id: id,
  planCode: 'PLN-0A1B2C3D4E5F-${id.toUpperCase()}',
  name: id,
  description: '',
  level: level,
  maxStores: level * 5,
  maxUsers: level * 25,
  status: status,
);

OrganizationLicense _license({
  required DateTime start,
  required DateTime expiry,
  required OrganizationLicenseStatus status,
  int level = 2,
  PlanStatus planStatus = PlanStatus.active,
}) => OrganizationLicense(
  id: 'lic-1',
  organizationId: 'org-1',
  startDate: start,
  expiryDate: expiry,
  negotiatedPrice: 1000,
  maintenancePrice: 100,
  status: status,
  plan: OrganizationLicensePlan(
    id: 'plan-$level',
    planCode: 'PLN-0A1B2C3D4E5F-PLAN',
    name: 'Plan $level',
    level: level,
    maxStores: 5,
    maxUsers: 25,
    status: planStatus,
  ),
);

void main() {
  group('CalendarDate', () {
    test('parses and formats yyyy-MM-dd as calendar dates', () {
      final date = CalendarDate.parse('2026-11-07');
      expect(date, DateTime.utc(2026, 11, 7));
      expect(CalendarDate.format(date), '2026-11-07');
      expect(CalendarDate.tryParse('2026-11-07T10:00:00Z'), date);
    });

    test('rejects text that is not a real calendar date', () {
      expect(CalendarDate.tryParse('07/11/2026'), isNull);
      expect(CalendarDate.tryParse('2026-02-30'), isNull);
      expect(() => CalendarDate.parse('next week'), throwsFormatException);
    });

    test('adds days and years across month, year and leap-day edges', () {
      expect(
        CalendarDate.addDays(DateTime.utc(2026, 12, 31), 1),
        DateTime.utc(2027, 1, 1),
      );
      expect(
        CalendarDate.addYears(DateTime.utc(2026, 11, 7), 1),
        DateTime.utc(2027, 11, 7),
      );
      expect(
        CalendarDate.addYears(DateTime.utc(2028, 2, 29), 1),
        DateTime.utc(2029, 3, 1),
      );
    });

    test('counts whole days, negative when the target is earlier', () {
      final from = DateTime.utc(2026, 11, 7);
      expect(CalendarDate.daysBetween(from, DateTime.utc(2026, 11, 17)), 10);
      expect(CalendarDate.daysBetween(from, DateTime.utc(2026, 11, 2)), -5);
      expect(CalendarDate.daysBetween(from, from), 0);
    });

    test('ignores the time of day and zone of the value', () {
      final evening = DateTime.utc(2026, 11, 7, 23, 59);
      expect(CalendarDate.of(evening), DateTime.utc(2026, 11, 7));
      expect(CalendarDate.daysBetween(evening, DateTime.utc(2026, 11, 8)), 1);
    });
  });

  group('term validation', () {
    test('expiry must be strictly after the start', () {
      final start = DateTime.utc(2026, 11, 7);
      expect(
        OrganizationLicenseRules.termError(start, DateTime.utc(2026, 11, 7)),
        'Expiry date must be after the start date.',
      );
      expect(
        OrganizationLicenseRules.termError(start, DateTime.utc(2026, 11, 8)),
        isNull,
      );
    });

    test('a renewal must start after the current expiry', () {
      final expiry = DateTime.utc(2026, 11, 6);
      final error = OrganizationLicenseRules.renewalTermError(
        currentExpiry: expiry,
        newStart: DateTime.utc(2026, 11, 6),
        newExpiry: DateTime.utc(2027, 11, 6),
      );
      expect(
        error,
        'The new start date must be after the current expiry date (2026-11-06).',
      );
    });

    test('a renewal must end after its own start', () {
      expect(
        OrganizationLicenseRules.renewalTermError(
          currentExpiry: DateTime.utc(2026, 11, 6),
          newStart: DateTime.utc(2026, 11, 7),
          newExpiry: DateTime.utc(2026, 11, 7),
        ),
        'Expiry date must be after the start date.',
      );
    });

    test('the contiguous renewal is the day after the current expiry', () {
      final running = _license(
        start: DateTime.utc(2025, 11, 7),
        expiry: DateTime.utc(2026, 11, 6),
        status: OrganizationLicenseStatus.expiringSoon,
      );
      expect(
        OrganizationLicenseRules.continuesRunningTerm(
          running,
          DateTime.utc(2026, 11, 7),
        ),
        isTrue,
      );
      expect(
        OrganizationLicenseRules.continuesRunningTerm(
          running,
          DateTime.utc(2026, 11, 8),
        ),
        isFalse,
      );
      final lapsed = _license(
        start: DateTime.utc(2025, 11, 7),
        expiry: DateTime.utc(2026, 11, 6),
        status: OrganizationLicenseStatus.expired,
      );
      expect(
        OrganizationLicenseRules.continuesRunningTerm(
          lapsed,
          DateTime.utc(2026, 11, 7),
        ),
        isFalse,
      );
    });

    test('renewal defaults: day after expiry, then one year', () {
      final start = OrganizationLicenseRules.defaultRenewalStart(
        DateTime.utc(2026, 11, 6),
      );
      expect(start, DateTime.utc(2026, 11, 7));
      expect(
        OrganizationLicenseRules.defaultTermExpiry(start),
        DateTime.utc(2027, 11, 7),
      );
    });
  });

  group('price input', () {
    test('accepts whole rupees of zero or more only', () {
      expect(OrganizationLicenseRules.parseWholeRupees(' 75000 '), 75000);
      expect(OrganizationLicenseRules.parseWholeRupees('0'), 0);
      expect(OrganizationLicenseRules.parseWholeRupees(''), isNull);
      expect(OrganizationLicenseRules.parseWholeRupees('-1'), isNull);
      expect(OrganizationLicenseRules.parseWholeRupees('12.5'), isNull);
      expect(OrganizationLicenseRules.parseWholeRupees('abc'), isNull);
    });

    test('price errors name the field', () {
      expect(
        OrganizationLicenseRules.priceError('', fieldName: 'one-time price'),
        'Enter a valid one-time price (whole rupees, 0 or more).',
      );
      expect(
        OrganizationLicenseRules.priceError('5', fieldName: 'one-time price'),
        isNull,
      );
    });
  });

  group('plan eligibility', () {
    final plans = [
      _plan('enterprise', 3, PlanStatus.active),
      _plan('basic', 1, PlanStatus.active),
      _plan('legacy', 4, PlanStatus.inactive),
      _plan('plus', 2, PlanStatus.active),
    ];

    test('assignable plans are the active ones, lowest level first', () {
      expect(OrganizationLicenseRules.assignablePlans(plans).map((p) => p.id), [
        'basic',
        'plus',
        'enterprise',
      ]);
    });

    test(
      'a change targets only active plans strictly above the current level',
      () {
        expect(
          OrganizationLicenseRules.changeTargets(plans, 2).map((p) => p.id),
          ['enterprise'],
        );
        expect(OrganizationLicenseRules.changeTargets(plans, 3), isEmpty);
      },
    );

    test('a renewal keeps the current level or moves up, never down', () {
      expect(OrganizationLicenseRules.renewalPlans(plans, 2).map((p) => p.id), [
        'plus',
        'enterprise',
      ]);
    });
  });

  group('history order', () {
    test('events are sorted newest first', () {
      LicenseHistoryEvent event(String id, DateTime at) => LicenseHistoryEvent(
        id: id,
        eventType: LicenseEventType.renewed,
        eventAt: at,
        planId: 'p',
        planCode: 'PLN',
        planName: 'Plus',
        planLevel: 2,
        maxStores: 10,
        maxUsers: 50,
        startDate: DateTime.utc(2026),
        expiryDate: DateTime.utc(2027),
        negotiatedPrice: 1,
        maintenancePrice: 1,
      );
      final sorted = OrganizationLicenseRules.newestFirst([
        event('old', DateTime.utc(2026, 1, 1)),
        event('new', DateTime.utc(2026, 6, 1)),
        event('mid', DateTime.utc(2026, 3, 1)),
      ]);
      expect(sorted.map((e) => e.id), ['new', 'mid', 'old']);
    });
  });
}
