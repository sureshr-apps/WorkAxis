import 'package:equatable/equatable.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';

/// Temporary session state during OTP flow.
class OtpSession extends Equatable {
  const OtpSession({
    required this.verificationId,
    required this.phoneNumber,
    this.channel = OtpChannel.sms,
    this.resendToken,
    required this.createdAt,
    this.timeoutSeconds = 60,
  });

  final String verificationId;
  final String phoneNumber;
  final OtpChannel channel;
  final int? resendToken;
  final DateTime createdAt;
  final int timeoutSeconds;

  bool get isExpired =>
      DateTime.now().difference(createdAt).inSeconds >= timeoutSeconds;

  int get remainingSeconds {
    final elapsed = DateTime.now().difference(createdAt).inSeconds;
    final remaining = timeoutSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  OtpSession copyWith({
    String? verificationId,
    String? phoneNumber,
    OtpChannel? channel,
    int? resendToken,
    DateTime? createdAt,
    int? timeoutSeconds,
  }) {
    return OtpSession(
      verificationId: verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      channel: channel ?? this.channel,
      resendToken: resendToken ?? this.resendToken,
      createdAt: createdAt ?? this.createdAt,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }

  @override
  List<Object?> get props => [
        verificationId,
        phoneNumber,
        channel,
        resendToken,
        createdAt,
        timeoutSeconds,
      ];
}
