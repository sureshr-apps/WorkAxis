import 'package:workaxis/app/bootstrap/backend_factory.dart';
import 'package:workaxis/features/authentication/data/mock_auth_repository.dart';

/// Hermetic mock backend for widget/app tests: zero simulated latency and the
/// same shared fixtures the production mock bundle uses.
BackendRepositories buildTestBackend() =>
    BackendFactory.createMockRepositories(delay: Duration.zero);

/// Convenience accessor for the mock auth repository inside [repos].
MockAuthenticationRepository mockAuthOf(BackendRepositories repos) =>
    repos.authRepository as MockAuthenticationRepository;
