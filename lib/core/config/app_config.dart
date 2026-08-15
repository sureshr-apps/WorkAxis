import 'package:equatable/equatable.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';

enum OtpProviderType {
  msg91,
  inMemory,
  twilio,
}

class Msg91Config extends Equatable {
  const Msg91Config({
    this.authKey = const String.fromEnvironment(
      'MSG91_AUTH_KEY',
      defaultValue: String.fromEnvironment('MSG91_AUTH_TOKEN',
          defaultValue: '560926TkwDcG3B6a8062a5P1'),
    ),
    this.widgetId = const String.fromEnvironment('MSG91_WIDGET_ID',
        defaultValue: '36686f6c5452333835343638'),
    this.smsWidgetId =
        const String.fromEnvironment('MSG91_SMS_WIDGET_ID', defaultValue: ''),
    this.whatsappWidgetId = const String.fromEnvironment(
        'MSG91_WHATSAPP_WIDGET_ID',
        defaultValue: ''),
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
  final String widgetId;
  final String smsWidgetId;
  final String whatsappWidgetId;
  final String smsTemplateId;
  final String whatsappTemplateId;
  final int otpLength;
  final int otpExpiryMinutes;
  final String baseUrl;

  /// Returns true if either an authKey/token or a widgetId is configured.
  bool get isConfigured =>
      authKey.isNotEmpty ||
      widgetId.isNotEmpty ||
      smsWidgetId.isNotEmpty ||
      whatsappWidgetId.isNotEmpty;

  /// Returns true if using the MSG91 OTP Widget (no DLT required).
  bool get isWidgetFlow =>
      widgetId.isNotEmpty ||
      smsWidgetId.isNotEmpty ||
      whatsappWidgetId.isNotEmpty;

  /// Resolves the specific widget ID for a given channel.
  String getWidgetIdForChannel(OtpChannel channel) {
    if (channel == OtpChannel.whatsapp && whatsappWidgetId.isNotEmpty) {
      return whatsappWidgetId;
    }
    if (channel == OtpChannel.sms && smsWidgetId.isNotEmpty) {
      return smsWidgetId;
    }
    return widgetId;
  }

  @override
  List<Object?> get props => [
        authKey,
        widgetId,
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
