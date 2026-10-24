import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/features/access/domain/repositories/access_repository.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/branch_dashboard/data/mock_branch_dashboard_repository.dart';
import 'package:workaxis/features/branch_dashboard/domain/repositories/branch_dashboard_repository.dart';
import 'package:workaxis/features/branch_dashboard/presentation/controllers/branch_dashboard_controller.dart';
import 'package:workaxis/features/employee_home/data/mock_employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_repository.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/employee_home_controller.dart';
import 'package:workaxis/features/branches/data/mock_branch_management_repository.dart';
import 'package:workaxis/features/branches/domain/repositories/branch_management_repository.dart';
import 'package:workaxis/features/branches/presentation/controllers/branch_management_controller.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';
import 'package:workaxis/features/employees/presentation/controllers/organization_members_controller.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_repository.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:workaxis/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:workaxis/features/organization_dashboard/data/mock_organization_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/domain/repositories/organization_dashboard_repository.dart';
import 'package:workaxis/features/organization_dashboard/presentation/controllers/organization_dashboard_controller.dart';
import 'package:workaxis/features/platform_dashboard/data/mock_platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_dashboard/domain/repositories/platform_dashboard_repository.dart';
import 'package:workaxis/features/platform_dashboard/presentation/controllers/platform_dashboard_controller.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_data_source.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/platform_users/data/mock_platform_users_repository.dart';
import 'package:workaxis/features/platform_users/domain/repositories/platform_users_repository.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/returns/data/mock_returns_repository.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';
import 'package:workaxis/features/reports/data/mock_reports_repository.dart';
import 'package:workaxis/features/reports/domain/repositories/reports_repository.dart';
import 'package:workaxis/features/reports/presentation/controllers/reports_controller.dart';

/// Root WorkAxis application widget configuring providers, theming, and routing.
class WorkAxisApp extends StatefulWidget {
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
  final String? initialLocation;

  WorkAxisApp({
    Key? key,
    required AuthenticationRepository authRepository,
    required AccessRepository accessRepository,
    PlatformDashboardRepository? platformRepository,
    PlatformOrganizationsRepository? platformOrganizationsRepository,
    PlatformUsersRepository? platformUsersRepository,
    OrganizationDashboardRepository? orgRepository,
    BranchDashboardRepository? branchRepository,
    EmployeeHomeRepository? employeeRepository,
    BranchManagementRepository? branchManagementRepository,
    OrganizationMembersRepository? organizationMembersRepository,
    AttendanceRepository? attendanceRepository,
    ReturnsRepository? returnsRepository,
    ReportsRepository? reportsRepository,
    String? initialLocation,
  }) : this._(
         key: key,
         authRepository: authRepository,
         accessRepository: accessRepository,
         platformRepository: platformRepository,
         platformOrganizationsRepository: platformOrganizationsRepository,
         platformUsersRepository: platformUsersRepository,
         orgRepository: orgRepository,
         branchRepository: branchRepository,
         employeeRepository: employeeRepository,
         branchManagementRepository: branchManagementRepository,
         organizationMembersRepository: organizationMembersRepository,
         attendanceRepository: attendanceRepository,
         returnsRepository: returnsRepository,
         reportsRepository: reportsRepository,
         initialLocation: initialLocation,
         defaultOrgsDataSource: MockPlatformOrganizationsDataSource(),
         defaultAccessDataSource: MockAccessDataSource(),
       );

  WorkAxisApp._({
    super.key,
    required this.authRepository,
    required this.accessRepository,
    PlatformDashboardRepository? platformRepository,
    PlatformOrganizationsRepository? platformOrganizationsRepository,
    PlatformUsersRepository? platformUsersRepository,
    OrganizationDashboardRepository? orgRepository,
    BranchDashboardRepository? branchRepository,
    EmployeeHomeRepository? employeeRepository,
    BranchManagementRepository? branchManagementRepository,
    OrganizationMembersRepository? organizationMembersRepository,
    AttendanceRepository? attendanceRepository,
    ReturnsRepository? returnsRepository,
    ReportsRepository? reportsRepository,
    this.initialLocation,
    required MockPlatformOrganizationsDataSource defaultOrgsDataSource,
    required MockAccessDataSource defaultAccessDataSource,
  }) : platformOrganizationsRepository =
           platformOrganizationsRepository ??
           MockPlatformOrganizationsRepository(
             dataSource:
                 _extractOrgsDataSource(platformRepository) ??
                 defaultOrgsDataSource,
           ),
       platformUsersRepository =
           platformUsersRepository ?? MockPlatformUsersRepository(),
       platformRepository =
           platformRepository ??
           MockPlatformDashboardRepository(
             organizationsDataSource:
                 _extractOrgsDataSource(platformOrganizationsRepository) ??
                 defaultOrgsDataSource,
           ),
       orgRepository = orgRepository ?? MockOrganizationDashboardRepository(),
       branchRepository = branchRepository ?? MockBranchDashboardRepository(),
       employeeRepository = employeeRepository ?? MockEmployeeHomeRepository(),
       branchManagementRepository =
           branchManagementRepository ??
           MockBranchManagementRepository(
             accessDataSource:
                 _extractAccessDataSource(accessRepository) ??
                 defaultAccessDataSource,
           ),
       organizationMembersRepository =
           organizationMembersRepository ??
           MockOrganizationMembersRepository(
             accessDataSource:
                 _extractAccessDataSource(accessRepository) ??
                 defaultAccessDataSource,
           ),
       attendanceRepository =
           attendanceRepository ?? MockAttendanceRepository(),
       returnsRepository = returnsRepository ?? MockReturnsRepository(),
       reportsRepository = reportsRepository ?? MockReportsRepository();

