/// Account operational status.
enum AccountStatus {
  active,
  suspended,
  disabled;

  bool get isActive => this == AccountStatus.active;
}
