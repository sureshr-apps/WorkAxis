/// Defined user roles in WorkAxis.
enum UserRole {
  orgAdmin('Organization Admin'),
  branchManager('Branch Manager'),
  employee('Employee');

  const UserRole(this.displayName);
  final String displayName;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'orgadmin':
      case 'org_admin':
      case 'organization admin':
      case 'admin':
        return UserRole.orgAdmin;
      case 'branchmanager':
      case 'branch_manager':
      case 'branch manager':
      case 'manager':
        return UserRole.branchManager;
      case 'employee':
      case 'staff':
      default:
        return UserRole.employee;
    }
  }
}
