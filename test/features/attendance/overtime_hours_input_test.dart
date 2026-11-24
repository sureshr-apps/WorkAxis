import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/attendance/presentation/overtime_hours_input.dart';

void main() {
  group('OvertimeHoursInput', () {
    test('starts from the potential hours', () {
      expect(OvertimeHoursInput.initialText(2), '2');
      expect(OvertimeHoursInput.initialText(1.75), '1.75');
    });

    test('accepts values up to the potential with two decimals', () {
      expect(OvertimeHoursInput.validate('2', 2), isNull);
      expect(OvertimeHoursInput.validate('1.25', 2), isNull);
      expect(OvertimeHoursInput.parse(' 1.5 ', 2), 1.5);
    });

    test('rejects empty, zero, over-limit and over-precise values', () {
      expect(OvertimeHoursInput.validate('', 2), 'Enter the hours to approve.');
      expect(OvertimeHoursInput.validate('0', 2), contains('more than 0'));
      expect(OvertimeHoursInput.validate('2.01', 2), contains('At most 2h'));
      expect(OvertimeHoursInput.validate('1.234', 2), contains('2 decimals'));
      expect(OvertimeHoursInput.validate('abc', 2), contains('2 decimals'));
      expect(OvertimeHoursInput.parse('3', 2), isNull);
    });
  });
}
