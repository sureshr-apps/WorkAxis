import 'package:flutter/widgets.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';

/// Per-field validation messages for the organization form.
class OrganizationFormErrors {
  const OrganizationFormErrors({
    this.name,
    this.address,
    this.contactName,
    this.email,
    this.phone,
  });

  final String? name;
  final String? address;
  final String? contactName;
  final String? email;
  final String? phone;

  bool get hasErrors =>
      name != null ||
      address != null ||
      contactName != null ||
      email != null ||
      phone != null;

  /// The same errors without the name error (cleared once the user types).
  OrganizationFormErrors withoutName() => OrganizationFormErrors(
    address: address,
    contactName: contactName,
    email: email,
    phone: phone,
  );
}

/// Text controllers plus validation and mapping for the add and edit
/// organization forms. Owned (and disposed) by the screen state.
class OrganizationFormState {
  OrganizationFormState();

  final name = TextEditingController();
  final taxIdentification = TextEditingController();
  final address = TextEditingController();
  final description = TextEditingController();
  final contactName = TextEditingController();
  final contactEmail = TextEditingController();
  final contactPhone = TextEditingController();

  List<TextEditingController> get _all => [
    name,
    taxIdentification,
    address,
    description,
    contactName,
    contactEmail,
    contactPhone,
  ];

  /// Registers [listener] on every field.
  void addListener(VoidCallback listener) {
    for (final c in _all) {
      c.addListener(listener);
    }
  }

  void removeListener(VoidCallback listener) {
    for (final c in _all) {
      c.removeListener(listener);
    }
  }

  /// Copies [org] into the fields.
  void populate(CustomerOrganization org) {
    name.text = org.name;
    taxIdentification.text = org.taxIdentification ?? '';
    address.text = org.address ?? '';
    description.text = org.description ?? '';
    contactName.text = org.contactName ?? '';
    contactEmail.text = org.contactEmail ?? '';
    contactPhone.text = org.contactPhone ?? '';
  }

  /// Validates the fields. Email and tax id are optional and only checked when
  /// the user entered a value. When [requiresContactDetails] is true, the
  /// headquarters address, contact person and contact phone are also required.
  OrganizationFormErrors validate({
    required String missingNameMessage,
    bool requiresContactDetails = false,
  }) {
    return OrganizationFormErrors(
      name: name.text.trim().isEmpty ? missingNameMessage : null,
      address: requiresContactDetails && address.text.trim().isEmpty
          ? 'Enter the headquarters address.'
          : null,
      contactName: requiresContactDetails && contactName.text.trim().isEmpty
          ? 'Enter the contact person name.'
          : null,
      email: ContactValidators.optionalEmail(contactEmail.text),
      phone: requiresContactDetails
          ? _requiredPhoneError()
          : ContactValidators.optionalPhone(contactPhone.text),
    );
  }

  String? _requiredPhoneError() {
    if (contactPhone.text.trim().isEmpty) {
      return 'Enter the contact phone number.';
    }
    return ContactValidators.optionalPhone(contactPhone.text);
  }

  CreateOrganizationRequest toCreateRequest() => CreateOrganizationRequest(
    name: name.text.trim(),
    taxIdentification: _orNull(taxIdentification),
    address: _orNull(address),
    description: _orNull(description),
    contactName: _orNull(contactName),
    contactEmail: _orNull(contactEmail),
    contactPhone: _orNull(contactPhone),
  );

  /// [original] with the form values applied. Blank optional fields become
  /// null so they clear on the server.
  CustomerOrganization applyTo(CustomerOrganization original) {
    return CustomerOrganization(
      id: original.id,
      name: name.text.trim(),
      code: original.code,
      status: original.status,
      branchCount: original.branchCount,
      employeeCount: original.employeeCount,
      createdAt: original.createdAt,
      category: original.category,
      taxIdentification: _orNull(taxIdentification),
      address: _orNull(address),
      description: _orNull(description),
      contactName: _orNull(contactName),
      contactEmail: _orNull(contactEmail),
      contactPhone: _orNull(contactPhone),
      admins: original.admins,
    );
  }

  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
  }

  static String? _orNull(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }
}
