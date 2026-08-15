import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:workaxis/core/config/app_config.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_delivery_result.dart';
import 'package:workaxis/features/authentication/domain/services/otp_service.dart';

/// Concrete implementation of [OtpService] integrating with MSG91 SendOTP v5 REST API.
class Msg91OtpService implements OtpService {
  Msg91OtpService({
    required this.config,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final Msg91Config config;
  final http.Client _httpClient;

  /// Normalizes E.164 phone numbers for MSG91 (e.g. +15551234567 -> 15551234567).
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

    final effectiveTemplateId = templateId ??
        (channel == OtpChannel.whatsapp
            ? config.whatsappTemplateId
            : config.smsTemplateId);

    final queryParams = <String, String>{
      'authkey': config.authKey,
      'mobile': mobile,
      'otp_length': config.otpLength.toString(),
      'otp_expiry': config.otpExpiryMinutes.toString(),
    };

    if (effectiveTemplateId.isNotEmpty) {
      queryParams['template_id'] = effectiveTemplateId;
    }

    if (channel == OtpChannel.whatsapp) {
      queryParams['channel'] = 'whatsapp';
    }

    final uri = Uri.parse(config.baseUrl).replace(queryParameters: queryParams);

    try {
      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'authkey': config.authKey,
        },
      );

      final body = _parseJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final type = body['type'] as String?;
        if (type == 'error') {
          final msg = body['message'] as String? ?? 'Failed to send OTP.';
          throw AuthException(message: msg, code: 'msg91-send-error');
        }

        final verificationId = body['request_id'] as String? ??
            'msg91_${DateTime.now().millisecondsSinceEpoch}';

        return OtpDeliveryResult(
          verificationId: verificationId,
          phoneNumber: phoneNumber,
          channel: channel,
          expiresInSeconds: config.otpExpiryMinutes * 60,
          message: body['message'] as String? ??
              'OTP sent successfully via ${channel.displayName}.',
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
    final mobile = _normalizeMobile(phoneNumber);
    final cleanOtp = otp.trim();

    if (cleanOtp.length != config.otpLength) {
      throw AuthException(
        message:
            'Please enter all ${config.otpLength} digits of the verification code.',
        code: 'invalid-otp-length',
      );
    }

    final verifyUrl = config.baseUrl.endsWith('/otp')
        ? '${config.baseUrl}/verify'
        : '${config.baseUrl}/otp/verify';

    final uri = Uri.parse(verifyUrl).replace(
      queryParameters: {
        'authkey': config.authKey,
        'mobile': mobile,
        'otp': cleanOtp,
      },
    );

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'authkey': config.authKey,
        },
      );

      final body = _parseJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final type = body['type'] as String?;
        final message = (body['message'] as String? ?? '').toLowerCase();

        if (type == 'success' ||
            message.contains('verified') ||
            message.contains('success')) {
          return true;
        }

        final errorMsg =
            body['message'] as String? ?? 'Invalid verification code.';
        throw AuthException(
          message: errorMsg.contains('match') || errorMsg.contains('invalid')
              ? 'Invalid verification code. Please check and try again.'
              : errorMsg,
          code: 'invalid-otp',
        );
      } else {
        final msg =
            body['message'] as String? ?? 'Failed to verify code with MSG91.';
        throw AuthException(
          message: msg,
          code: 'msg91-verify-error-${response.statusCode}',
        );
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Network error during code verification: $e',
      );
    }
  }

  @override
  Future<OtpDeliveryResult> resendOtp({
    required String phoneNumber,
    OtpChannel channel = OtpChannel.sms,
    String? verificationId,
  }) async {
    final mobile = _normalizeMobile(phoneNumber);
    final retryUrl = config.baseUrl.endsWith('/otp')
        ? '${config.baseUrl}/retry'
        : '${config.baseUrl}/otp/retry';

    final retryType = channel == OtpChannel.whatsapp
        ? 'whatsapp'
        : (channel == OtpChannel.voice ? 'voice' : 'text');

    final uri = Uri.parse(retryUrl).replace(
      queryParameters: {
        'authkey': config.authKey,
        'mobile': mobile,
        'retrytype': retryType,
      },
    );

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'authkey': config.authKey,
        },
      );

      final body = _parseJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final type = body['type'] as String?;
        if (type == 'error') {
          final msg = body['message'] as String? ?? 'Failed to resend code.';
          throw AuthException(message: msg, code: 'msg91-resend-error');
        }

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
      } else {
        final msg = body['message'] as String? ?? 'Failed to resend code.';
        throw AuthException(
          message: msg,
          code: 'msg91-resend-http-${response.statusCode}',
        );
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Network error during resend: $e',
      );
    }
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
