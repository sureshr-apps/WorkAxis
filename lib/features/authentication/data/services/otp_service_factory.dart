import 'package:http/http.dart' as http;
import 'package:workaxis/core/config/app_config.dart';
import 'package:workaxis/features/authentication/data/services/in_memory_otp_service.dart';
import 'package:workaxis/features/authentication/data/services/msg91_otp_service.dart';
import 'package:workaxis/features/authentication/domain/services/otp_service.dart';

/// Factory responsible for instantiating the appropriate [OtpService] provider.
class OtpServiceFactory {
  static OtpService create({
    required AppConfig config,
    http.Client? httpClient,
  }) {
    switch (config.otpProviderType) {
      case OtpProviderType.msg91:
        if (config.msg91.isConfigured) {
          return Msg91OtpService(
            config: config.msg91,
            httpClient: httpClient,
          );
        }
        // Fallback to in-memory mock if MSG91 credentials are not configured
        return InMemoryOtpService();

      case OtpProviderType.inMemory:
        return InMemoryOtpService();

      case OtpProviderType.twilio:
        // Reserved for Twilio expansion; defaults to in-memory if unconfigured
        return InMemoryOtpService();
    }
  }
}
