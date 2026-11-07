import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workaxis/app/config/backend_config.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/data/sql_connect_access_repository.dart';
import 'package:workaxis/features/access/domain/repositories/access_repository.dart';
import 'package:workaxis/features/attendance/data/firestore_attendance_repository.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_repository.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:workaxis/features/authentication/data/firebase_auth_repository.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';
import 'package:workaxis/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:workaxis/features/branch_dashboard/data/mock_branch_dashboard_repository.dart';
import 'package:workaxis/features/branch_dashboard/data/sql_connect_branch_dashboard_repository.dart';
import 'package:workaxis/features/branch_dashboard/domain/repositories/branch_dashboard_repository.dart';
import 'package:workaxis/features/branches/data/mock_branch_management_repository.dart';
import 'package:workaxis/features/branches/data/sql_connect_branch_management_repository.dart';
import 'package:workaxis/features/branches/domain/repositories/branch_management_repository.dart';
import 'package:workaxis/features/employee_home/data/firestore_employee_home_repository.dart';
import 'package:workaxis/features/employee_home/data/mock_employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_repository.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/data/sql_connect_organization_members_repository.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';
import 'package:workaxis/features/organization_dashboard/data/mock_organization_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/data/sql_connect_organization_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/domain/repositories/organization_dashboard_repository.dart';
import 'package:workaxis/features/platform_dashboard/data/mock_platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_dashboard/data/sql_connect_platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_dashboard/domain/repositories/platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/data/sql_connect_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';
import 'package:workaxis/features/platform_users/data/firestore_platform_users_repository.dart';
import 'package:workaxis/features/platform_users/data/mock_platform_users_repository.dart';
import 'package:workaxis/features/platform_users/domain/repositories/platform_users_repository.dart';
import 'package:workaxis/features/reports/data/mock_reports_repository.dart';
import 'package:workaxis/features/reports/data/sql_connect_reports_repository.dart';
import 'package:workaxis/features/reports/domain/repositories/reports_repository.dart';
import 'package:workaxis/features/returns/data/mock_returns_repository.dart';
import 'package:workaxis/features/returns/data/sql_connect_returns_repository.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';

/// Bundle containing all repositories required to bootstrap the application.
class BackendRepositories {
  const BackendRepositories({
    required this.authRepository,
    required this.accessRepository,
    required this.platformRepository,
    required this.platformOrganizationsRepository,
    required this.platformUsersRepository,
    required this.orgRepository,
    required this.branchRepository,
    required this.employeeRepository,
    required this.branchManagementRepository,
    required this.organizationMembersRepository,
    required this.attendanceRepository,
    required this.returnsRepository,
    required this.reportsRepository,
  });

  final AuthenticationRepository authRepository;
  final AccessRepository accessRepository;
  final PlatformDashboardRepository platformRepository;
  final PlatformOrganizationsRepository platformOrganizationsRepository;
  final PlatformUsersRepository platformUsersRepository;
  final OrganizationDashboardRepository orgRepository;
  final BranchDashboardRepository branchRepository;
  final EmployeeHomeRepository employeeRepository;
  final BranchManagementRepository branchManagementRepository;
  final OrganizationMembersRepository organizationMembersRepository;
  final AttendanceRepository attendanceRepository;
  final ReturnsRepository returnsRepository;
  final ReportsRepository reportsRepository;
}

/// Factory responsible for instantiating application repositories according to
/// the active [BackendConfig.mode].
class BackendFactory {
  BackendFactory._();

  /// Creates and returns all application repositories configured for the current environment.
  static BackendRepositories createRepositories({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    WorkaxisConnectorConnector? connector,
  }) {
    if (BackendConfig.isFirebase) {
      return BackendRepositories(
        authRepository: FirebaseAuthRepository(auth: auth, firestore: firestore),
        accessRepository: SqlConnectAccessRepository(connector: connector),
        platformRepository: SqlConnectPlatformDashboardRepository(
          connector: connector,
          firestore: firestore,
        ),
        platformOrganizationsRepository:
            SqlConnectPlatformOrganizationsRepository(connector: connector),
        platformUsersRepository:
            FirestorePlatformUsersRepository(firestore: firestore),
        orgRepository:
            SqlConnectOrganizationDashboardRepository(connector: connector),
        branchRepository:
            SqlConnectBranchDashboardRepository(connector: connector),
        employeeRepository: FirestoreEmployeeHomeRepository(firestore: firestore),
        branchManagementRepository:
            SqlConnectBranchManagementRepository(connector: connector),
        organizationMembersRepository:
            SqlConnectOrganizationMembersRepository(connector: connector),
        attendanceRepository: FirestoreAttendanceRepository(firestore: firestore),
        returnsRepository: SqlConnectReturnsRepository(connector: connector),
        reportsRepository: SqlConnectReportsRepository(connector: connector),
      );
    }

    // Default mock repositories bundle
    return BackendRepositories(
      authRepository: MockAuthenticationRepository(),
      accessRepository: MockAccessRepository(),
      platformRepository: MockPlatformDashboardRepository(),
      platformOrganizationsRepository: MockPlatformOrganizationsRepository(),
      platformUsersRepository: MockPlatformUsersRepository(),
      orgRepository: MockOrganizationDashboardRepository(),
      branchRepository: MockBranchDashboardRepository(),
      employeeRepository: MockEmployeeHomeRepository(),
      branchManagementRepository: MockBranchManagementRepository(),
      organizationMembersRepository: MockOrganizationMembersRepository(),
      attendanceRepository: MockAttendanceRepository(),
      returnsRepository: MockReturnsRepository(),
      reportsRepository: MockReportsRepository(),
    );
  }
}
