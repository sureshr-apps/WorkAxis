import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/data/mock_platform_users_data_source.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/domain/platform_administrator_validator.dart';
import 'package:workaxis/features/platform_users/domain/repositories/platform_users_repository.dart';

/// Mock repository boundary used by the Platform Users presentation layer.
/// Applies the same validation as production through
/// [PlatformAdministratorValidator].
class MockPlatformUsersRepository implements PlatformUsersRepository {
  MockPlatformUsersRepository({MockPlatformUsersDataSource? dataSource})
    : _dataSource = dataSource ?? MockPlatformUsersDataSource();

  final MockPlatformUsersDataSource _dataSource;

  @override
  Future<PageResult<PlatformAdministrator>> getAdministratorsPage({
    String? query,
    AccountStatus? status,
    int offset = 0,
    int limit = defaultPageSize,
  }) async {
    final all = _dataSource.getAdministrators(query: query, status: status);
    final start = offset.clamp(0, all.length);
    final end = (offset + limit).clamp(0, all.length);
    return PageResult(
      items: all.sublist(start, end),
      total: all.length,
      offset: start,
    );
  }

  @override
  Future<int> countAdministrators({AccountStatus? status}) async =>
      _dataSource.count(status: status);

  @override
  Future<PlatformAdministrator?> getAdministratorById(String id) async =>
      _dataSource.getById(id);

  @override
  Future<PlatformAdministrator> createAdministrator({
    required PlatformAdministrator administrator,
    required String initialPassword,
  }) async {
    final prepared = PlatformAdministratorValidator.prepare(
      administrator,
      isCreate: true,
      initialPassword: initialPassword,
    );
    // The mock profile store intentionally receives no credential value.
    return _dataSource.create(prepared);
  }

  @override
  Future<PlatformAdministrator> updateAdministrator(
    PlatformAdministrator administrator,
  ) async => _dataSource.update(
    PlatformAdministratorValidator.prepare(administrator, isCreate: false),
  );

  @override
  Future<PlatformAdministrator> updateAdministratorStatus(
    String id,
    AccountStatus status,
  ) async => _dataSource.updateStatus(id, status);

  @override
  Future<void> resetAdministratorPassword({
    required String id,
    required String newPassword,
  }) async {
    if (_dataSource.getById(id) == null) {
      throw ValidationException('Administrator not found.');
    }
    final error = ContactValidators.password(newPassword);
    if (error != null) throw ValidationException(error);
  }
}
