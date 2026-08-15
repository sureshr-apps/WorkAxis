import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';
import 'package:workaxis/core/config/app_config.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_delivery_result.dart';
import 'package:workaxis/features/authentication/domain/services/otp_service.dart';

/// Concrete implementation of [OtpService] integrating with MSG91's official [sendotp_flutter_sdk].
/// Supports Widget ID flow (DLT-less) and fallback REST APIs.
class Msg91OtpService implements OtpService {
  Msg91OtpService({
    required this.config,
    http.Client? httpClient,
  })  : _isCustomClient = httpClient != null,
        _httpClient = httpClient ?? http.Client() {
    if (config.widgetId.isNotEmpty &&
        config.authKey.isNotEmpty &&
        !_isCustomClient) {
      OTPWidget.initializeWidget(config.widgetId, config.authKey);
    }
  }

  final Msg91Config config;
  final http.Client _httpClient;
  final bool _isCustomClient;

  /// Normalizes phone numbers for MSG91 (e.g. +919876543210 -> 919876543210).
  String _normalizeMobile(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  }

  @override
  Future<OtpDeliveryResult> sendOtp({
    required String phoneNumber,
    OtpChannel channel = OtpChannel.sms,
    String? templateId,
  }) async {
    final mobile = _normalizeMobile(phoneNumber);
    if (mobile.length < 10) {
      throw const AuthException(
        message:
            'Invalid mobile number. Please check the country code and number.',
        code: 'invalid-phone-number',
      );
    }

    // 1. Primary for runtime: Official MSG91 Flutter SDK (OTPWidget)
    if (config.isWidgetFlow && !_isCustomClient) {
      try {
        OTPWidget.initializeWidget(config.widgetId, config.authKey);
        final channelCode =
            channel == OtpChannel.whatsapp ? 'WHATSAPP-12' : 'SMS-11';

        final response = await OTPWidget.sendOTP({
          'identifier': mobile,
          'channel': channelCode,
          'reqChannel': channelCode,
          'retryChannel': channelCode,
        });

        if (response != null) {
          final isSuccess = response['type'] == 'success' ||
              (response['status'] == 'success' && response['hasError'] != true);

          if (isSuccess) {
            final verificationId = response['message'] as String? ??
                response['reqId'] as String? ??
                response['requestId'] as String? ??
                mobile;

            // If user explicitly chose WhatsApp, trigger WhatsApp retry channel immediately
            // to ensure delivery via WhatsApp even if the widget's default channel is SMS.
            if (channel == OtpChannel.whatsapp) {
              try {
                await OTPWidget.retryOTP({
                  'reqId': verificationId,
                  'retryChannel': 'WHATSAPP-12',
                });
              } catch (_) {}
            }

            return OtpDeliveryResult(
              verificationId: verificationId,
              phoneNumber: phoneNumber,
              channel: channel,
              expiresInSeconds: config.otpExpiryMinutes * 60,
              message: 'OTP sent successfully via ${channel.displayName}.',
              providerName: 'MSG91 SDK',
            );
          } else {
            final msg = response['message'] as String? ??
                'Failed to send OTP via MSG91.';
            if (msg.toLowerCase().contains('mobile requests are not allowed')) {
              throw AuthException(
                message:
                    "MSG91 Setup Required: Please toggle ON 'Mobile Integration' in your MSG91 Dashboard (OTP -> Widgets -> ${config.widgetId} -> Configurations).",
                code: 'msg91-mobile-integration-disabled',
              );
            }
            throw AuthException(message: msg, code: 'msg91-sdk-error');
          }
        }
      } on AuthException {
        rethrow;
      } catch (e) {
        if (e is AuthException) rethrow;
        // Fallback to HTTP REST endpoint
      }
    }

    // 2. Fallback / Test Mock: Direct REST endpoint
    return _sendOtpViaRest(
      phoneNumber: phoneNumber,
      mobile: mobile,
      channel: channel,
      templateId: templateId,
    );
  }

