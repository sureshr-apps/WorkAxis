import 'package:equatable/equatable.dart';

/// Temporary session state during OTP flow.
class OtpSession extends Equatable {
  const OtpSession({
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
    required this.createdAt,
    this.timeoutSeconds = 60,
  });

  final String verificationId;
  final String phoneNumber;
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

  @override
  List<Object?> get props => [
        verificationId,
        phoneNumber,
        resendToken,
        createdAt,
        timeoutSeconds,
      ];
}
