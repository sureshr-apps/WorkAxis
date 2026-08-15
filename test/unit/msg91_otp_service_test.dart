import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:workaxis/core/config/app_config.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/data/services/msg91_otp_service.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';

void main() {
  group('Msg91OtpService Tests', () {
    const config = Msg91Config(
      authKey: 'test_auth_key_12345',
      smsTemplateId: 'sms_tmpl_001',
      whatsappTemplateId: 'wa_tmpl_002',
      otpLength: 6,
      otpExpiryMinutes: 5,
    );

    test('sendOtp sends HTTP POST with correct query params for SMS', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;

      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;

        return http.Response(
          jsonEncode({
            'message': 'OTP sent successfully',
            'type': 'success',
            'request_id': 'req_msg91_101',
          }),
          200,
        );
      });

      final service = Msg91OtpService(config: config, httpClient: mockClient);

      final result = await service.sendOtp(
        phoneNumber: '+15551234567',
        channel: OtpChannel.sms,
      );

      expect(result.verificationId, 'req_msg91_101');
      expect(result.channel, OtpChannel.sms);
      expect(result.providerName, 'MSG91');
      expect(capturedHeaders['authkey'], 'test_auth_key_12345');
      expect(capturedUri.queryParameters['mobile'], '15551234567');
      expect(capturedUri.queryParameters['template_id'], 'sms_tmpl_001');
      expect(capturedUri.queryParameters['otp_length'], '6');
    });

    test('sendOtp configures channel=whatsapp for WhatsApp channel', () async {
      late Uri capturedUri;

      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode({
            'message': 'OTP sent on WhatsApp',
            'type': 'success',
            'request_id': 'req_wa_202',
          }),
          200,
        );
      });

      final service = Msg91OtpService(config: config, httpClient: mockClient);

      final result = await service.sendOtp(
        phoneNumber: '+919876543210',
        channel: OtpChannel.whatsapp,
      );

      expect(result.verificationId, 'req_wa_202');
      expect(result.channel, OtpChannel.whatsapp);
      expect(capturedUri.queryParameters['channel'], 'whatsapp');
      expect(capturedUri.queryParameters['template_id'], 'wa_tmpl_002');
      expect(capturedUri.queryParameters['mobile'], '919876543210');
    });

    test('verifyOtp returns true on success response', () async {
      late Uri capturedUri;

      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode({
            'message': 'OTP verified success',
            'type': 'success',
          }),
          200,
        );
      });

      final service = Msg91OtpService(config: config, httpClient: mockClient);

      final isValid = await service.verifyOtp(
        phoneNumber: '+15551234567',
        otp: '123456',
      );

      expect(isValid, isTrue);
      expect(capturedUri.queryParameters['mobile'], '15551234567');
      expect(capturedUri.queryParameters['otp'], '123456');
    });

    test('verifyOtp throws AuthException on invalid OTP', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'OTP not match',
            'type': 'error',
          }),
          200,
        );
      });

      final service = Msg91OtpService(config: config, httpClient: mockClient);

      expect(
        () => service.verifyOtp(phoneNumber: '+15551234567', otp: '000000'),
        throwsA(isA<AuthException>()),
      );
    });

    test('resendOtp invokes retry endpoint with correct retrytype', () async {
      late Uri capturedSmsUri;
      late Uri capturedWaUri;

      final mockClient = MockClient((request) async {
        if (request.url.queryParameters['retrytype'] == 'whatsapp') {
          capturedWaUri = request.url;
        } else {
          capturedSmsUri = request.url;
        }
        return http.Response(
          jsonEncode({
            'message': 'OTP resent successfully',
            'type': 'success',
          }),
          200,
        );
      });

      final service = Msg91OtpService(config: config, httpClient: mockClient);

      // Resend SMS
      final smsResult = await service.resendOtp(
        phoneNumber: '+15551234567',
        channel: OtpChannel.sms,
      );
      expect(smsResult.channel, OtpChannel.sms);
      expect(capturedSmsUri.queryParameters['retrytype'], 'text');

      // Resend WhatsApp
      final waResult = await service.resendOtp(
        phoneNumber: '+15551234567',
        channel: OtpChannel.whatsapp,
      );
      expect(waResult.channel, OtpChannel.whatsapp);
      expect(capturedWaUri.queryParameters['retrytype'], 'whatsapp');
    });

    test('handles HTTP 401 unauthorized gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Invalid authkey',
            'type': 'error',
          }),
          401,
        );
      });

      final service = Msg91OtpService(config: config, httpClient: mockClient);

      expect(
        () => service.sendOtp(phoneNumber: '+15551234567'),
        throwsA(isA<AuthException>()),
      );
    });

    group('MSG91 Widget ID Flow (No DLT Required)', () {
      const widgetConfig = Msg91Config(
        authKey: 'widget_token_abc123',
        widgetId: '346473616263333132333435',
        otpLength: 6,
        otpExpiryMinutes: 5,
      );

      test('sendOtp sends JSON payload to widget/sendOtp', () async {
        late String capturedBody;
        late Uri capturedUri;

        final mockClient = MockClient((request) async {
          capturedUri = request.url;
          capturedBody = request.body;

          return http.Response(
            jsonEncode({
              'message': 'OTP sent via widget',
              'type': 'success',
              'reqId': 'req_widget_999',
            }),
            200,
          );
        });

        final service =
            Msg91OtpService(config: widgetConfig, httpClient: mockClient);

        final result = await service.sendOtp(
          phoneNumber: '+919876543210',
          channel: OtpChannel.sms,
        );

        expect(result.verificationId, 'req_widget_999');
        expect(result.channel, OtpChannel.sms);
        expect(result.providerName, 'MSG91 Widget');
        expect(capturedUri.path, contains('/widget/sendOtp'));

        final decoded = jsonDecode(capturedBody) as Map<String, dynamic>;
        expect(decoded['widgetId'], '346473616263333132333435');
        expect(decoded['tokenAuth'], 'widget_token_abc123');
        expect(decoded['mobile'], '919876543210');
        expect(decoded['channel'], 'SMS');
      });

      test('verifyOtp sends JSON payload to widget/verifyOtp', () async {
        late String capturedBody;

        final mockClient = MockClient((request) async {
          capturedBody = request.body;
          return http.Response(
            jsonEncode({
              'message': 'OTP verified successfully',
              'type': 'success',
            }),
            200,
          );
        });

        final service =
            Msg91OtpService(config: widgetConfig, httpClient: mockClient);

        final isValid = await service.verifyOtp(
          phoneNumber: '+919876543210',
          otp: '654321',
          verificationId: 'req_widget_999',
        );

        expect(isValid, isTrue);
        final decoded = jsonDecode(capturedBody) as Map<String, dynamic>;
        expect(decoded['widgetId'], '346473616263333132333435');
        expect(decoded['reqId'], 'req_widget_999');
        expect(decoded['otp'], '654321');
      });
    });
  });
}
