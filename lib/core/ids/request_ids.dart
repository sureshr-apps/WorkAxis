import 'dart:math';

/// Generates collision-resistant client identifiers.
///
/// Used only where the client must supply an idempotency key (for example the
/// `requestId` of the `provisionUser` callable). Entity ids are always
/// assigned by the server.
class RequestIds {
  RequestIds._();

  static final Random _secure = Random.secure();

  /// A random (version 4) UUID string.
  static String uuidV4([Random? random]) {
    final rng = random ?? _secure;
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int from, int to) => bytes
        .sublist(from, to)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  static const String _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Random human-readable code (no ambiguous characters).
  static String shortCode(int length, [Random? random]) {
    final rng = random ?? _secure;
    return List.generate(
      length,
      (_) => _codeAlphabet[rng.nextInt(_codeAlphabet.length)],
    ).join();
  }
}