  static MockPlatformOrganizationsDataSource? _extractOrgsDataSource(
    Object? repository,
  ) {
    if (repository is MockPlatformOrganizationsRepository) {
      return repository.dataSource;
    }
    if (repository is MockPlatformDashboardRepository) {
      return repository.dataSource.organizationsDataSource;
    }
    return null;
  }

  static MockAccessDataSource? _extractAccessDataSource(Object repository) {
    if (repository is MockAccessRepository) return repository.dataSource;
    return null;
  }

  @override
  State<WorkAxisApp> createState() => _WorkAxisAppState();
}

class _WorkAxisAppState extends State<WorkAxisApp> {
  late final AuthController _authController;
  late final AccessController _accessController;
  late final BranchContextController _branchController;
  late final PlatformDashboardController _platformController;
  late final PlatformOrganizationsController _platformOrganizationsController;
  late final PlatformUsersController _platformUsersController;
  late final OrganizationDashboardController _orgController;
  late final BranchDashboardController _branchDashboardController;
  late final EmployeeHomeController _employeeController;
  late final BranchManagementController _branchManagementController;
  late final OrganizationMembersController _organizationMembersController;
  late final AttendanceController _attendanceController;
  late final ReturnsController _returnsController;
  late final ReportsController _reportsController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(authRepository: widget.authRepository);
    _accessController = AccessController(
      accessRepository: widget.accessRepository,
    );
    _branchController = BranchContextController();
    _platformController = PlatformDashboardController(
      repository: widget.platformRepository,
    );
    _platformOrganizationsController = PlatformOrganizationsController(
      repository: widget.platformOrganizationsRepository,
    );
    _platformUsersController = PlatformUsersController(
      repository: widget.platformUsersRepository,
    );
    _orgController = OrganizationDashboardController(
      repository: widget.orgRepository,
    );
    _branchDashboardController = BranchDashboardController(
      repository: widget.branchRepository,
    );
    _employeeController = EmployeeHomeController(
      repository: widget.employeeRepository,
    );
    _branchManagementController = BranchManagementController(
      repository: widget.branchManagementRepository,
    );
    _organizationMembersController = OrganizationMembersController(
      repository: widget.organizationMembersRepository,
    );
    _attendanceController = AttendanceController(
      repository: widget.attendanceRepository,
    );
    _returnsController = ReturnsController(
      repository: widget.returnsRepository,
    );
    _reportsController = ReportsController(
      repository: widget.reportsRepository,
    );

    _router = createAppRouter(
      authController: _authController,
      accessController: _accessController,
      branchController: _branchController,
      initialLocation: widget.initialLocation ?? AppRoutes.signIn,
    );
  }

  @override
  void dispose() {
    _authController.dispose();
    _accessController.dispose();
    _branchController.dispose();
    _platformController.dispose();
    _platformOrganizationsController.dispose();
    _platformUsersController.dispose();
    _orgController.dispose();
    _branchDashboardController.dispose();
    _employeeController.dispose();
    _branchManagementController.dispose();
    _organizationMembersController.dispose();
    _attendanceController.dispose();
    _returnsController.dispose();
    _reportsController.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: _authController),
        ChangeNotifierProvider<AccessController>.value(
          value: _accessController,
        ),
        ChangeNotifierProvider<BranchContextController>.value(
          value: _branchController,
        ),
        ChangeNotifierProvider<PlatformDashboardController>.value(
          value: _platformController,
        ),
        ChangeNotifierProvider<PlatformOrganizationsController>.value(
          value: _platformOrganizationsController,
        ),
        ChangeNotifierProvider<PlatformUsersController>.value(
          value: _platformUsersController,
        ),
        ChangeNotifierProvider<OrganizationDashboardController>.value(
          value: _orgController,
        ),
        ChangeNotifierProvider<BranchDashboardController>.value(
          value: _branchDashboardController,
        ),
        ChangeNotifierProvider<EmployeeHomeController>.value(
          value: _employeeController,
        ),
        ChangeNotifierProvider<BranchManagementController>.value(
          value: _branchManagementController,
        ),
        ChangeNotifierProvider<OrganizationMembersController>.value(
          value: _organizationMembersController,
        ),
        ChangeNotifierProvider<AttendanceController>.value(
          value: _attendanceController,
        ),
        ChangeNotifierProvider<ReturnsController>.value(
          value: _returnsController,
        ),
        ChangeNotifierProvider<ReportsController>.value(
          value: _reportsController,
        ),
      ],
      child: MaterialApp.router(
        title: 'WorkAxis',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
