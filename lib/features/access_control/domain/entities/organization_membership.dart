import 'package:equatable/equatable.dart';
import 'package:workaxis/features/access_control/domain/entities/organization.dart';
import 'package:workaxis/features/access_control/domain/entities/user_role.dart';

enum MembershipStatus { active, suspended, pending }

/// Association between a user and an organization with a specific role and branch.
class OrganizationMembership extends Equatable {
  const OrganizationMembership({
    required this.id,
    required this.userId,
    required this.organizationId,
    required this.organization,
    required this.role,
    this.branchId,
    this.branchName,
    this.status = MembershipStatus.active,
    this.lastAccessedAt,
    this.permissions = const [],
  });

  final String id;
  final String userId;
  final String organizationId;
  final Organization organization;
  final UserRole role;
  final String? branchId;
  final String? branchName;
  final MembershipStatus status;
  final DateTime? lastAccessedAt;
  final List<String> permissions;

  bool get isActive =>
      status == MembershipStatus.active && organization.isUsable;

  bool get requiresBranch =>
      role == UserRole.branchManager || role == UserRole.employee;

  bool get hasValidBranch => branchId != null && branchId!.isNotEmpty;

  OrganizationMembership copyWith({
    String? id,
    String? userId,
    String? organizationId,
    Organization? organization,
    UserRole? role,
    String? branchId,
    String? branchName,
    MembershipStatus? status,
    DateTime? lastAccessedAt,
    List<String>? permissions,
  }) {
    return OrganizationMembership(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      organization: organization ?? this.organization,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      status: status ?? this.status,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        organizationId,
        organization,
        role,
        branchId,
        branchName,
        status,
        lastAccessedAt,
        permissions,
      ];
}
