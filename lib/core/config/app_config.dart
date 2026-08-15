import 'package:equatable/equatable.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';

enum OtpProviderType {
  msg91,
  inMemory,
  twilio,
}

class Msg91Config extends Equatable {
  const Msg91Config({
    this.authKey =
        const String.fromEnvironment('MSG91_AUTH_KEY', defaultValue: ''),
    this.smsTemplateId =
        const String.fromEnvironment('MSG91_SMS_TEMPLATE_ID', defaultValue: ''),
    this.whatsappTemplateId = const String.fromEnvironment(
        'MSG91_WHATSAPP_TEMPLATE_ID',
        defaultValue: ''),
    this.otpLength = 6,
    this.otpExpiryMinutes = 5,
    this.baseUrl = 'https://control.msg91.com/api/v5/otp',
  });

  final String authKey;
  final String smsTemplateId;
  final String whatsappTemplateId;
  final int otpLength;
  final int otpExpiryMinutes;
  final String baseUrl;

  bool get isConfigured => authKey.isNotEmpty;

  @override
  List<Object?> get props => [
        authKey,
        smsTemplateId,
        whatsappTemplateId,
        otpLength,
        otpExpiryMinutes,
        baseUrl,
      ];
}

class AppConfig extends Equatable {
  const AppConfig({
    this.otpProviderType = OtpProviderType.msg91,
    this.defaultOtpChannel = OtpChannel.sms,
    this.msg91 = const Msg91Config(),
  });

  final OtpProviderType otpProviderType;
  final OtpChannel defaultOtpChannel;
  final Msg91Config msg91;

  AppConfig copyWith({
    OtpProviderType? otpProviderType,
    OtpChannel? defaultOtpChannel,
    Msg91Config? msg91,
  }) {
    return AppConfig(
      otpProviderType: otpProviderType ?? this.otpProviderType,
      defaultOtpChannel: defaultOtpChannel ?? this.defaultOtpChannel,
      msg91: msg91 ?? this.msg91,
    );
  }

  @override
  List<Object?> get props => [otpProviderType, defaultOtpChannel, msg91];
}
