import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/bootstrap/backend_factory.dart';
import 'package:workaxis/app/config/backend_config.dart';
import 'package:workaxis/features/attendance/data/firestore_attendance_repository.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_repository.dart';
import 'package:workaxis/features/authentication/data/firebase_auth_repository.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';
import 'package:workaxis/features/branches/data/mock_branch_management_repository.dart';
import 'package:workaxis/features/branches/data/sql_connect_branch_management_repository.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/data/sql_connect_organization_members_repository.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/data/sql_connect_platform_organizations_repository.dart';
import 'package:workaxis/features/returns/data/mock_returns_repository.dart';
import 'package:workaxis/features/returns/data/sql_connect_returns_repository.dart';

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
      expect(repos.platformOrganizationsRepository, isA<MockPlatformOrganizationsRepository>());
      expect(repos.branchManagementRepository, isA<MockBranchManagementRepository>());
      expect(repos.organizationMembersRepository, isA<MockOrganizationMembersRepository>());
      expect(repos.returnsRepository, isA<MockReturnsRepository>());
      expect(repos.platformRepository, isNotNull);
      expect(repos.accessRepository, isNotNull);
      expect(repos.orgRepository, isNotNull);
    });

    test('BackendFactory switches to Firebase and SQL Connect repositories in firebase mode', () {
      BackendConfig.setMode(BackendMode.firebase);
      expect(BackendConfig.isFirebase, isTrue);

      final repos = BackendFactory.createRepositories();
      expect(repos.authRepository, isA<FirebaseAuthRepository>());
      expect(repos.attendanceRepository, isA<FirestoreAttendanceRepository>());
      expect(repos.platformOrganizationsRepository, isA<SqlConnectPlatformOrganizationsRepository>());
      expect(repos.branchManagementRepository, isA<SqlConnectBranchManagementRepository>());
      expect(repos.organizationMembersRepository, isA<SqlConnectOrganizationMembersRepository>());
      expect(repos.returnsRepository, isA<SqlConnectReturnsRepository>());
    });
  });
}
