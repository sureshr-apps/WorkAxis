import 'package:workaxis/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:workaxis/features/authentication/domain/entities/auth_user.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_channel.dart';
import 'package:workaxis/features/authentication/domain/entities/otp_session.dart';
import 'package:workaxis/features/authentication/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AuthUser?> get authStateChanges => _remoteDataSource.authStateChanges;

  @override
  AuthUser? get currentUser => _remoteDataSource.currentUser;

  @override
  Future<OtpSession> sendOtp({
    required String phoneNumber,
    OtpChannel channel = OtpChannel.sms,
    int? resendToken,
  }) {
    return _remoteDataSource.sendOtp(
      phoneNumber: phoneNumber,
      channel: channel,
      resendToken: resendToken,
    );
  }

  @override
  Future<AuthUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) {
    return _remoteDataSource.verifyOtp(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  @override
  Future<AuthUser> signInWithGoogle() {
    return _remoteDataSource.signInWithGoogle();
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }
}
