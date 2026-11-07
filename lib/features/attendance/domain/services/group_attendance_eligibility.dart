import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';

/// Decides who can be included in a manager's group check-in.
///
/// * **Recorded**: the employee has any check-in on the same business day,
///   whatever its status (present, late, ...). Recording them again would
///   create a duplicate for the day.
/// * **Eligible**: an active employee assigned to the branch.
class GroupAttendanceEligibility {
  const GroupAttendanceEligibility();

  /// The id attendance entries use for [member]: the Firebase uid when the
  /// account has one (employee punches and the security rules key on it),
  /// otherwise the member id.
  String attendanceId(OrganizationMember member) => member.authUid ?? member.id;

  /// Whether [entry] is a check-in recorded for the business [day].
  bool isRecorded(AttendanceEntry entry, DateTime day) =>
      entry.checkInAt != null && _sameDay(entry.workDate, day);

  /// Whether [employeeId] already has a check-in on [day] in [entries].
  bool hasRecorded(
    String employeeId,
    Iterable<AttendanceEntry> entries,
    DateTime day,
  ) => entries.any((e) => e.employeeId == employeeId && isRecorded(e, day));

  /// Whether [member] is an active employee assigned to [branchId].
  bool isEligible(OrganizationMember member, {required String? branchId}) =>
      branchId != null &&
      member.role == UserRole.employee &&
      member.status == AccountStatus.active &&
      member.branchIds.contains(branchId);

  /// The members of [members] that may be recorded for [branchId].
  List<OrganizationMember> eligibleMembers(
    Iterable<OrganizationMember> members, {
    required String? branchId,
  }) => members.where((m) => isEligible(m, branchId: branchId)).toList();

  /// Eligible members with no check-in on [day]: the default selection.
  List<OrganizationMember> unrecordedMembers(
    Iterable<OrganizationMember> members, {
    required String? branchId,
    required Iterable<AttendanceEntry> entries,
    required DateTime day,
  }) => eligibleMembers(
    members,
    branchId: branchId,
  ).where((m) => !hasRecorded(attendanceId(m), entries, day)).toList();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
