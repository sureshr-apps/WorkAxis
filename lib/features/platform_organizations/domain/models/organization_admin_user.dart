import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_status.dart';

/// Read-only model representing an assigned Organization Administrator.
class OrganizationAdminUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? username;
  final String roleTitle;
  final OrganizationAdminStatus status;
  final String? lastLogin;

  /// Firebase Auth uid; the target of account callables. Null for mock data.
  final String? authUid;

  const OrganizationAdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.username,
    this.roleTitle = 'Organization Admin',
    this.status = OrganizationAdminStatus.active,
    this.lastLogin,
    this.authUid,
  });

  String get displayUsername {
    final handle =
        username ?? (email.contains('@') ? email.split('@').first : name);
    return '@$handle';
  }

  OrganizationAdminUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? username,
    String? roleTitle,
    OrganizationAdminStatus? status,
    String? lastLogin,
    String? authUid,
  }) {
    return OrganizationAdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      roleTitle: roleTitle ?? this.roleTitle,
      status: status ?? this.status,
      lastLogin: lastLogin ?? this.lastLogin,
      authUid: authUid ?? this.authUid,
    );
  }

  /// Derives 1 or 2 letter initials from the person's name.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'OA';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
