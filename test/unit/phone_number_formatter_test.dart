import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/utils/phone_number_formatter.dart';

void main() {
  group('PhoneNumberFormatter', () {
    test('toE164 normalizes US phone numbers correctly', () {
      expect(
        PhoneNumberFormatter.toE164(
            countryCode: '+1', nationalNumber: '5551234567'),
        '+15551234567',
      );
      expect(
        PhoneNumberFormatter.toE164(
            countryCode: '1', nationalNumber: '(555) 123-4567'),
        '+15551234567',
      );
    });

    test('toE164 normalizes international codes correctly', () {
      expect(
        PhoneNumberFormatter.toE164(
            countryCode: '+91', nationalNumber: '9876543210'),
        '+919876543210',
      );
      expect(
        PhoneNumberFormatter.toE164(
            countryCode: '+44', nationalNumber: '7911 123456'),
        '+447911123456',
      );
    });

    test('maskPhoneNumber masks 10-digit numbers correctly', () {
      expect(
        PhoneNumberFormatter.maskPhoneNumber('5551234567'),
        '(***) ***-4567',
      );
    });

    test('maskPhoneNumber masks E.164 US numbers correctly', () {
      expect(
        PhoneNumberFormatter.maskPhoneNumber('+15551234567'),
        '+1 (***) ***-4567',
      );
    });

    test('maskPhoneNumber masks E.164 India numbers correctly', () {
      expect(
        PhoneNumberFormatter.maskPhoneNumber('+919876543210'),
        '+91 (***) ***-3210',
      );
    });

    test('isValidNationalNumber validates minimum length', () {
      expect(PhoneNumberFormatter.isValidNationalNumber('123456'), false);
      expect(PhoneNumberFormatter.isValidNationalNumber('5551234567'), true);
      expect(
          PhoneNumberFormatter.isValidNationalNumber('(555) 123-4567'), true);
    });
  });
}
