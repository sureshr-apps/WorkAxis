import 'package:flutter/material.dart';
import 'package:workaxis/app/app.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize mock repositories for the mock-first architecture phase
  final authRepository = MockAuthenticationRepository();
  final accessRepository = MockAccessRepository();

  runApp(
    WorkAxisApp(
      authRepository: authRepository,
      accessRepository: accessRepository,
    ),
  );
}
