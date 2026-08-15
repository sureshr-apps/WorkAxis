import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run bin/send_trial_otp.dart <phone_number_with_country_code>');
    print('Example: dart run bin/send_trial_otp.dart 919876543210');
    exit(1);
  }

  final rawPhone = args[0].replaceAll(RegExp(r'\D'), '');
  const widgetId = '36686f6c5452333835343638';
  const tokenAuth = '560926TkwDcG3B6a8062a5P1';

  print('==============================================');
  print(' MSG91 Live OTP Diagnostic Tool');
  print('==============================================');
  print('Recipient Mobile: $rawPhone');
  print('Widget ID:        $widgetId');
  print('Token/AuthKey:    $tokenAuth');
  print('----------------------------------------------');
  print('Sending trial OTP via MSG91 SendOTP API...');

  final url = Uri.parse(
    'https://control.msg91.com/api/v5/otp?widgetId=$widgetId&authkey=$tokenAuth&mobile=$rawPhone&otp_length=6&otp_expiry=5',
  );

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'authkey': tokenAuth,
      },
    );

    print('HTTP Status Code: ${response.statusCode}');
    print('Response Body:    ${response.body}');
    print('----------------------------------------------');

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['type'] == 'success' || response.statusCode == 200) {
      final reqId = json['request_id'] ?? json['reqId'];
      print('RESULT: SUCCESS');
      print('MSG91 Request ID: $reqId');
      print('');
      print('Next Steps to check delivery in MSG91 Dashboard:');
      print('1. Log in to https://control.msg91.com');
      print('2. Go to: OTP -> Logs / Analytics');
      print('3. Look for Request ID: $reqId');
      print('   Check status (Delivered, Pending, Failed, No Balance, or DND)');
    } else {
      print('RESULT: FAILED');
      print('Error Message: ${json['message']}');
    }
  } catch (e) {
    print('Network or execution error: $e');
  }
  print('==============================================');
}
