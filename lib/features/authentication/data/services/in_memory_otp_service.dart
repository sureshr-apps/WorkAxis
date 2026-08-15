import 'dart:math';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_delivery_result.dart';
import 'package:workaxis/features/authentication/domain/services/otp_service.dart';

/// In-memory mock implementation of [OtpService] for fast automated tests and offline development.
class InMemoryOtpService implements OtpService {
  InMemoryOtpService({
    this.fixedTestOtp = '123456',
    this.useFixedOtp = true,
    this.simulatedLatency = const Duration(milliseconds: 150),
    this.timeoutSeconds = 300,
  });

  final String fixedTestOtp;
  final bool useFixedOtp;
  final Duration simulatedLatency;
  final int timeoutSeconds;

  final Map<String, _StoredOtp> _storedOtps = {};

  @override
  Future<OtpDeliveryResult> sendOtp({
    required String phoneNumber,
    OtpChannel channel = OtpChannel.sms,
    String? templateId,
  }) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    if (phoneNumber.length < 8) {
      throw const AuthException(
        message: 'Invalid phone number format.',
        code: 'invalid-phone-number',
      );
    }

    final code = useFixedOtp
        ? fixedTestOtp
        : (100000 + Random().nextInt(900000)).toString();

    final verificationId =
        'mock_verif_${DateTime.now().millisecondsSinceEpoch}_$phoneNumber';

    _storedOtps[phoneNumber] = _StoredOtp(
      code: code,
      verificationId: verificationId,
      expiresAt: DateTime.now().add(Duration(seconds: timeoutSeconds)),
      channel: channel,
    );

    return OtpDeliveryResult(
      verificationId: verificationId,
      phoneNumber: phoneNumber,
      channel: channel,
      expiresInSeconds: timeoutSeconds,
      message: 'Code $code sent via ${channel.displayName} (Mock Provider).',
      providerName: 'InMemory',
    );
  }

  @override
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? verificationId,
  }) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    final stored = _storedOtps[phoneNumber];
    if (stored == null) {
      // If fixed code matches in test mode, allow verification
      if (useFixedOtp && otp == fixedTestOtp) {
        return true;
      }
      throw const AuthException(
        message:
            'No active verification session found. Please request a new code.',
        code: 'session-expired',
      );
    }

    if (DateTime.now().isAfter(stored.expiresAt)) {
      _storedOtps.remove(phoneNumber);
      throw const AuthException(
        message: 'Verification code has expired. Please request a new code.',
        code: 'otp-expired',
      );
    }

    if (stored.code != otp.trim() &&
        (!useFixedOtp || otp.trim() != fixedTestOtp)) {
      throw const AuthException(
        message: 'Invalid verification code. Please check and try again.',
        code: 'invalid-otp',
      );
    }

    _storedOtps.remove(phoneNumber);
    return true;
  }

  @override
  Future<OtpDeliveryResult> resendOtp({
    required String phoneNumber,
    OtpChannel channel = OtpChannel.sms,
    String? verificationId,
  }) async {
    return sendOtp(phoneNumber: phoneNumber, channel: channel);
  }

  /// Helper for unit tests to inspect generated code.
  String? getActiveCodeForPhone(String phoneNumber) =>
      _storedOtps[phoneNumber]?.code;

  void clear() => _storedOtps.clear();
}

class _StoredOtp {
  const _StoredOtp({
    required this.code,
    required this.verificationId,
    required this.expiresAt,
    required this.channel,
  });

  final String code;
  final String verificationId;
  final DateTime expiresAt;
  final OtpChannel channel;
}
