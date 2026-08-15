import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/core/theme/app_theme.dart';
import 'package:workaxis/features/access_control/data/datasources/access_remote_data_source.dart';
import 'package:workaxis/features/access_control/data/repositories/access_repository_impl.dart';
import 'package:workaxis/features/access_control/presentation/pages/access_denied_page.dart';
import 'package:workaxis/features/access_control/presentation/pages/account_disabled_page.dart';
import 'package:workaxis/features/access_control/presentation/pages/branch_assignment_required_page.dart';
import 'package:workaxis/features/access_control/presentation/pages/organization_unavailable_page.dart';
import 'package:workaxis/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:workaxis/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:workaxis/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:workaxis/features/organization/presentation/controllers/organization_context_controller.dart';

void main() {
  late InMemoryAuthDataSource authDataSource;
  late AuthRepositoryImpl authRepository;
  late InMemoryAccessDataSource accessDataSource;
  late AccessRepositoryImpl accessRepository;

  setUp(() {
    authDataSource = InMemoryAuthDataSource();
    authRepository = AuthRepositoryImpl(remoteDataSource: authDataSource);
    accessDataSource = InMemoryAccessDataSource();
    accessRepository = AccessRepositoryImpl(remoteDataSource: accessDataSource);
  });

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              OrganizationContextController(accessRepository: accessRepository),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: child,
      ),
    );
  }

  group('Access Control State Widgets', () {
    testWidgets('renders AccessDeniedPage correctly', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const AccessDeniedPage()));
      await tester.pumpAndSettle();

      expect(find.text('Access Denied'), findsOneWidget);
      expect(find.text('Try Another Account'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('renders AccountDisabledPage correctly', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const AccountDisabledPage()));
      await tester.pumpAndSettle();

      expect(find.text('Account Disabled'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('renders BranchAssignmentRequiredPage correctly',
        (tester) async {
      await tester
          .pumpWidget(wrapWithProviders(const BranchAssignmentRequiredPage()));
      await tester.pumpAndSettle();

      expect(find.text('Branch Assignment Required'), findsOneWidget);
      expect(find.text('Refresh Status'), findsOneWidget);
    });

    testWidgets('renders OrganizationUnavailablePage correctly',
        (tester) async {
      await tester
          .pumpWidget(wrapWithProviders(const OrganizationUnavailablePage()));
      await tester.pumpAndSettle();

      expect(find.text('Organization Unavailable'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });
}