  Future<OtpDeliveryResult> _sendOtpViaRest({
    required String phoneNumber,
    required String mobile,
    required OtpChannel channel,
    String? templateId,
  }) async {
    final effectiveTemplateId = templateId ??
        (channel == OtpChannel.whatsapp
            ? config.whatsappTemplateId
            : (config.smsTemplateId.isNotEmpty
                ? config.smsTemplateId
                : config.widgetId));

    final queryParams = <String, String>{
      if (config.authKey.isNotEmpty) 'authkey': config.authKey,
      if (effectiveTemplateId.isNotEmpty) 'template_id': effectiveTemplateId,
      if (config.widgetId.isNotEmpty) 'widgetId': config.widgetId,
      'mobile': mobile,
      'otp_length': config.otpLength.toString(),
      'otp_expiry': config.otpExpiryMinutes.toString(),
    };

    if (channel == OtpChannel.whatsapp) {
      queryParams['channel'] = 'whatsapp';
    }

    final otpUrl = config.baseUrl.endsWith('/otp')
        ? config.baseUrl
        : '${config.baseUrl}/otp';
    final uri = Uri.parse(otpUrl).replace(queryParameters: queryParams);

    try {
      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (config.authKey.isNotEmpty) 'authkey': config.authKey,
        },
      );

      final body = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final isSuccess = body['type'] == 'success' ||
            (body['status'] == 'success' && body['hasError'] != true);

        if (!isSuccess) {
          final msg = body['message'] as String? ?? 'Failed to send OTP.';
          throw AuthException(message: msg, code: 'msg91-send-error');
        }

        final verificationId = body['request_id'] as String? ??
            body['reqId'] as String? ??
            body['message'] as String? ??
            mobile;

