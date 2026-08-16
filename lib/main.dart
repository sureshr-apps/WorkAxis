import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:workaxis/app/app.dart';
import 'package:workaxis/core/config/app_config.dart';
import 'package:workaxis/features/access_control/data/datasources/access_remote_data_source.dart';
import 'package:workaxis/features/access_control/data/datasources/firestore_access_data_source.dart';
import 'package:workaxis/features/access_control/data/repositories/access_repository_impl.dart';
import 'package:workaxis/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:workaxis/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:workaxis/features/authentication/data/services/google_sign_in_service.dart';
import 'package:workaxis/features/authentication/data/services/otp_service_factory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (e.g. for Firestore & Google Auth)
  AccessRemoteDataSource accessDataSource;
  try {
    await Firebase.initializeApp();
    accessDataSource = FirestoreAccessDataSource();
  } catch (e) {
    debugPrint('Firebase initialization fallback to in-memory: $e');
    accessDataSource = InMemoryAccessDataSource();
  }

  // Load app configuration (reads MSG91 credentials and Google config from environment or defaults)
  const appConfig = AppConfig();
  final otpService = OtpServiceFactory.create(config: appConfig);
  final googleAuthService =
      GoogleSignInServiceImpl(config: appConfig.googleAuth);

  final authDataSource = OtpServiceAuthDataSource(
    otpService: otpService,
    googleAuthService: googleAuthService,
  );
  final authRepository = AuthRepositoryImpl(remoteDataSource: authDataSource);

  final accessRepository =
      AccessRepositoryImpl(remoteDataSource: accessDataSource);

  runApp(
    WorkAxisApp(
      authRepository: authRepository,
      accessRepository: accessRepository,
    ),
  );
}
