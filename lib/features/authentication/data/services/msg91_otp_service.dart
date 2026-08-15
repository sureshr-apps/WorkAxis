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

    // Try standard v5 SendOTP API first (which accepts template_id = widgetId for DLT-less routing)
    // as it avoids browser/client domain origin restrictions.
    try {
      return await _sendOtpViaStandardApi(
        phoneNumber: phoneNumber,
        mobile: mobile,
        channel: channel,
        templateId: templateId,
      );
    } catch (e) {
      // If widgetId is configured and standard API fails, attempt widget/sendOtp endpoint as fallback
      if (config.isWidgetFlow) {
        try {
          return await _sendOtpViaWidget(
            phoneNumber: phoneNumber,
            mobile: mobile,
            channel: channel,
          );
        } catch (widgetError) {
          // If both fail, rethrow with friendly advice
          throw _formatFriendlyException(widgetError);
        }
      }
      rethrow;
    }
  }

  /// Sends OTP using standard MSG91 v5 API (passing widgetId as template_id if DLT-less).
  Future<OtpDeliveryResult> _sendOtpViaStandardApi({
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
        headers: _authHeaders,
      );

      final body = _parseJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final type = body['type'] as String?;
        final message = (body['message'] as String? ?? '').toLowerCase();

        if (type == 'error' ||
            message.contains('error') ||
            message.contains('not allowed')) {
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

  /// Sends OTP using the MSG91 OTP Widget endpoint.
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
        final msg = body['message'] as String? ?? '';

        if (type == 'error' || msg.toLowerCase().contains('not allowed')) {
          throw AuthException(
            message: msg.isNotEmpty ? msg : 'Failed to send OTP via widget.',
            code: 'msg91-widget-error',
          );
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
          message: msg.isNotEmpty
              ? msg
              : 'OTP sent successfully via ${channel.displayName}.',
          providerName: 'MSG91 Widget',
        );
      } else {
        final msg = body['message'] as String? ??
            'Widget endpoint returned status ${response.statusCode}';
        throw AuthException(
            message: msg, code: 'msg91-widget-http-${response.statusCode}');
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Unable to connect to MSG91 Widget service: $e',
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
      }
    } catch (e) {
      if (e is AuthException) rethrow;
    }

    // Fallback: Widget verify endpoint
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
      } catch (e) {
        if (e is AuthException) rethrow;
      }
    }

    throw const AuthException(
      message: 'Invalid verification code. Please check and try again.',
      code: 'invalid-otp',
    );
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

  AppException _formatFriendlyException(dynamic error) {
    if (error is AuthException) {
      final msg = error.message;
      if (msg.toLowerCase().contains('web requests are not allowed')) {
        return const AuthException(
          message:
              'MSG91 Widget Notice: Web/API requests are restricted for this widget. In your MSG91 Dashboard -> OTP -> Widgets -> Configurations, allow your domain/API requests or verify widget settings.',
          code: 'msg91-widget-domain-restricted',
        );
      }
      return error;
    }
    return NetworkException(message: 'Error connecting to MSG91: $error');
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
