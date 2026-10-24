/// A user-safe failure that a Platform Users repository may report.
class PlatformUsersFailure implements Exception {
  const PlatformUsersFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