        return OtpDeliveryResult(
          verificationId: verificationId,
          phoneNumber: phoneNumber,
          channel: channel,
          expiresInSeconds: config.otpExpiryMinutes * 60,
          message: 'OTP sent successfully via ${channel.displayName}.',
          providerName: 'MSG91',
        );
      } else {
        final msg = body['message'] as String? ??
            'MSG91 service error (Status ${response.statusCode}).';
        throw AuthException(
          message: msg,
          code: 'msg91-http-${response.statusCode}',
        );
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Unable to connect to OTP verification service: $e',
      );
    }
  }

  @override
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? verificationId,
  }) async {
    final cleanOtp = otp.trim();
    if (cleanOtp.length != config.otpLength) {
      throw AuthException(
        message:
            'Please enter all ${config.otpLength} digits of the verification code.',
        code: 'invalid-otp-length',
      );
    }

    final reqId = verificationId ?? _normalizeMobile(phoneNumber);

    // 1. Primary for runtime: Official MSG91 SDK
    if (config.isWidgetFlow && !_isCustomClient) {
      try {
        OTPWidget.initializeWidget(config.widgetId, config.authKey);
        final response = await OTPWidget.verifyOTP({
          'reqId': reqId,
          'otp': cleanOtp,
        });

        if (response != null) {
          final isSuccess = response['type'] == 'success' ||
              (response['status'] == 'success' && response['hasError'] != true);
          if (isSuccess) return true;

          final errorMsg =
              response['message'] as String? ?? 'Invalid verification code.';
          throw AuthException(
            message: errorMsg.contains('match') || errorMsg.contains('invalid')
                ? 'Invalid verification code. Please check and try again.'
                : errorMsg,
            code: 'invalid-otp',
          );
        }
      } on AuthException {
        rethrow;
      } catch (e) {
        if (e is AuthException) rethrow;
      }
    }

    // 2. Fallback / Test Mock: Direct REST endpoint
    final mobile = _normalizeMobile(phoneNumber);
    final verifyUrl = config.baseUrl.endsWith('/otp')
        ? '${config.baseUrl}/verify'
        : '${config.baseUrl}/otp/verify';

    final uri = Uri.parse(verifyUrl).replace(
      queryParameters: {
        if (config.authKey.isNotEmpty) 'authkey': config.authKey,
        if (config.widgetId.isNotEmpty) 'widgetId': config.widgetId,
        'mobile': mobile,
        'otp': cleanOtp,
      },
    );

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (config.authKey.isNotEmpty) 'authkey': config.authKey,
        },
      );

      final body = _parseJson(response.body);
      final isSuccess = body['type'] == 'success' ||
          (body['status'] == 'success' && body['hasError'] != true) ||
          (body['message'] as String? ?? '')
              .toLowerCase()
              .contains('success') ||
          (body['message'] as String? ?? '').toLowerCase().contains('verified');

      if (isSuccess) return true;

      final errorMsg =
          body['message'] as String? ?? 'Invalid verification code.';
      throw AuthException(
        message: errorMsg.contains('match') || errorMsg.contains('invalid')
            ? 'Invalid verification code. Please check and try again.'
            : errorMsg,
        code: 'invalid-otp',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Network error during verification: $e',
      );
    }
  }

  @override
  Future<OtpDeliveryResult> resendOtp({
    required String phoneNumber,
    OtpChannel channel = OtpChannel.sms,
    String? verificationId,
  }) async {
    final reqId = verificationId ?? _normalizeMobile(phoneNumber);
    final channelCode =
        channel == OtpChannel.whatsapp ? 'WHATSAPP-12' : 'SMS-11';

    // 1. Primary for runtime: Official MSG91 SDK
    if (config.isWidgetFlow && !_isCustomClient) {
      try {
        OTPWidget.initializeWidget(config.widgetId, config.authKey);
        final response = await OTPWidget.retryOTP({
          'reqId': reqId,
          'retryChannel': channelCode,
        });

        if (response != null) {
          final isSuccess = response['type'] == 'success' ||
              (response['status'] == 'success' && response['hasError'] != true);
          if (isSuccess) {
            return OtpDeliveryResult(
              verificationId: reqId,
              phoneNumber: phoneNumber,
              channel: channel,
              expiresInSeconds: config.otpExpiryMinutes * 60,
              message: 'Code resent via ${channel.displayName}.',
              providerName: 'MSG91 SDK',
            );
          } else {
            final msg = response['message'] as String? ??
                'Failed to resend code via ${channel.displayName}.';
            throw AuthException(message: msg, code: 'msg91-retry-error');
          }
        }
      } on AuthException {
        rethrow;
      } catch (e) {
        if (e is AuthException) rethrow;
      }
    }

    // Fallback: REST Retry endpoint
    final mobile = _normalizeMobile(phoneNumber);
    final retryUrl = config.baseUrl.endsWith('/otp')
        ? '${config.baseUrl}/retry'
        : '${config.baseUrl}/otp/retry';

    final retryType = channel == OtpChannel.whatsapp
        ? 'whatsapp'
        : (channel == OtpChannel.voice ? 'voice' : 'text');

    final uri = Uri.parse(retryUrl).replace(
      queryParameters: {
        if (config.authKey.isNotEmpty) 'authkey': config.authKey,
        if (config.widgetId.isNotEmpty) 'widgetId': config.widgetId,
        'mobile': mobile,
        'retrytype': retryType,
      },
    );

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (config.authKey.isNotEmpty) 'authkey': config.authKey,
        },
      );

      final body = _parseJson(response.body);
      final isSuccess = body['type'] == 'success' ||
          (body['status'] == 'success' && body['hasError'] != true);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          isSuccess) {
        return OtpDeliveryResult(
          verificationId: verificationId ??
              'msg91_${DateTime.now().millisecondsSinceEpoch}',
          phoneNumber: phoneNumber,
          channel: channel,
          expiresInSeconds: config.otpExpiryMinutes * 60,
          message: body['message'] as String? ??
              'Code resent via ${channel.displayName}.',
          providerName: 'MSG91',
        );
      }
    } catch (_) {}

    return sendOtp(phoneNumber: phoneNumber, channel: channel);
  }

  Map<String, dynamic> _parseJson(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{'message': rawBody};
    } catch (_) {
      return <String, dynamic>{'message': rawBody};
    }
  }
}
