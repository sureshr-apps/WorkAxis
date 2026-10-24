/// Status enumeration for Customer Organizations.
enum OrganizationStatus {
  active,
  suspended;

  bool get isActive => this == OrganizationStatus.active;
  bool get isSuspended => this == OrganizationStatus.suspended;

  String get displayName {
    switch (this) {
      case OrganizationStatus.active:
        return 'Active';
      case OrganizationStatus.suspended:
        return 'Suspended';
    }
  }

  static OrganizationStatus fromString(String? value) {
    if (value == null) return OrganizationStatus.active;
    final normalized = value.toLowerCase().trim();
    if (normalized == 'suspended') {
      return OrganizationStatus.suspended;
    }
    return OrganizationStatus.active;
  }
}
