import 'package:equatable/equatable.dart';

enum OrgStatus { active, suspended, archived }

/// Organization entity in WorkAxis multi-tenant structure.
class Organization extends Equatable {
  const Organization({
    required this.id,
    required this.name,
    this.code,
    this.logoUrl,
    this.status = OrgStatus.active,
    this.address,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? code;
  final String? logoUrl;
  final OrgStatus status;
  final String? address;
  final DateTime? createdAt;

  bool get isUsable => status == OrgStatus.active;

  @override
  List<Object?> get props =>
      [id, name, code, logoUrl, status, address, createdAt];
}
