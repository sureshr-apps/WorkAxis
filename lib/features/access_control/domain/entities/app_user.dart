import 'package:equatable/equatable.dart';

enum AccountStatus { active, disabled, pending }

/// Application user profile associated with an authenticated identity.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.email,
    this.status = AccountStatus.active,
    this.createdAt,
  });

  final String id;
  final String phoneNumber;
  final String? name;
  final String? email;
  final AccountStatus status;
  final DateTime? createdAt;

  bool get isActive => status == AccountStatus.active;
  bool get isDisabled => status == AccountStatus.disabled;

  @override
  List<Object?> get props => [id, phoneNumber, name, email, status, createdAt];
}
