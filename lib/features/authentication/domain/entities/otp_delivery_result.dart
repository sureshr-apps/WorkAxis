import 'package:equatable/equatable.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';

class OtpDeliveryResult extends Equatable {
  const OtpDeliveryResult({
    required this.verificationId,
    required this.phoneNumber,
    required this.channel,
    required this.expiresInSeconds,
    this.message,
    this.providerName = 'MSG91',
  });

  final String verificationId;
  final String phoneNumber;
  final OtpChannel channel;
  final int expiresInSeconds;
  final String? message;
  final String providerName;

  @override
  List<Object?> get props => [
        verificationId,
        phoneNumber,
        channel,
        expiresInSeconds,
        message,
        providerName,
      ];
}
