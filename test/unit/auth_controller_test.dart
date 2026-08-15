import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:workaxis/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';

void main() {
  late InMemoryAuthDataSource dataSource;
  late AuthRepositoryImpl repository;
  late AuthController controller;

  setUp(() {
    dataSource = InMemoryAuthDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: dataSource);
    controller = AuthController(authRepository: repository);
  });

  tearDown(() {
    controller.dispose();
  });

  group('AuthController', () {
    test('initial state is AuthInitial', () {
      expect(controller.state, const AuthInitial());
      expect(controller.isAuthenticated, false);
    });

    test(
        'sendOtp transitions from AuthAuthenticating to AuthOtpSent on valid phone (SMS)',
        () async {
      final future = controller.sendOtp(
        phoneNumber: '+15551234567',
        channel: OtpChannel.sms,
      );
      expect(controller.state,
          const AuthAuthenticating(message: 'Sending code...'));

      await future;
      expect(controller.state, isA<AuthOtpSent>());
      final sentState = controller.state as AuthOtpSent;
      expect(sentState.session.phoneNumber, '+15551234567');
      expect(sentState.session.channel, OtpChannel.sms);
    });

    test('sendOtp supports WhatsApp channel', () async {
      await controller.sendOtp(
        phoneNumber: '+919876543210',
        channel: OtpChannel.whatsapp,
      );

      expect(controller.state, isA<AuthOtpSent>());
      final sentState = controller.state as AuthOtpSent;
      expect(sentState.session.phoneNumber, '+919876543210');
      expect(sentState.session.channel, OtpChannel.whatsapp);
    });

    test('resendOtp allows switching from SMS to WhatsApp', () async {
      await controller.sendOtp(
        phoneNumber: '+15551234567',
        channel: OtpChannel.sms,
      );
      final initialSession = (controller.state as AuthOtpSent).session;
      expect(initialSession.channel, OtpChannel.sms);

      await controller.resendOtp(
        currentSession: initialSession,
        channel: OtpChannel.whatsapp,
      );

      final newSession = (controller.state as AuthOtpSent).session;
      expect(newSession.channel, OtpChannel.whatsapp);
    });

    test('sendOtp transitions to AuthError on invalid phone number', () async {
      await controller.sendOtp(phoneNumber: '123');
      expect(controller.state, isA<AuthError>());
    });

    test('verifyOtp transitions to AuthAuthenticated on correct code',
        () async {
      await controller.sendOtp(phoneNumber: '+15551234567');
      final session = (controller.state as AuthOtpSent).session;

      await controller.verifyOtp(
        verificationId: session.verificationId,
        smsCode: '123456',
      );

      expect(controller.state, isA<AuthAuthenticated>());
      expect(controller.isAuthenticated, true);
      expect(controller.currentUser?.phoneNumber, '+15551234567');
    });

    test('verifyOtp transitions to AuthError on invalid code', () async {
      await controller.sendOtp(phoneNumber: '+15551234567');
      final session = (controller.state as AuthOtpSent).session;

      await controller.verifyOtp(
        verificationId: session.verificationId,
        smsCode: '000000',
      );

      expect(controller.state, isA<AuthError>());
      expect(controller.isAuthenticated, false);
    });

    test('signInWithGoogle transitions to AuthAuthenticated', () async {
      await controller.signInWithGoogle();
      expect(controller.state, isA<AuthAuthenticated>());
      expect(controller.currentUser?.email, 'alex.morgan@workaxis.io');
    });

    test('signOut clears user and returns to AuthInitial', () async {
      await controller.signInWithGoogle();
      expect(controller.isAuthenticated, true);

      await controller.signOut();
      expect(controller.state, const AuthInitial());
      expect(controller.isAuthenticated, false);
    });
  });
}
