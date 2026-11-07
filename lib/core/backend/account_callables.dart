import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Result of `provisionUser`.
class ProvisionedAccount {
  const ProvisionedAccount({
    required this.uid,
    required this.memberId,
    required this.username,
    required this.loginEmail,
  });

  final String uid;
  final String memberId;
  final String username;
  final String loginEmail;
}

/// Typed wrapper over the account-management callables
/// (`provisionUser`, `updateUserAccount`, `resetUserPassword`,
/// `setUserStatus`). Payloads are documented in `docs/backend-api.md`.
///
/// Optional values are omitted rather than sent as null, except `phone` where
/// null explicitly clears the alias.
class AccountCallables {
  AccountCallables(this._functions);

  final CallableFunctions _functions;

  Future<ProvisionedAccount> provision({
    required String requestId,
    required String fullName,
    required String username,
    required String password,
    required UserRole role,
    String? email,
    String? phone,
    String? organizationId,
    List<String> branchIds = const [],
  }) async {
    final response = await _functions.call('provisionUser', {
      'requestId': requestId,
      'fullName': fullName,
      'username': username,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'password': password,
      'role': role.name,
      'organizationId': ?organizationId,
      if (branchIds.isNotEmpty) 'branchIds': branchIds,
    });
    final uid = response['uid'];
    final memberId = response['memberId'];
    if (uid is! String || memberId is! String) {
      throw const DatabaseException('provisionUser returned no identifiers');
    }
    return ProvisionedAccount(
      uid: uid,
      memberId: memberId,
      username: response['username'] as String? ?? username,
      loginEmail: response['loginEmail'] as String? ?? '',
    );
  }

  /// Updates the supplied fields. [clearPhone] removes the phone alias.
  Future<void> update({
    required String targetUid,
    String? fullName,
    String? email,
    String? phone,
    bool clearPhone = false,
    UserRole? role,
    List<String>? branchIds,
  }) async {
    await _functions.call('updateUserAccount', {
      'targetUid': targetUid,
      'fullName': ?fullName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (clearPhone) 'phone': null else 'phone': ?phone,
      'role': ?role?.name,
      'branchIds': ?branchIds,
    });
  }

  Future<void> resetPassword({
    required String targetUid,
    required String newPassword,
  }) async {
    await _functions.call('resetUserPassword', {
      'targetUid': targetUid,
      'newPassword': newPassword,
    });
  }

  Future<void> setStatus({
    required String targetUid,
    required AccountStatus status,
  }) async {
    await _functions.call('setUserStatus', {
      'targetUid': targetUid,
      'status': status == AccountStatus.active ? 'active' : 'suspended',
    });
  }
}
