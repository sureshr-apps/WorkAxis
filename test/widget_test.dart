import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/app.dart';
import 'package:workaxis/features/access_control/data/datasources/access_remote_data_source.dart';
import 'package:workaxis/features/access_control/data/repositories/access_repository_impl.dart';
import 'package:workaxis/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:workaxis/features/authentication/data/repositories/auth_repository_impl.dart';

void main() {
  testWidgets('WorkAxisApp root smoke test', (WidgetTester tester) async {
    final authDataSource = InMemoryAuthDataSource();
    final authRepository = AuthRepositoryImpl(remoteDataSource: authDataSource);
    final accessDataSource = InMemoryAccessDataSource();
    final accessRepository =
        AccessRepositoryImpl(remoteDataSource: accessDataSource);

    await tester.pumpWidget(
      WorkAxisApp(
        authRepository: authRepository,
        accessRepository: accessRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WorkAxis'), findsOneWidget);
  });
}
