import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/data/mock_platform_users_data_source.dart';
import 'package:workaxis/features/platform_users/domain/errors/platform_users_failure.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/domain/repositories/platform_users_repository.dart';

/// Mock repository boundary used by the Platform Users presentation layer.
class MockPlatformUsersRepository implements PlatformUsersRepository {
  MockPlatformUsersRepository({MockPlatformUsersDataSource? dataSource})
    : _dataSource = dataSource ?? MockPlatformUsersDataSource();

  final MockPlatformUsersDataSource _dataSource;

  @override
  Future<List<PlatformAdministrator>> getAdministrators({
    String? query,
    AccountStatus? status,
  }) async => _dataSource.getAdministrators(query: query, status: status);

  @override
  Future<PlatformAdministrator?> getAdministratorById(String id) async =>
      _dataSource.getById(id);

  @override
  Future<PlatformAdministrator> createAdministrator({
    required PlatformAdministrator administrator,
    required String initialPassword,
  }) async {
    if (initialPassword.length < 8) {
      throw const PlatformUsersFailure(
        'The initial password must contain at least 8 characters.',
      );
    }
    // The mock profile store intentionally receives no credential value.
    return _dataSource.create(administrator);
  }

  @override
  Future<PlatformAdministrator> updateAdministrator(
    PlatformAdministrator administrator,
  ) async => _dataSource.update(administrator);

  @override
  Future<PlatformAdministrator> updateAdministratorStatus(
    String id,
    AccountStatus status,
  ) async => _dataSource.updateStatus(id, status);
}
