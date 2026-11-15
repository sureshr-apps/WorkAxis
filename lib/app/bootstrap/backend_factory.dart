import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/core/backend/account_callables.dart';
import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/features/access/data/sql_connect_access_remote_data_source.dart';
import 'package:workaxis/features/branches/data/sql_connect_branches_remote_data_source.dart';
import 'package:workaxis/features/employees/data/sql_connect_organization_members_remote_data_source.dart';
import 'package:workaxis/features/platform_organizations/data/sql_connect_platform_organizations_remote_data_source.dart';
import 'package:workaxis/features/plans/data/mock_license_plans_repository.dart';
import 'package:workaxis/features/plans/data/sql_connect_license_plans_remote_data_source.dart';
import 'package:workaxis/features/plans/data/sql_connect_license_plans_repository.dart';
import 'package:workaxis/features/plans/domain/repositories/license_plans_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workaxis/app/config/backend_config.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';
import 'package:workaxis/core/storage/attachment_uploader.dart';
import 'package:workaxis/core/storage/firebase_attachment_storage.dart';
import 'package:workaxis/core/storage/mock_attachment_storage.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/data/sql_connect_access_repository.dart';
import 'package:workaxis/features/access/domain/repositories/access_repository.dart';
import 'package:workaxis/features/attendance/data/attendance_day_counter.dart';
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
import 'package:workaxis/features/employee_home/data/geolocator_device_location_gateway.dart';
import 'package:workaxis/features/employee_home/domain/services/attendance_location_provider.dart';
import 'package:workaxis/features/employee_home/domain/services/gateway_attendance_location_provider.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/data/sql_connect_organization_members_repository.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';
import 'package:workaxis/features/organization_dashboard/data/mock_organization_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/data/sql_connect_organization_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/domain/repositories/organization_dashboard_repository.dart';
import 'package:workaxis/features/platform_dashboard/data/mock_platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_dashboard/data/sql_connect_platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_dashboard/domain/repositories/platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_data_source.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/data/sql_connect_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';
import 'package:workaxis/features/platform_users/data/sql_connect_platform_users_remote_data_source.dart';
import 'package:workaxis/features/platform_users/data/sql_connect_platform_users_repository.dart';
import 'package:workaxis/features/platform_users/data/mock_platform_users_repository.dart';
import 'package:workaxis/features/platform_users/domain/repositories/platform_users_repository.dart';
import 'package:workaxis/features/reports/data/mock_reports_repository.dart';
import 'package:workaxis/features/reports/data/sql_connect_reports_repository.dart';
import 'package:workaxis/features/reports/domain/repositories/reports_repository.dart';
import 'package:workaxis/features/returns/data/mock_returns_repository.dart';
import 'package:workaxis/features/returns/data/sql_connect_returns_repository.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';
import 'package:workaxis/features/settings/data/firestore_settings_repository.dart';
import 'package:workaxis/features/settings/data/mock_settings_repository.dart';
import 'package:workaxis/features/settings/domain/repositories/settings_repository.dart';

/// Bundle containing all repositories required to bootstrap the application.
class BackendRepositories {
  const BackendRepositories({
    required this.authRepository,
    required this.accessRepository,
    required this.platformRepository,
    required this.platformOrganizationsRepository,
    required this.licensePlansRepository,
    required this.platformUsersRepository,
    required this.orgRepository,
    required this.branchRepository,
    required this.employeeRepository,
    required this.branchManagementRepository,
    required this.organizationMembersRepository,
    required this.attendanceRepository,
    required this.returnsRepository,
    required this.reportsRepository,
    required this.settingsRepository,
    required this.attachmentStorage,
  });

  final AuthenticationRepository authRepository;
  final AccessRepository accessRepository;
  final PlatformDashboardRepository platformRepository;
  final PlatformOrganizationsRepository platformOrganizationsRepository;
  final LicensePlansRepository licensePlansRepository;
  final PlatformUsersRepository platformUsersRepository;
  final OrganizationDashboardRepository orgRepository;
  final BranchDashboardRepository branchRepository;
  final EmployeeHomeRepository employeeRepository;
  final BranchManagementRepository branchManagementRepository;
  final OrganizationMembersRepository organizationMembersRepository;
  final AttendanceRepository attendanceRepository;
  final ReturnsRepository returnsRepository;
  final ReportsRepository reportsRepository;
  final SettingsRepository settingsRepository;
  final AttachmentStorage attachmentStorage;
}

/// Factory responsible for instantiating application repositories according to
/// the active [BackendConfig.mode].
class BackendFactory {
  BackendFactory._();

