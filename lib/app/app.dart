import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/bootstrap/backend_factory.dart';
import 'package:workaxis/app/routing/app_router.dart';
import 'package:workaxis/app/routing/app_routes.dart';
import 'package:workaxis/app/session/session_controller.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:workaxis/features/assets/presentation/controllers/assets_controller.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/branch_dashboard/presentation/controllers/branch_dashboard_controller.dart';
import 'package:workaxis/features/branches/presentation/controllers/branch_management_controller.dart';
import 'package:workaxis/features/employee_home/presentation/controllers/employee_home_controller.dart';
import 'package:workaxis/features/employees/presentation/controllers/organization_members_controller.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';
import 'package:workaxis/features/organization_dashboard/presentation/controllers/organization_dashboard_controller.dart';
import 'package:workaxis/features/platform_dashboard/presentation/controllers/platform_dashboard_controller.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';
import 'package:workaxis/features/plans/presentation/controllers/license_plans_controller.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';
import 'package:workaxis/features/reports/presentation/controllers/reports_controller.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';
import 'package:workaxis/features/leaves/presentation/controllers/leaves_controller.dart';
import 'package:workaxis/features/off_site_work/presentation/controllers/off_site_work_controller.dart';
import 'package:workaxis/features/settings/presentation/controllers/settings_controller.dart';

/// Root WorkAxis application widget configuring providers, theming, and routing.
///
/// All repositories arrive as one [BackendRepositories] value (built by
/// [BackendFactory]), so a mock and a production repository can never be mixed
/// by forgetting an argument.
class WorkAxisApp extends StatefulWidget {
  const WorkAxisApp({
    super.key,
    required this.repositories,
    this.initialLocation,
  });

  final BackendRepositories repositories;
  final String? initialLocation;

  @override
  State<WorkAxisApp> createState() => _WorkAxisAppState();
}

class _WorkAxisAppState extends State<WorkAxisApp> {
  late final AuthController _authController;
  late final AccessController _accessController;
  late final BranchContextController _branchController;
  late final PlatformDashboardController _platformController;
  late final LicensePlansController _licensePlansController;
  late final PlatformOrganizationsController _platformOrganizationsController;
  late final PlatformUsersController _platformUsersController;
  late final OrganizationDashboardController _orgController;
  late final BranchDashboardController _branchDashboardController;
  late final EmployeeHomeController _employeeController;
  late final BranchManagementController _branchManagementController;
  late final OrganizationMembersController _organizationMembersController;
  late final AssetsController _assetsController;
  late final AttendanceController _attendanceController;
  late final ReturnsController _returnsController;
  late final LeavesController _leavesController;
  late final OffSiteWorkController _offSiteWorkController;
  late final ReportsController _reportsController;
  late final SettingsController _settingsController;
  late final SessionController _sessionController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final repos = widget.repositories;

    _authController = AuthController(authRepository: repos.authRepository);
    _branchController = BranchContextController();
    _accessController = AccessController(
      accessRepository: repos.accessRepository,
      onResolved: _branchController.initFromAccessContext,
    );
    _platformController = PlatformDashboardController(
      repository: repos.platformRepository,
    );
    _platformOrganizationsController = PlatformOrganizationsController(
      repository: repos.platformOrganizationsRepository,
    );
    _licensePlansController = LicensePlansController(
      repository: repos.licensePlansRepository,
    );
    _platformUsersController = PlatformUsersController(
      repository: repos.platformUsersRepository,
    );
    _orgController = OrganizationDashboardController(
      repository: repos.orgRepository,
    );
    _branchDashboardController = BranchDashboardController(
      repository: repos.branchRepository,
    );
    _employeeController = EmployeeHomeController(
      repository: repos.employeeRepository,
    );
    _branchManagementController = BranchManagementController(
      repository: repos.branchManagementRepository,
    );
    _organizationMembersController = OrganizationMembersController(
      repository: repos.organizationMembersRepository,
    );
    _assetsController = AssetsController(
      repository: repos.assetsRepository,
      membersRepository: repos.organizationMembersRepository,
    );
    _attendanceController = AttendanceController(
      repository: repos.attendanceRepository,
    );
    _returnsController = ReturnsController(repository: repos.returnsRepository);
    _leavesController = LeavesController(repository: repos.leavesRepository);
    _offSiteWorkController = OffSiteWorkController(
      repository: repos.offSiteWorkRepository,
    );
    _reportsController = ReportsController(repository: repos.reportsRepository);
    _settingsController = SettingsController(
      repository: repos.settingsRepository,
    );

    final branchScoped = <SessionScoped>[
      _branchDashboardController,
      _attendanceController,
      _returnsController,
      _leavesController,
      _offSiteWorkController,
      _organizationMembersController,
      _assetsController,
      _reportsController,
    ];
    _sessionController = SessionController(
      auth: _authController,
      access: _accessController,
      branch: _branchController,
      sessionScoped: [
        _platformController,
        _licensePlansController,
        _platformOrganizationsController,
        _platformUsersController,
        _orgController,
        _employeeController,
        _branchManagementController,
        _settingsController,
        ...branchScoped,
      ],
      branchScoped: branchScoped,
    );

    // Restore any previous session before the first redirect is evaluated.
    _authController.init();

    _router = createAppRouter(
      authController: _authController,
      accessController: _accessController,
      branchController: _branchController,
      initialLocation: widget.initialLocation ?? AppRoutes.signIn,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _sessionController.dispose();
    _authController.dispose();
    _accessController.dispose();
    _branchController.dispose();
    _platformController.dispose();
    _platformOrganizationsController.dispose();
    _licensePlansController.dispose();
    _platformUsersController.dispose();
    _orgController.dispose();
    _branchDashboardController.dispose();
    _employeeController.dispose();
    _branchManagementController.dispose();
    _organizationMembersController.dispose();
    _assetsController.dispose();
    _attendanceController.dispose();
    _returnsController.dispose();
    _leavesController.dispose();
    _offSiteWorkController.dispose();
    _reportsController.dispose();
    _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<OrganizationMembersRepository>.value(
          value: widget.repositories.organizationMembersRepository,
        ),
        Provider<AttachmentStorage>.value(
          value: widget.repositories.attachmentStorage,
        ),
        Provider<SessionController>.value(value: _sessionController),
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
        ChangeNotifierProvider<LicensePlansController>.value(
          value: _licensePlansController,
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
        ChangeNotifierProvider<AssetsController>.value(
          value: _assetsController,
        ),
        ChangeNotifierProvider<AttendanceController>.value(
          value: _attendanceController,
        ),
        ChangeNotifierProvider<ReturnsController>.value(
          value: _returnsController,
        ),
        ChangeNotifierProvider<LeavesController>.value(
          value: _leavesController,
        ),
        ChangeNotifierProvider<OffSiteWorkController>.value(
          value: _offSiteWorkController,
        ),
        ChangeNotifierProvider<ReportsController>.value(
          value: _reportsController,
        ),
        ChangeNotifierProvider<SettingsController>.value(
          value: _settingsController,
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
