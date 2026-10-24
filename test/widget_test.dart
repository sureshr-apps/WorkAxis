import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/app.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';

void main() {
  testWidgets('WorkAxisApp smoke test launches on SignInScreen', (
    tester,
  ) async {
    final authRepository = MockAuthenticationRepository(delay: Duration.zero);
    final accessRepository = MockAccessRepository(delay: Duration.zero);

    await tester.pumpWidget(
      WorkAxisApp(
        authRepository: authRepository,
        accessRepository: accessRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WorkAxis'), findsOneWidget);
    expect(find.text('Username, email, or phone number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    authRepository.dispose();
  });
}
