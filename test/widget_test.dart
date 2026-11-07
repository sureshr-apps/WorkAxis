import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/app.dart';

import 'helpers/test_backend.dart';

void main() {
  testWidgets('WorkAxisApp smoke test launches on SignInScreen', (
    tester,
  ) async {
    final repos = buildTestBackend();

    await tester.pumpWidget(WorkAxisApp(repositories: repos));
    await tester.pumpAndSettle();

    expect(find.text('WorkAxis'), findsOneWidget);
    expect(find.text('Username, email, or phone number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    mockAuthOf(repos).dispose();
  });
}
