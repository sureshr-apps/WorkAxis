import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:workaxis/core/config/app_config.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_delivery_result.dart';
import 'package:workaxis/features/authentication/domain/services/otp_service.dart';

/// Concrete implementation of [OtpService] integrating with MSG91 SendOTP v5 & OTP Widget APIs.
/// Supports both the default DLT-less Widget ID flow and custom DLT template flows.
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

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (config.authKey.isNotEmpty) 'authkey': config.authKey,
      };

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

    // Choose endpoint: Widget flow (no DLT) vs standard OTP flow
    if (config.isWidgetFlow) {
      return _sendOtpViaWidget(
          phoneNumber: phoneNumber, mobile: mobile, channel: channel);
    } else {
      return _sendOtpViaStandardApi(
        phoneNumber: phoneNumber,
        mobile: mobile,
        channel: channel,
        templateId: templateId,
      );
    }
  }

  /// Sends OTP using the MSG91 OTP Widget flow (no DLT required).
  Future<OtpDeliveryResult> _sendOtpViaWidget({
    required String phoneNumber,
    required String mobile,
    required OtpChannel channel,
  }) async {
    final uri = Uri.parse('${config.baseUrl}/widget/sendOtp');
    final channelStr = channel == OtpChannel.whatsapp ? 'WHATSAPP' : 'SMS';

    final bodyPayload = jsonEncode({
      'widgetId': config.widgetId,
      'tokenAuth': config.authKey,
      'identifier': mobile,
      'mobile': mobile,
      'otp_length': config.otpLength,
      'otp_expiry': config.otpExpiryMinutes,
      'channel': channelStr,
    });

    try {
      final response = await _httpClient.post(
        uri,
        headers: _authHeaders,
        body: bodyPayload,
      );

      final body = _parseJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final type = body['type'] as String?;
        if (type == 'error') {
          final msg =
              body['message'] as String? ?? 'Failed to send OTP via widget.';
          throw AuthException(message: msg, code: 'msg91-widget-error');
        }

        final verificationId = body['reqId'] as String? ??
            body['request_id'] as String? ??
            body['message'] as String? ??
            'msg91_widget_${DateTime.now().millisecondsSinceEpoch}';

        return OtpDeliveryResult(
          verificationId: verificationId,
          phoneNumber: phoneNumber,
          channel: channel,
          expiresInSeconds: config.otpExpiryMinutes * 60,
          message: body['message'] as String? ??
              'OTP sent successfully via ${channel.displayName}.',
          providerName: 'MSG91 Widget',
        );
      } else {
        // If widget endpoint 404s or errors, fallback to v5 OTP endpoint with widgetId
        return _sendOtpViaStandardApi(
          phoneNumber: phoneNumber,
          mobile: mobile,
          channel: channel,
        );
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Unable to connect to MSG91 OTP service: $e',
      );
    }
  }

  /// Sends OTP using standard MSG91 v5 API.
  Future<OtpDeliveryResult> _sendOtpViaStandardApi({
    required String phoneNumber,
    required String mobile,
    required OtpChannel channel,
    String? templateId,
  }) async {
    final effectiveTemplateId = templateId ??
        (channel == OtpChannel.whatsapp
            ? config.whatsappTemplateId
            : config.smsTemplateId);

    final queryParams = <String, String>{
      if (config.authKey.isNotEmpty) 'authkey': config.authKey,
      if (config.widgetId.isNotEmpty) 'widgetId': config.widgetId,
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

    final otpUrl = config.baseUrl.endsWith('/otp')
        ? config.baseUrl
        : '${config.baseUrl}/otp';
    final uri = Uri.parse(otpUrl).replace(queryParameters: queryParams);

    try {
      final response = await _httpClient.post(
        uri,
        headers: _authHeaders,
      );

      final body = _parseJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final type = body['type'] as String?;
        if (type == 'error') {
          final msg = body['message'] as String? ?? 'Failed to send OTP.';
          throw AuthException(message: msg, code: 'msg91-send-error');
        }

        final verificationId = body['request_id'] as String? ??
            body['reqId'] as String? ??
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

    if (config.isWidgetFlow) {
      try {
        final widgetVerifyUri = Uri.parse('${config.baseUrl}/widget/verifyOtp');
        final response = await _httpClient.post(
          widgetVerifyUri,
          headers: _authHeaders,
          body: jsonEncode({
            'widgetId': config.widgetId,
            'tokenAuth': config.authKey,
            'reqId': verificationId ?? mobile,
            'mobile': mobile,
            'otp': cleanOtp,
          }),
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
        }
      } catch (_) {
        // Fallback to standard verification below
      }
    }

    // Standard verification endpoint
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
        headers: _authHeaders,
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

    if (config.isWidgetFlow) {
      try {
        final retryUri = Uri.parse('${config.baseUrl}/widget/retryOtp');
        final retryChannelCode =
            channel == OtpChannel.whatsapp ? 13 : 11; // 11=SMS, 13=WhatsApp

        final response = await _httpClient.post(
          retryUri,
          headers: _authHeaders,
          body: jsonEncode({
            'widgetId': config.widgetId,
            'tokenAuth': config.authKey,
            'reqId': verificationId ?? mobile,
            'retryChannel': retryChannelCode,
          }),
        );

        final body = _parseJson(response.body);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final type = body['type'] as String?;
          if (type != 'error') {
            return OtpDeliveryResult(
              verificationId: verificationId ??
                  'msg91_widget_${DateTime.now().millisecondsSinceEpoch}',
              phoneNumber: phoneNumber,
              channel: channel,
              expiresInSeconds: config.otpExpiryMinutes * 60,
              message: body['message'] as String? ??
                  'Code resent via ${channel.displayName}.',
              providerName: 'MSG91 Widget',
            );
          }
        }
      } catch (_) {
        // Fallback to standard retry below
      }
    }

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
        headers: _authHeaders,
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
