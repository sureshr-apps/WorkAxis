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
    this.employeeCode,
  });

  final String uid;
  final String memberId;
  final String username;
  final String loginEmail;

  /// Employee ID assigned (or accepted) by the server; null for platform roles.
  final String? employeeCode;
}

/// Optional profile fields `updateUserAccount` can clear.
///
/// Wire contract: a key omitted from the payload means "unchanged"; an explicit
/// `null` means "clear the stored value". `dailyWorkHours`, `shiftHours` and
/// `employeeCode` are required and can never be cleared.
enum ClearableProfileField {
  aadhaarNumber,
  aadhaarPhotoUrl,
  dateOfBirth,
  gender,
  address,
  profilePhotoUrl,
  designation,
  joiningDate,
  relievingDate,
  salary,
  assetDetails,
}

/// Typed wrapper over the account-management callables
/// (`provisionUser`, `updateUserAccount`, `resetUserPassword`,
/// `setUserStatus`, `deleteOrganization`). Payloads are documented in `docs/backend-api.md`.
///
/// Optional values are omitted rather than sent as null, except where a field
/// is being cleared: `phone`/`email` (flags) and the [ClearableProfileField]s
/// in `update(clear: ...)` are sent as an explicit null.
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
    double? dailyWorkHours,
    String? shiftHours,
    String? employeeCode,
    String? aadhaarNumber,
    String? aadhaarPhotoUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? profilePhotoUrl,
    String? designation,
    DateTime? joiningDate,
    DateTime? relievingDate,
    double? salary,
    String? assetDetails,
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
      'dailyWorkHours': ?dailyWorkHours,
      if (shiftHours != null && shiftHours.isNotEmpty) 'shiftHours': shiftHours,
      'employeeCode': ?employeeCode,
      'aadhaarNumber': ?aadhaarNumber,
      'aadhaarPhotoUrl': ?aadhaarPhotoUrl,
      'dateOfBirth': ?dateOfBirth?.toIso8601String().split('T').first,
      'gender': ?gender,
      'address': ?address,
      'profilePhotoUrl': ?profilePhotoUrl,
      'designation': ?designation,
      'joiningDate': ?joiningDate?.toIso8601String().split('T').first,
      'relievingDate': ?relievingDate?.toIso8601String().split('T').first,
      'salary': ?salary,
      'assetDetails': ?assetDetails,
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
      employeeCode: response['employeeCode'] as String?,
    );
  }

  /// Updates the supplied fields. [clearPhone] removes the phone alias; every
  /// field in [clear] is sent as an explicit null so the server removes it.
  /// A field is either set or cleared, never both.
  Future<void> update({
    required String targetUid,
    String? fullName,
    String? email,
    String? phone,
    bool clearPhone = false,
    bool clearEmail = false,
    UserRole? role,
    List<String>? branchIds,
    double? dailyWorkHours,
    String? shiftHours,
    String? employeeCode,
    String? aadhaarNumber,
    String? aadhaarPhotoUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? profilePhotoUrl,
    String? designation,
    DateTime? joiningDate,
    DateTime? relievingDate,
    double? salary,
    String? assetDetails,
    Set<ClearableProfileField> clear = const {},
  }) async {
    final payload = <String, dynamic>{
      'targetUid': targetUid,
      'fullName': ?fullName,
      if (clearEmail)
        'email': null
      else if (email != null && email.isNotEmpty)
        'email': email,
      if (clearPhone) 'phone': null else 'phone': ?phone,
      'role': ?role?.name,
      'branchIds': ?branchIds,
      'dailyWorkHours': ?dailyWorkHours,
      if (shiftHours != null && shiftHours.isNotEmpty) 'shiftHours': shiftHours,
      'employeeCode': ?employeeCode,
      'aadhaarNumber': ?aadhaarNumber,
      'aadhaarPhotoUrl': ?aadhaarPhotoUrl,
      'dateOfBirth': ?dateOfBirth?.toIso8601String().split('T').first,
      'gender': ?gender,
      'address': ?address,
      'profilePhotoUrl': ?profilePhotoUrl,
      'designation': ?designation,
      'joiningDate': ?joiningDate?.toIso8601String().split('T').first,
      'relievingDate': ?relievingDate?.toIso8601String().split('T').first,
      'salary': ?salary,
      'assetDetails': ?assetDetails,
    };
    for (final field in clear) {
      assert(
        !payload.containsKey(field.name),
        '${field.name} cannot be both set and cleared',
      );
      payload[field.name] = null;
    }
    await _functions.call('updateUserAccount', payload);
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

  /// Permanently deletes a Platform Administrator (`deletePlatformAdministrator`).
  Future<void> deletePlatformAdministrator({required String targetUid}) async {
    await _functions.call('deletePlatformAdministrator', {
      'targetUid': targetUid,
    });
  }

  /// Permanently deletes a customer organization (`deleteOrganization`); the
  /// server removes the organization and its dependent records.
  Future<void> deleteOrganization(String organizationId) async {
    await _functions.call('deleteOrganization', {
      'organizationId': organizationId,
    });
  }
}
