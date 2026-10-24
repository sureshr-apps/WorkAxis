import 'package:workaxis/features/authentication/domain/models/account_status.dart';

/// A platform administrator profile managed by a Platform Owner.
///
/// Credentials are deliberately not part of this model.
class PlatformAdministrator {
  const PlatformAdministrator({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.status,
    required this.createdAt,
    this.phone,
    this.lastActiveAt,
  });

  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? phone;
  final AccountStatus status;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'PA';
    if (parts.length == 1) {
      final characterCount = parts.first.length >= 2 ? 2 : 1;
      return parts.first.substring(0, characterCount).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  PlatformAdministrator copyWith({
    String? fullName,
    String? username,
    String? email,
    String? phone,
    bool clearPhone = false,
    AccountStatus? status,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return PlatformAdministrator(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: clearPhone ? null : phone ?? this.phone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
