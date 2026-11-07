/// Hides synthetic login addresses created for accounts without an email.
///
/// The server stores `<username>@login.workaxis.invalid` when an admin does
/// not supply an email (`docs/backend-api.md`). It must never be displayed.
class LoginEmail {
  LoginEmail._();

  static bool isSynthetic(String? email) =>
      email != null && email.trim().toLowerCase().endsWith('.invalid');

  /// The email to display, or an empty string when [email] is synthetic/null.
  static String displayable(String? email) =>
      email == null || isSynthetic(email) ? '' : email.trim();
}
