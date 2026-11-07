import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:workaxis/app/app.dart';
import 'package:workaxis/app/bootstrap/backend_factory.dart';
import 'package:workaxis/app/config/backend_config.dart';
import 'package:workaxis/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (BackendConfig.isFirebase) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization notice: $e');
    }
  }

  final repos = BackendFactory.createRepositories();

  runApp(
    WorkAxisApp(
      authRepository: repos.authRepository,
      accessRepository: repos.accessRepository,
      platformRepository: repos.platformRepository,
      platformOrganizationsRepository: repos.platformOrganizationsRepository,
      platformUsersRepository: repos.platformUsersRepository,
      orgRepository: repos.orgRepository,
      branchRepository: repos.branchRepository,
      employeeRepository: repos.employeeRepository,
      branchManagementRepository: repos.branchManagementRepository,
      organizationMembersRepository: repos.organizationMembersRepository,
      attendanceRepository: repos.attendanceRepository,
      returnsRepository: repos.returnsRepository,
      reportsRepository: repos.reportsRepository,
    ),
  );
}
