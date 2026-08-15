import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/config/app_config.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/utils/phone_number_formatter.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_session.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/authentication/presentation/widgets/auth_scaffold.dart';
import 'package:workaxis/features/authentication/presentation/widgets/otp_input_row.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  String _enteredOtp = '';
  Timer? _timer;
  int _countdown = 45;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdown = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _enteredOtp = '';
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits of the verification code.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authController = context.read<AuthController>();
    final state = authController.state;
    String verificationId = '';

    if (state is AuthOtpSent) {
      verificationId = state.session.verificationId;
    } else if (state is AuthError && state.previousSession != null) {
      verificationId = state.previousSession!.verificationId;
    } else {
      context.go('/signin/phone');
      return;
    }

    await authController.verifyOtp(
      verificationId: verificationId,
      smsCode: _enteredOtp,
    );

    if (!mounted) return;
    final newState = authController.state;
    if (newState is AuthAuthenticated) {
      context.go('/verifying-access');
    } else if (newState is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState.exception.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleResend({OtpChannel? alternateChannel}) async {
    final authController = context.read<AuthController>();
    final state = authController.state;
    OtpSession? session;

    if (state is AuthOtpSent) {
      session = state.session;
    } else if (state is AuthError && state.previousSession != null) {
      session = state.previousSession;
    }

    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please re-enter your phone number.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final targetChannel = alternateChannel ?? session.channel;
    await authController.resendOtp(
      currentSession: session,
      channel: targetChannel,
    );

    if (!mounted) return;
    final newState = authController.state;
    if (newState is AuthOtpSent) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'A new code has been sent via ${targetChannel.displayName}.'),
          backgroundColor: AppColors.statusActive,
        ),
      );
    } else if (newState is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState.exception.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final state = authController.state;
    final isLoading = state is AuthAuthenticating;
    final isResending = state is AuthOtpSent && state.isResending;

    String phoneNumber = '';
    OtpChannel currentChannel = OtpChannel.sms;

    if (state is AuthOtpSent) {
      phoneNumber = state.session.phoneNumber;
      currentChannel = state.session.channel;
    } else if (state is AuthError && state.previousSession != null) {
      phoneNumber = state.previousSession!.phoneNumber;
      currentChannel = state.previousSession!.channel;
    }

    final maskedPhone = PhoneNumberFormatter.maskPhoneNumber(phoneNumber);
    final alternateChannel =
        currentChannel == OtpChannel.sms ? OtpChannel.whatsapp : OtpChannel.sms;

    // Check if live MSG91 credentials are configured
    const msg91Config = Msg91Config();
    final isMockMode = !msg91Config.isConfigured;

    return AuthScaffold(
      title: 'Enter 6-digit code',
      subtitle:
          "We've sent a verification code via ${currentChannel.displayName} to $maskedPhone",
      onBack: () => context.go('/signin/phone'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMockMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withAlpha(50),
                borderRadius: AppRadius.borderDefault,
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Dev Mock Mode: Use test OTP 123456 (Live SMS disabled without MSG91 credentials)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          OtpInputRow(
            onCompleted: (otp) {
              _enteredOtp = otp;
              _handleVerify();
            },
            onChanged: (otp) => _enteredOtp = otp,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Resend section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Didn't receive the code?",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isResending)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_countdown > 0)
                Text(
                  'Resend in 00:${_countdown.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.w600,
                      ),
                )
              else
                TextButton(
                  onPressed: () => _handleResend(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(60, 32),
                  ),
                  child: Text('Resend ${currentChannel.displayName}'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Alternate channel quick action
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: Text(alternateChannel.iconEmoji,
                  style: const TextStyle(fontSize: 14)),
              label: Text('Send via ${alternateChannel.displayName} instead'),
              onPressed: isResending
                  ? null
                  : () => _handleResend(alternateChannel: alternateChannel),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(120, 32),
              ),
            ),
          ),
        ],
      ),
      bottomAction: AppButton(
        text: 'Verify & Continue',
        isLoading: isLoading,
        onPressed: _handleVerify,
      ),
    );
  }
}
