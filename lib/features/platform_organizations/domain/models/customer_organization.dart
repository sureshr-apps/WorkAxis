import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';

/// Domain entity representing a Customer Organization on the WorkAxis platform.
class CustomerOrganization {
  final String id;
  final String name;
  final String code;
  final OrganizationStatus status;
  final int branchCount;
  final int employeeCount;
  final DateTime createdAt;
  final String? description;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final String? taxIdentification;
  final List<OrganizationAdminUser> admins;

  const CustomerOrganization({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    required this.branchCount,
    required this.employeeCount,
    required this.createdAt,
    this.description,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.taxIdentification,
    this.admins = const [],
  });

  bool get isActive => status.isActive;
  bool get isSuspended => status.isSuspended;

  /// Returns 2-letter uppercase initials from the organization name.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words[0].isEmpty) return 'OR';
    if (words.length == 1) {
      final w = words[0];
      return w.substring(0, w.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  CustomerOrganization copyWith({
    String? id,
    String? name,
    String? code,
    OrganizationStatus? status,
    int? branchCount,
    int? employeeCount,
    DateTime? createdAt,
    String? description,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? address,
    String? taxIdentification,
    List<OrganizationAdminUser>? admins,
  }) {
    return CustomerOrganization(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      status: status ?? this.status,
      branchCount: branchCount ?? this.branchCount,
      employeeCount: employeeCount ?? this.employeeCount,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      taxIdentification: taxIdentification ?? this.taxIdentification,
      admins: admins ?? this.admins,
    );
  }
}
