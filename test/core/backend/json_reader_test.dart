import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';

void main() {
  group('JsonReader', () {
    final json = <String, dynamic>{
      's': 'text',
      'i': 3,
      'whole': 4.0,
      'd': 2,
      'f': 1.5,
      'b': true,
      'nil': null,
      'o': {'k': 'v'},
      'list': [
        {'a': 1},
        {'a': 2},
      ],
      'ts': '2026-11-07T10:30:00.000Z',
      'date': '2026-11-07',
      'total': [
        {'_count': 7},
      ],
    };

    test('reads typed values', () {
      expect(json.string('s'), 'text');
      expect(json.integer('i'), 3);
      expect(json.integer('whole'), 4);
      expect(json.number('d'), 2.0);
      expect(json.number('f'), 1.5);
      expect(json.boolean('b'), isTrue);
      expect(json.object('o').string('k'), 'v');
      expect(json.objects('list').map((e) => e.integer('a')), [1, 2]);
      expect(json.dateTime('ts'), DateTime.utc(2026, 11, 7, 10, 30));
      expect(json.dateOnly('date'), DateTime(2026, 11, 7));
      expect(json.countOf('total'), 7);
    });

    test('optional readers return null for absent or null', () {
      expect(json.optString('nil'), isNull);
      expect(json.optString('missing'), isNull);
      expect(json.optInt('missing'), isNull);
      expect(json.optNumber('nil'), isNull);
      expect(json.optBool('missing'), isNull);
      expect(json.optObject('missing'), isNull);
      expect(json.optObjects('missing'), isNull);
      expect(json.optDateTime('missing'), isNull);
      expect(json.countOf('missing'), 0);
    });

    test('missing required or mistyped values throw DatabaseException', () {
      expect(() => json.string('missing'), throwsA(isA<DatabaseException>()));
      expect(() => json.string('i'), throwsA(isA<DatabaseException>()));
      expect(() => json.integer('f'), throwsA(isA<DatabaseException>()));
      expect(() => json.object('s'), throwsA(isA<DatabaseException>()));
      expect(() => json.objects('s'), throwsA(isA<DatabaseException>()));
      expect(() => json.dateTime('s'), throwsA(isA<DatabaseException>()));
    });

    test('groupedCounts sums rows sharing a key and sumCounts totals', () {
      final rows = [
        {'status': 'Pending', '_count': 2},
        {'status': 'pending', '_count': 3},
        {'status': 'approved', '_count': 1},
      ];
      expect(groupedCounts(rows, 'status', lowerCaseKeys: true), {
        'pending': 5,
        'approved': 1,
      });
      expect(sumCounts(rows), 6);
    });
  });
}
