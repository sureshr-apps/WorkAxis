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
  });

  final String id;
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
    String? fullName,
    String? username,
    String? email,
    String? phone,
    UserRole? role,
    List<String>? branchIds,
    AccountStatus? status,
  }) => OrganizationMember(
    id: id,
    organizationId: organizationId,
    fullName: fullName ?? this.fullName,
    username: username ?? this.username,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    branchIds: branchIds ?? this.branchIds,
    status: status ?? this.status,
  );
}
