import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/data/services/in_memory_otp_service.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';

void main() {
  group('InMemoryOtpService Tests', () {
    late InMemoryOtpService service;

    setUp(() {
      service = InMemoryOtpService(
        fixedTestOtp: '123456',
        useFixedOtp: true,
        simulatedLatency: Duration.zero,
      );
    });

    test('sends OTP via SMS and verifies successfully with correct code',
        () async {
      final sendResult = await service.sendOtp(
        phoneNumber: '+15551234567',
        channel: OtpChannel.sms,
      );

      expect(sendResult.channel, OtpChannel.sms);
      expect(sendResult.verificationId, contains('+15551234567'));

      final isValid = await service.verifyOtp(
        phoneNumber: '+15551234567',
        otp: '123456',
      );

      expect(isValid, isTrue);
    });

    test('sends OTP via WhatsApp and verifies successfully', () async {
      final sendResult = await service.sendOtp(
        phoneNumber: '+919876543210',
        channel: OtpChannel.whatsapp,
      );

      expect(sendResult.channel, OtpChannel.whatsapp);

      final isValid = await service.verifyOtp(
        phoneNumber: '+919876543210',
        otp: '123456',
      );

      expect(isValid, isTrue);
    });

    test('throws AuthException on incorrect OTP', () async {
      final dynamicService = InMemoryOtpService(
        useFixedOtp: false,
        simulatedLatency: Duration.zero,
      );

      await dynamicService.sendOtp(phoneNumber: '+15559998888');

      expect(
        () => dynamicService.verifyOtp(
          phoneNumber: '+15559998888',
          otp: '000000',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
