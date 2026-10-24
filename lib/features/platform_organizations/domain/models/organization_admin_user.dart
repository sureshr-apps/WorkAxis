/// Read-only model representing an assigned Organization Administrator.
class OrganizationAdminUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? username;
  final String roleTitle;
  final String status;
  final String? lastLogin;

  const OrganizationAdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.username,
    this.roleTitle = 'Organization Admin',
    this.status = 'Active',
    this.lastLogin,
  });

  String get displayUsername => '@${username ?? email.split('@').first}';

  OrganizationAdminUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? username,
    String? roleTitle,
    String? status,
    String? lastLogin,
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
