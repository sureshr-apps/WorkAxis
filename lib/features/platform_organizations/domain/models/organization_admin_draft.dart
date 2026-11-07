/// Fields entered when adding or editing an Organization Administrator.
///
/// [initialPassword] is only used when creating an account and is never
/// stored by the client.
class OrganizationAdminDraft {
  const OrganizationAdminDraft({
    required this.name,
    required this.username,
    this.email = '',
    this.phone = '',
    this.initialPassword,
  });

  final String name;
  final String username;
  final String email;
  final String phone;
  final String? initialPassword;
}
