import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/routing/app_router.dart';
import 'package:workaxis/core/theme/app_theme.dart';
import 'package:workaxis/features/access_control/domain/repositories/access_repository.dart';
import 'package:workaxis/features/authentication/domain/repositories/auth_repository.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

class WorkAxisApp extends StatefulWidget {
  const WorkAxisApp({
    required this.authRepository,
    required this.accessRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final AccessRepository accessRepository;

  @override
  State<WorkAxisApp> createState() => _WorkAxisAppState();
}

class _WorkAxisAppState extends State<WorkAxisApp> {
  late final AuthController _authController;
  late final OrganizationContextController _orgController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(authRepository: widget.authRepository);
    _orgController = OrganizationContextController(
        accessRepository: widget.accessRepository);
    _router = AppRouter.createRouter(
      authController: _authController,
      orgController: _orgController,
    );
  }

  @override
  void dispose() {
    _authController.dispose();
    _orgController.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authController),
        ChangeNotifierProvider.value(value: _orgController),
      ],
      child: MaterialApp.router(
        title: 'WorkAxis',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}
