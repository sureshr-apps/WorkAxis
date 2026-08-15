import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_delivery_result.dart';

/// Abstract contract for pluggable OTP delivery and verification services (MSG91, Twilio, In-Memory, etc.).
abstract interface class OtpService {
  /// Sends an OTP to the specified phone number via the chosen channel (SMS or WhatsApp).
  Future<OtpDeliveryResult> sendOtp({
    required String phoneNumber,
    OtpChannel channel = OtpChannel.sms,
    String? templateId,
  });

  /// Verifies an entered OTP for the given phone number.
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? verificationId,
  });

  /// Resends an OTP to the specified phone number, optionally switching channels.
  Future<OtpDeliveryResult> resendOtp({
    required String phoneNumber,
    OtpChannel channel = OtpChannel.sms,
    String? verificationId,
  });
}
