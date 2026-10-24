import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Represents an authenticated user identity in WorkAxis.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.email,
    this.phone,
    this.organizationId,
    this.status = AccountStatus.active,
  });

  /// Unique user identity ID across the system.
  final String id;

  /// Display name of the user.
  final String name;

  /// Primary login handle/username.
  final String username;

  /// Optional email address alias.
  final String? email;

  /// Optional phone number alias.
  final String? phone;

  /// Role assigned to the user.
  final UserRole role;

  /// Account operational status.
  final AccountStatus status;

  /// Single organization ID for customer-level roles. Null for platform users.
  final String? organizationId;

  bool get isCustomerLevel => role.isCustomerLevel;
  bool get isPlatformLevel => role.isPlatformLevel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
