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

  print('====================================================');
  print(' MSG91 Live OTP Diagnostic Tool');
  print('====================================================');
  print('Target Mobile: $rawPhone');
  print('Widget ID:     $widgetId');
  print('Token / Key:   $tokenAuth');
  print('----------------------------------------------------');

  // METHOD 1: Official MSG91 Widget SendOTP Endpoint
  print('1. Testing Official Widget Endpoint (api/v5/widget/sendOtp)...');
  final widgetUrl = Uri.parse('https://control.msg91.com/api/v5/widget/sendOtp');
  final widgetPayload = {
    'widgetId': widgetId,
    'tokenAuth': tokenAuth,
    'identifier': rawPhone,
  };

  try {
    final response1 = await http.post(
      widgetUrl,
      headers: {
        'Content-Type': 'application/json',
        'authkey': tokenAuth,
      },
      body: jsonEncode(widgetPayload),
    );

    print('   HTTP Status: ${response1.statusCode}');
    print('   Response:    ${response1.body}');
    final json1 = jsonDecode(response1.body) as Map<String, dynamic>;
    if (json1['type'] == 'success') {
      print('   -> SUCCESS: Widget Request ID = ${json1['message'] ?? json1['reqId']}');
    } else {
      print('   -> FAILED: ${json1['message']}');
    }
  } catch (e) {
    print('   -> ERROR: $e');
  }

  print('----------------------------------------------------');

  // METHOD 2: Direct SendOTP v5 API
  print('2. Testing Direct SendOTP v5 API (api/v5/otp)...');
  final otpUrl = Uri.parse(
    'https://control.msg91.com/api/v5/otp?widgetId=$widgetId&authkey=$tokenAuth&mobile=$rawPhone&otp_length=6&otp_expiry=5',
  );

  try {
    final response2 = await http.post(
      otpUrl,
      headers: {
        'Content-Type': 'application/json',
        'authkey': tokenAuth,
      },
    );

    print('   HTTP Status: ${response2.statusCode}');
    print('   Response:    ${response2.body}');
    final json2 = jsonDecode(response2.body) as Map<String, dynamic>;
    if (json2['type'] == 'success') {
      print('   -> SUCCESS: OTP Request ID = ${json2['request_id']}');
    } else {
      print('   -> FAILED: ${json2['message']}');
    }
  } catch (e) {
    print('   -> ERROR: $e');
  }

  print('====================================================');
  print('DIAGNOSTIC SUMMARY:');
  print('If Method 1 returns "Web requests are not allowed for this widget":');
  print('  -> In MSG91 Dashboard -> OTP -> Widgets -> Widget Settings:');
  print('     Check if "Allowed Domains" or "Direct API" permissions are enabled.');
  print('If Method 1 or 2 returns "AuthenticationFailure":');
  print('  -> The AuthKey must be your Account Master AuthKey from:');
  print('     https://control.msg91.com/app/authkey');
  print('====================================================');
}
