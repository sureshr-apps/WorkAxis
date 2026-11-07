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

  /// Parses a stored status. Anything other than ctive (including a
  /// missing or unknown value) is treated as suspended: malformed data must
  /// never grant access.
  static OrganizationStatus fromString(String? value) =>
      value?.toLowerCase().trim() == 'active'
      ? OrganizationStatus.active
      : OrganizationStatus.suspended;
}
