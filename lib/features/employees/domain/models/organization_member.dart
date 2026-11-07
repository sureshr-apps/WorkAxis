import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

class OrganizationMember {
  const OrganizationMember({
    required this.id,
    required this.organizationId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.role,
    required this.branchIds,
    required this.status,
    this.phone,
    this.authUid,
  });

  /// SQL member id (assigned by the server).
  final String id;

  /// Firebase Auth uid of the account; the target of account callables.
  /// Null for seed rows that have no sign-in identity yet.
  final String? authUid;
  final String organizationId;
  final String fullName;
  final String username;
  final String email;
  final String? phone;
  final UserRole role;
  final List<String> branchIds;
  final AccountStatus status;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    return parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  OrganizationMember copyWith({
    String? id,
    String? authUid,
    String? fullName,
    String? username,
    String? email,
    String? phone,
    bool clearPhone = false,
    UserRole? role,
    List<String>? branchIds,
    AccountStatus? status,
  }) => OrganizationMember(
    id: id ?? this.id,
    authUid: authUid ?? this.authUid,
    organizationId: organizationId,
    fullName: fullName ?? this.fullName,
    username: username ?? this.username,
    email: email ?? this.email,
    phone: clearPhone ? null : phone ?? this.phone,
    role: role ?? this.role,
    branchIds: branchIds ?? this.branchIds,
    status: status ?? this.status,
  );
}
