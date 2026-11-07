/// Organization details submitted to create a tenant.
///
/// The repository implementation assigns system-managed identifiers such as
/// the organization ID and code.
class CreateOrganizationRequest {
  final String name;
  final String? taxIdentification;
  final String? description;
  final String? category;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;

  const CreateOrganizationRequest({
    required this.name,
    this.taxIdentification,
    this.description,
    this.category,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.address,
  });
}
