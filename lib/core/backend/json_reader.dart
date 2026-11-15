import 'package:workaxis/core/errors/app_exceptions.dart';

/// Typed accessors for JSON objects returned by the data gateway.
///
/// A missing or wrongly typed required field throws a [DatabaseException]
/// naming the field, instead of surfacing a raw cast error. Optional readers
/// (`opt*`) return null for absent or null values but still reject a value of
/// the wrong type. Numbers accept both `int` and `double` JSON numbers.
extension JsonReader on Map<String, dynamic> {
  String string(String key) => _required(key, optString(key));

  String? optString(String key) => _typed<String>(key, 'a string');

  int integer(String key) => _required(key, optInt(key));

  int? optInt(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num && value == value.truncateToDouble()) return value.toInt();
    throw _malformed(key, 'an integer');
  }

  double number(String key) => _required(key, optNumber(key));

  double? optNumber(String key) => _typed<num>(key, 'a number')?.toDouble();

  bool boolean(String key) => _required(key, optBool(key));

  bool? optBool(String key) => _typed<bool>(key, 'a boolean');

  /// Required JSON object.
  Map<String, dynamic> object(String key) => _required(key, optObject(key));

  Map<String, dynamic>? optObject(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw _malformed(key, 'an object');
  }

  /// Required array of JSON objects (an absent key is an error; use
  /// [optObjects] when the server may omit it).
  List<Map<String, dynamic>> objects(String key) =>
      _required(key, optObjects(key));

  List<Map<String, dynamic>>? optObjects(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is! List) throw _malformed(key, 'an array');
    return [
      for (final item in value)
        if (item is Map<String, dynamic>)
          item
        else if (item is Map)
          Map<String, dynamic>.from(item)
        else
          throw _malformed(key, 'an array of objects'),
    ];
  }

  /// ISO-8601 timestamp string.
  DateTime dateTime(String key) => _required(key, optDateTime(key));

  DateTime? optDateTime(String key) => _parseDate(key, optString(key));

  /// Calendar date (`YYYY-MM-DD`) as a [DateTime] at local midnight.
  DateTime dateOnly(String key) => _required(key, optDateOnly(key));

  DateTime? optDateOnly(String key) {
    final raw = optString(key);
    if (raw == null) return null;
    return _parseDate(key, raw.length < 10 ? raw : raw.substring(0, 10));
  }

  /// The single-row aggregate `[{"_count": n}]` under [key], or 0 when empty.
  int countOf(String key) {
    final rows = optObjects(key);
    if (rows == null || rows.isEmpty) return 0;
    return rows.first.integer('_count');
  }

  T? _typed<T>(String key, String expected) {
    final value = this[key];
    if (value == null) return null;
    if (value is T) return value;
    throw _malformed(key, expected);
  }

  T _required<T>(String key, T? value) {
    if (value == null) throw _malformed(key, 'present');
    return value;
  }

  DateTime? _parseDate(String key, String? raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) throw _malformed(key, 'an ISO-8601 date');
    return parsed;
  }

  DatabaseException _malformed(String key, String expected) =>
      DatabaseException('Malformed response: "$key" must be $expected.');
}

/// Reads the `_count` rows of a grouped aggregate such as
/// `[{"status": "pending", "_count": 3}]`, summing rows that share a key.
Map<String, int> groupedCounts(
  List<Map<String, dynamic>> rows,
  String keyField, {
  bool lowerCaseKeys = false,
}) {
  final out = <String, int>{};
  for (final row in rows) {
    var key = row.string(keyField);
    if (lowerCaseKeys) key = key.toLowerCase();
    out[key] = (out[key] ?? 0) + row.integer('_count');
  }
  return out;
}

/// Sum of `_count` across [rows].
int sumCounts(List<Map<String, dynamic>> rows) =>
    rows.fold(0, (sum, row) => sum + row.integer('_count'));
