import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/bootstrap/backend_factory.dart';
import 'package:workaxis/app/config/backend_config.dart';
import 'package:workaxis/features/attendance/data/firestore_attendance_repository.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_repository.dart';
import 'package:workaxis/features/authentication/data/firebase_auth_repository.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';

void main() {
  group('BackendConfig and BackendFactory Tests', () {
    tearDown(() {
      BackendConfig.setMode(BackendMode.mock);
    });

    test('defaults to mock mode in test environment', () {
      expect(BackendConfig.mode, equals(BackendMode.mock));
      expect(BackendConfig.isMock, isTrue);
      expect(BackendConfig.isFirebase, isFalse);
    });

    test('BackendFactory instantiates mock repositories when in mock mode', () {
      BackendConfig.setMode(BackendMode.mock);
      final repos = BackendFactory.createRepositories();

      expect(repos.authRepository, isA<MockAuthenticationRepository>());
      expect(repos.attendanceRepository, isA<MockAttendanceRepository>());
      expect(repos.platformRepository, isNotNull);
      expect(repos.accessRepository, isNotNull);
      expect(repos.orgRepository, isNotNull);
    });

    test('BackendFactory switches to Firebase repositories in firebase mode', () {
      BackendConfig.setMode(BackendMode.firebase);
      expect(BackendConfig.isFirebase, isTrue);

      final repos = BackendFactory.createRepositories();
      expect(repos.authRepository, isA<FirebaseAuthRepository>());
      expect(repos.attendanceRepository, isA<FirestoreAttendanceRepository>());
    });
  });
}
