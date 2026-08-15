enum OtpChannel {
  sms,
  whatsapp,
  voice;

  String get displayName {
    switch (this) {
      case OtpChannel.sms:
        return 'SMS';
      case OtpChannel.whatsapp:
        return 'WhatsApp';
      case OtpChannel.voice:
        return 'Voice Call';
    }
  }

  String get iconEmoji {
    switch (this) {
      case OtpChannel.sms:
        return '💬';
      case OtpChannel.whatsapp:
        return '🟢';
      case OtpChannel.voice:
        return '📞';
    }
  }
}
