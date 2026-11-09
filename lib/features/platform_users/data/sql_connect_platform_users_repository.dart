import 'package:workaxis/core/backend/account_callables.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/ids/request_ids.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/platform_users/data/platform_users_remote_data_source.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/domain/platform_administrator_validator.dart';
import 'package:workaxis/features/platform_users/domain/repositories/platform_users_repository.dart';

/// Production [PlatformUsersRepository].
///
/// Reads come from SQL Connect; create, update, status and password changes go
/// through the account callables, which also own Firebase Auth, claims and
/// alias maintenance. The client never writes `users` or `user_aliases`.
class SqlConnectPlatformUsersRepository implements PlatformUsersRepository {
  SqlConnectPlatformUsersRepository({
    required this._dataSource,
    required this._accounts,
  });

  final PlatformUsersRemoteDataSource _dataSource;
  final AccountCallables _accounts;
  final Map<String, String> _pendingRequestIds = {};

  @override
  Future<PageResult<PlatformAdministrator>> getAdministratorsPage({
    String? query,
    AccountStatus? status,
    int offset = 0,
    int limit = defaultPageSize,
  }) => _guard(
    () => _dataSource.listPage(
      limit: limit,
      offset: offset,
      nameContains: query,
      status: status,
    ),
  );

  @override
  Future<int> countAdministrators({AccountStatus? status}) =>
      _guard(() => _dataSource.count(status: status));

  @override
  Future<PlatformAdministrator?> getAdministratorById(String id) =>
      _guard(() => _dataSource.getById(id));

  @override
  Future<PlatformAdministrator> createAdministrator({
    required PlatformAdministrator administrator,
    required String initialPassword,
  }) => _guard(() async {
    final prepared = PlatformAdministratorValidator.prepare(
      administrator,
      isCreate: true,
      initialPassword: initialPassword,
    );
    final requestId = _pendingRequestIds.putIfAbsent(
      prepared.username,
      RequestIds.uuidV4,
    );
    final result = await _accounts.provision(
      requestId: requestId,
      fullName: prepared.fullName,
      username: prepared.username,
      email: prepared.email,
      phone: prepared.phone,
      password: initialPassword,
      role: UserRole.platformAdmin,
    );
    _pendingRequestIds.remove(prepared.username);
    return _require(result.memberId);
  });

  @override
  Future<PlatformAdministrator> updateAdministrator(
    PlatformAdministrator administrator,
  ) => _guard(() async {
    final existing = await _require(administrator.id);
    final prepared = PlatformAdministratorValidator.prepare(
      administrator,
      isCreate: false,
    );
    final hadPhone = (existing.phone ?? '').isNotEmpty;
    final nextPhone = prepared.phone ?? '';
    await _accounts.update(
      targetUid: _uid(existing),
      fullName: prepared.fullName,
      email: prepared.email != existing.email ? prepared.email : null,
      clearEmail:
          prepared.email.trim().isEmpty && prepared.email != existing.email,
      phone: nextPhone.isNotEmpty && nextPhone != existing.phone
          ? nextPhone
          : null,
      clearPhone: hadPhone && nextPhone.isEmpty,
    );
    return _require(existing.id);
  });

  @override
  Future<PlatformAdministrator> updateAdministratorStatus(
    String id,
    AccountStatus status,
  ) => _guard(() async {
    final existing = await _require(id);
    await _accounts.setStatus(targetUid: _uid(existing), status: status);
    return _require(existing.id);
  });

  @override
  Future<void> resetAdministratorPassword({
    required String id,
    required String newPassword,
  }) => _guard(() async {
    final passwordError = ContactValidators.password(newPassword);
    if (passwordError != null) throw ValidationException(passwordError);
    final existing = await _require(id);
    await _accounts.resetPassword(
      targetUid: _uid(existing),
      newPassword: newPassword,
    );
  });

  Future<PlatformAdministrator> _require(String id) async {
    final admin = await _dataSource.getById(id);
    if (admin == null) {
      throw const NotFoundException('Platform administrator not found');
    }
    return admin;
  }

  String _uid(PlatformAdministrator admin) {
    final uid = admin.authUid;
    if (uid == null || uid.isEmpty) {
      throw ValidationException(
        'This account has no sign-in identity yet and cannot be changed here.',
      );
    }
    return uid;
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }
}