  /// Creates and returns all application repositories configured for the current environment.
  static BackendRepositories createRepositories({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    DataGateway? gateway,
    CallableFunctions? functions,
    AttendanceLocationProvider? locationProvider,
    Now? now,
  }) {
    BackendConfig.assertReleaseSafe();
    if (BackendConfig.isFirebase) {
      final callables = functions ?? FirebaseCallableFunctions();
      final attachmentStorage = FirebaseAttachmentStorage(
        bucket: BackendConfig.attachmentsBucket,
      );
      final attachments = AttachmentUploader(attachmentStorage);
      final accounts = AccountCallables(callables);
      final data = gateway ?? CallableDataGateway();
      final membersSource = SqlConnectOrganizationMembersRemoteDataSource(
        gateway: data,
      );
      final platformOrganizationsRepository =
          SqlConnectPlatformOrganizationsRepository(
            dataSource: SqlConnectPlatformOrganizationsRemoteDataSource(
              gateway: data,
            ),
            functions: callables,
          );
      return BackendRepositories(
        authRepository: FirebaseAuthRepository(
          auth: auth,
          firestore: firestore,
          functions: callables,
        ),
        accessRepository: SqlConnectAccessRepository(
          dataSource: SqlConnectAccessRemoteDataSource(gateway: data),
        ),
        platformRepository: SqlConnectPlatformDashboardRepository(
          gateway: data,
          organizations: platformOrganizationsRepository,
        ),
        platformOrganizationsRepository: platformOrganizationsRepository,
        licensePlansRepository: SqlConnectLicensePlansRepository(
          dataSource: SqlConnectLicensePlansRemoteDataSource(gateway: data),
        ),
        platformUsersRepository: SqlConnectPlatformUsersRepository(
          dataSource: SqlConnectPlatformUsersRemoteDataSource(gateway: data),
          accounts: accounts,
        ),
        orgRepository: SqlConnectOrganizationDashboardRepository(
          gateway: data,
          attendanceCounter: AttendanceDayCounter(
            firestore: firestore,
            now: now,
          ),
        ),
        branchRepository: SqlConnectBranchDashboardRepository(
          gateway: data,
          attendanceCounter: AttendanceDayCounter(
            firestore: firestore,
            now: now,
          ),
        ),
        employeeRepository: FirestoreEmployeeHomeRepository(
          firestore: firestore,
          functions: callables,
          locationProvider:
              locationProvider ??
              GatewayAttendanceLocationProvider(
                const GeolocatorDeviceLocationGateway(),
              ),
          now: now,
        ),
        branchManagementRepository: SqlConnectBranchManagementRepository(
          branches: SqlConnectBranchesRemoteDataSource(gateway: data),
          members: membersSource,
          functions: callables,
        ),
        organizationMembersRepository: SqlConnectOrganizationMembersRepository(
          dataSource: membersSource,
          accounts: accounts,
          firestore: firestore,
          attachments: attachments,
        ),
        attendanceRepository: FirestoreAttendanceRepository(
          functions: callables,
          firestore: firestore,
          now: now,
        ),
        returnsRepository: SqlConnectReturnsRepository(
          gateway: data,
          now: now,
          attachments: attachments,
        ),
        reportsRepository: SqlConnectReportsRepository(gateway: data),
        settingsRepository: FirestoreSettingsRepository(firestore: firestore),
        attachmentStorage: attachmentStorage,
      );
    }

    return createMockRepositories();
  }

  /// Builds the mock bundle with the shared fixtures that the real backend
  /// shares implicitly: one access data source (branches/assignments) and one
  /// organizations data source, so the platform dashboard, organization list
  /// and members/branches repositories always agree.
  ///
  /// [delay] overrides the simulated latency (tests pass [Duration.zero]).
  static BackendRepositories createMockRepositories({Duration? delay}) {
    final accessDataSource = MockAccessDataSource();
    final organizationsDataSource = MockPlatformOrganizationsDataSource();

    return BackendRepositories(
      authRepository: delay == null
          ? MockAuthenticationRepository()
          : MockAuthenticationRepository(delay: delay),
      accessRepository: MockAccessRepository(
        dataSource: accessDataSource,
        delay: delay ?? const Duration(milliseconds: 350),
      ),
      platformRepository: MockPlatformDashboardRepository(
        organizationsDataSource: organizationsDataSource,
        delay: delay ?? const Duration(milliseconds: 300),
      ),
      platformOrganizationsRepository: MockPlatformOrganizationsRepository(
        dataSource: organizationsDataSource,
      ),
      licensePlansRepository: MockLicensePlansRepository(),
      platformUsersRepository: MockPlatformUsersRepository(),
      orgRepository: delay == null
          ? MockOrganizationDashboardRepository()
          : MockOrganizationDashboardRepository(delay: delay),
      branchRepository: delay == null
          ? MockBranchDashboardRepository()
          : MockBranchDashboardRepository(delay: delay),
      employeeRepository: delay == null
          ? MockEmployeeHomeRepository()
          : MockEmployeeHomeRepository(delay: delay),
      branchManagementRepository: MockBranchManagementRepository(
        accessDataSource: accessDataSource,
      ),
      organizationMembersRepository: MockOrganizationMembersRepository(
        accessDataSource: accessDataSource,
      ),
      attendanceRepository: MockAttendanceRepository(),
      returnsRepository: delay == null
          ? MockReturnsRepository()
          : MockReturnsRepository(delay: delay),
      reportsRepository: delay == null
          ? MockReportsRepository()
          : MockReportsRepository(delay: delay),
      settingsRepository: delay == null
          ? MockSettingsRepository()
          : MockSettingsRepository(delay: delay),
      attachmentStorage: const MockAttachmentStorage(),
    );
  }
}
