import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/time/business_time.dart';

void main() {
  group('BusinessTime', () {
    test('the business timezone is Asia/Kolkata (UTC+05:30)', () {
      expect(kBusinessTimeZone, 'Asia/Kolkata');
      expect(kBusinessUtcOffset, const Duration(hours: 5, minutes: 30));
    });

    test('dateOf converts through UTC, independent of the device zone', () {
      // 18:29 UTC is still the same IST day; 18:30 UTC is midnight IST.
      expect(
        BusinessTime.dateOf(DateTime.utc(2026, 11, 6, 18, 29)),
        DateTime(2026, 11, 6),
      );
      expect(
        BusinessTime.dateOf(DateTime.utc(2026, 11, 6, 18, 30)),
        DateTime(2026, 11, 7),
      );
    });

    test('keys are zero padded yyyy-MM-dd', () {
      expect(BusinessTime.keyOfDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(
        BusinessTime.keyOfInstant(DateTime.utc(2026, 12, 31, 20)),
        '2027-01-01',
      );
    });

    test('startOfDay is IST midnight as a UTC instant', () {
      expect(
        BusinessTime.startOfDay(DateTime(2026, 11, 7)),
        DateTime.utc(2026, 11, 6, 18, 30),
      );
    });

    test('today follows the injected clock', () {
      expect(
        BusinessTime.today(() => DateTime.utc(2026, 11, 7, 5)),
        DateTime(2026, 11, 7),
      );
    });
  });
}
