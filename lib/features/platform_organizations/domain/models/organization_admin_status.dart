/// Operational status of an Organization Administrator account.
enum OrganizationAdminStatus {
  active,
  suspended;

  String get label => switch (this) {
    OrganizationAdminStatus.active => 'Active',
    OrganizationAdminStatus.suspended => 'Suspended',
  };

  static OrganizationAdminStatus fromAccountName(String? value) =>
      value == 'active'
      ? OrganizationAdminStatus.active
      : OrganizationAdminStatus.suspended;
}

/// Actions a Platform user can take on an Organization Administrator.
enum OrganizationAdminAction { edit, resetPassword, suspend, restore }
