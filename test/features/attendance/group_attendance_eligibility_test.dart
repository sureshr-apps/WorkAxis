import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/services/group_attendance_eligibility.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

import '../../helpers/fixed_clock.dart';

void main() {
  const eligibility = GroupAttendanceEligibility();
  final day = DateTime(2026, 11, 7);

  AttendanceEntry entry(
    String employeeId, {
    AttendanceStatus status = AttendanceStatus.present,
    DateTime? workDate,
    bool checkedIn = true,
  }) => AttendanceEntry(
    id: 'e-$employeeId',
    organizationId: 'org',
    branchId: 'br-01',
    employeeId: employeeId,
    employeeName: employeeId,
    workDate: workDate ?? day,
    status: status,
    reviewStatus: AttendanceReviewStatus.none,
    checkInAt: checkedIn ? testNow : null,
  );

  OrganizationMember member(
    String id, {
    UserRole role = UserRole.employee,
    AccountStatus status = AccountStatus.active,
    List<String> branches = const ['br-01'],
  }) => OrganizationMember(
    id: id,
    organizationId: 'org',
    fullName: id,
    username: id,
    email: '$id@example.com',
    role: role,
    branchIds: branches,
    status: status,
  );

  group('isRecorded', () {
    test('a present check-in on the day is recorded', () {
      expect(eligibility.isRecorded(entry('a'), day), isTrue);
    });

    test('a LATE check-in on the day is recorded too (no double entry)', () {
      expect(
        eligibility.isRecorded(entry('a', status: AttendanceStatus.late), day),
        isTrue,
      );
    });

    test('incomplete and absent entries with a check-in are recorded', () {
      expect(
        eligibility.isRecorded(
          entry('a', status: AttendanceStatus.incomplete),
          day,
        ),
        isTrue,
      );
    });

    test('an entry without a check-in is not recorded', () {
      expect(
        eligibility.isRecorded(
          entry('a', status: AttendanceStatus.absent, checkedIn: false),
          day,
        ),
        isFalse,
      );
    });

    test('an entry from another day is not recorded', () {
      expect(
        eligibility.isRecorded(
          entry('a', workDate: DateTime(2026, 11, 6)),
          day,
        ),
        isFalse,
      );
    });

    test('the time of day on either side is ignored', () {
      expect(
        eligibility.isRecorded(
          entry('a', workDate: DateTime(2026, 11, 7, 23, 59)),
          DateTime(2026, 11, 7, 0, 1),
        ),
        isTrue,
      );
    });
  });

  group('isEligible', () {
    test('active employee assigned to the branch is eligible', () {
      expect(eligibility.isEligible(member('m'), branchId: 'br-01'), isTrue);
    });

    test('inactive, non-employee, other-branch and no-branch are not', () {
      expect(
        eligibility.isEligible(
          member('m', status: AccountStatus.suspended),
          branchId: 'br-01',
        ),
        isFalse,
      );
      expect(
        eligibility.isEligible(
          member('m', role: UserRole.branchManager),
          branchId: 'br-01',
        ),
        isFalse,
      );
      expect(eligibility.isEligible(member('m'), branchId: 'br-02'), isFalse);
      expect(eligibility.isEligible(member('m'), branchId: null), isFalse);
    });
  });

  test(
    'unrecordedMembers pre-selects only eligible people with no check-in',
    () {
      final members = [
        member('present'),
        member('late'),
        member('fresh'),
        member('suspended', status: AccountStatus.suspended),
        member('elsewhere', branches: const ['br-02']),
      ];
      final entries = [
        entry('present'),
        entry('late', status: AttendanceStatus.late),
      ];

      final selected = eligibility.unrecordedMembers(
        members,
        branchId: 'br-01',
        entries: entries,
        day: day,
      );

      expect(selected.map((m) => m.id), ['fresh']);
    },
  );
}
