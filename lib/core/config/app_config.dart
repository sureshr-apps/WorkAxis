import 'package:equatable/equatable.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';

enum OtpProviderType {
  msg91,
  inMemory,
  twilio,
}

class GoogleAuthConfig extends Equatable {
  const GoogleAuthConfig({
    this.serverClientId = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '',
    ),
    this.clientId = const String.fromEnvironment(
      'GOOGLE_CLIENT_ID',
      defaultValue: '',
    ),
    this.scopes = const ['email', 'profile'],
  });

  final String serverClientId;
  final String clientId;
  final List<String> scopes;

  bool get isConfigured => serverClientId.isNotEmpty || clientId.isNotEmpty;

  @override
  List<Object?> get props => [serverClientId, clientId, scopes];
}

class Msg91Config extends Equatable {
  const Msg91Config({
    this.authKey = const String.fromEnvironment(
      'MSG91_AUTH_KEY',
      defaultValue: String.fromEnvironment('MSG91_AUTH_TOKEN',
          defaultValue: '560926TkwDcG3B6a8062a5P1'),
    ),
    this.smsWidgetId = const String.fromEnvironment(
      'MSG91_SMS_WIDGET_ID',
      defaultValue: '36686f6e376d353532323233',
    ),
    this.whatsappWidgetId = const String.fromEnvironment(
      'MSG91_WHATSAPP_WIDGET_ID',
      defaultValue: '36686f6c5452333835343638',
    ),
    this.smsTemplateId =
        const String.fromEnvironment('MSG91_SMS_TEMPLATE_ID', defaultValue: ''),
    this.whatsappTemplateId = const String.fromEnvironment(
        'MSG91_WHATSAPP_TEMPLATE_ID',
        defaultValue: ''),
    this.otpLength = 6,
    this.otpExpiryMinutes = 5,
    this.baseUrl = 'https://control.msg91.com/api/v5',
  });

  final String authKey;
  final String smsWidgetId;
  final String whatsappWidgetId;
  final String smsTemplateId;
  final String whatsappTemplateId;
  final int otpLength;
  final int otpExpiryMinutes;
  final String baseUrl;

  /// Returns true if either an authKey/token or a widget is configured.
  bool get isConfigured =>
      authKey.isNotEmpty ||
      smsWidgetId.isNotEmpty ||
      whatsappWidgetId.isNotEmpty;

  /// Returns true if using the MSG91 OTP Widget (no DLT required).
  bool get isWidgetFlow =>
      smsWidgetId.isNotEmpty || whatsappWidgetId.isNotEmpty;

  /// Resolves the specific widget ID for a given channel.
  String getWidgetIdForChannel(OtpChannel channel) {
    if (channel == OtpChannel.whatsapp) {
      return whatsappWidgetId.isNotEmpty ? whatsappWidgetId : smsWidgetId;
    }
    return smsWidgetId.isNotEmpty ? smsWidgetId : whatsappWidgetId;
  }

  @override
  List<Object?> get props => [
        authKey,
        smsWidgetId,
        whatsappWidgetId,
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
    this.googleAuth = const GoogleAuthConfig(),
  });

  final OtpProviderType otpProviderType;
  final OtpChannel defaultOtpChannel;
  final Msg91Config msg91;
  final GoogleAuthConfig googleAuth;

  AppConfig copyWith({
    OtpProviderType? otpProviderType,
    OtpChannel? defaultOtpChannel,
    Msg91Config? msg91,
    GoogleAuthConfig? googleAuth,
  }) {
    return AppConfig(
      otpProviderType: otpProviderType ?? this.otpProviderType,
      defaultOtpChannel: defaultOtpChannel ?? this.defaultOtpChannel,
      msg91: msg91 ?? this.msg91,
      googleAuth: googleAuth ?? this.googleAuth,
    );
  }

  @override
  List<Object?> get props =>
      [otpProviderType, defaultOtpChannel, msg91, googleAuth];
}
