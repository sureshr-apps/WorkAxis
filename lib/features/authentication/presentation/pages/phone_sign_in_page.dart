import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/models/country_code.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/utils/phone_number_formatter.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/authentication/presentation/widgets/auth_scaffold.dart';
import 'package:workaxis/features/authentication/presentation/widgets/country_code_picker_sheet.dart';

class PhoneSignInPage extends StatefulWidget {
  const PhoneSignInPage({super.key});

  @override
  State<PhoneSignInPage> createState() => _PhoneSignInPageState();
}

class _PhoneSignInPageState extends State<PhoneSignInPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  CountryCode _selectedCountry = CountryCode.defaultCountry;
  String? _inlineError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickCountryCode() async {
    final picked = await CountryCodePickerSheet.show(
      context: context,
      selectedCountry: _selectedCountry,
    );
    if (picked != null && mounted) {
      setState(() => _selectedCountry = picked);
    }
  }

  Future<void> _handleSendOtp() async {
    final rawNumber = _phoneController.text.trim();
    if (rawNumber.isEmpty) {
      setState(() => _inlineError = 'Please enter your mobile number.');
      return;
    }

    if (!PhoneNumberFormatter.isValidNationalNumber(rawNumber)) {
      setState(() => _inlineError =
          'Please enter a valid mobile number (at least 10 digits).');
      return;
    }

    setState(() => _inlineError = null);
    final e164Phone = PhoneNumberFormatter.toE164(
      countryCode: _selectedCountry.dialCode,
      nationalNumber: rawNumber,
    );

    final authController = context.read<AuthController>();
    await authController.sendOtp(phoneNumber: e164Phone);

    if (!mounted) return;
    final state = authController.state;
    if (state is AuthOtpSent) {
      context.push('/signin/otp');
    } else if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.exception.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isLoading = authController.state is AuthAuthenticating;

    return AuthScaffold(
      title: 'Sign in with phone number',
      subtitle: 'Enter the mobile number registered with your organization.',
      onBack: () => context.go('/welcome'),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _phoneController,
              labelText: 'Mobile Number',
              hintText: '555 123 4567',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              errorText: _inlineError,
              prefixIcon: InkWell(
                onTap: _pickCountryCode,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.defaultRadius),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _selectedCountry.dialCode,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        height: 24,
                        width: 1,
                        color: AppColors.outlineVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              onSubmitted: (_) => _handleSendOtp(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'By continuing, you may receive an SMS for verification. Message and data rates may apply.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.outline,
                  ),
            ),
          ],
        ),
      ),
      bottomAction: AppButton(
        text: 'Send OTP',
        isLoading: isLoading,
        onPressed: _handleSendOtp,
      ),
    );
  }
}
