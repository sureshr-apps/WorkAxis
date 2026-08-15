import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/utils/phone_number_formatter.dart';
import 'package:workaxis/core/widgets/app_button.dart';
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

  Future<void> _handleResend() async {
    if (_countdown > 0) return;

    final authController = context.read<AuthController>();
    final state = authController.state;
    if (state is AuthOtpSent) {
      await authController.resendOtp(currentSession: state.session);
      _startCountdown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new verification code has been sent.'),
          backgroundColor: AppColors.statusActive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final state = authController.state;
    final isLoading = state is AuthAuthenticating;

    String phoneNumber = '';
    if (state is AuthOtpSent) {
      phoneNumber = state.session.phoneNumber;
    } else if (state is AuthError && state.previousSession != null) {
      phoneNumber = state.previousSession!.phoneNumber;
    }

    final maskedPhone = PhoneNumberFormatter.maskPhoneNumber(phoneNumber);

    return AuthScaffold(
      title: 'Enter 6-digit code',
      subtitle: "We've sent a verification code to $maskedPhone",
      onBack: () => context.go('/signin/phone'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              if (_countdown > 0)
                Text(
                  'Resend in 00:${_countdown.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.w600,
                      ),
                )
              else
                TextButton(
                  onPressed: _handleResend,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(60, 32),
                  ),
                  child: const Text('Resend Code'),
                ),
            ],
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
