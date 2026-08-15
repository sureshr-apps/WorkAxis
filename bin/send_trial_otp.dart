// ignore_for_file: avoid_print
import 'dart:io';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print(
        'Usage: dart run bin/send_trial_otp.dart <phone_number_with_country_code>');
    print('Example: dart run bin/send_trial_otp.dart 919876543210');
    exit(1);
  }

  final rawPhone = args[0].replaceAll(RegExp(r'\D'), '');
  const widgetId = '36686f6c5452333835343638';
  const tokenAuth = '560926TkwDcG3B6a8062a5P1';

  print('====================================================');
  print(' MSG91 Flutter SDK Trial Tool');
  print('====================================================');
  print('Target Mobile: $rawPhone');
  print('Widget ID:     $widgetId');
  print('Token Auth:    $tokenAuth');
  print('----------------------------------------------------');
  print('Initializing sendotp_flutter_sdk OTPWidget...');
  OTPWidget.initializeWidget(widgetId, tokenAuth);

  print('1. Checking getWidgetProcess()...');
  try {
    final process = await OTPWidget.getWidgetProcess();
    print('   getWidgetProcess result: $process');
  } catch (e) {
    print('   getWidgetProcess error: $e');
  }

  print('----------------------------------------------------');
  print('2. Sending OTP via OTPWidget.sendOTP...');
  try {
    final response = await OTPWidget.sendOTP({'identifier': rawPhone});
    print('   sendOTP Response: $response');
  } catch (e) {
    print('   sendOTP Error: $e');
  }
  print('====================================================');
}
