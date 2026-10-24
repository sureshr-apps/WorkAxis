/// Supported user roles in the WorkAxis application.
enum UserRole {
  platformOwner,
  platformAdmin,
  orgAdmin,
  branchManager,
  employee;

  bool get isPlatformLevel =>
      this == UserRole.platformOwner || this == UserRole.platformAdmin;

  bool get isCustomerLevel => !isPlatformLevel;

  String get displayName {
    switch (this) {
      case UserRole.platformOwner:
        return 'Platform Owner';
      case UserRole.platformAdmin:
        return 'Platform Administrator';
      case UserRole.orgAdmin:
        return 'Organization Admin';
      case UserRole.branchManager:
        return 'Branch Manager';
      case UserRole.employee:
        return 'Employee';
    }
  }
}
