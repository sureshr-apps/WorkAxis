import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

class MockAttendanceRepository implements AttendanceRepository {
  MockAttendanceRepository() {
    final today = DateTime.now();
    final entries = [
      _entry(
        'att-01',
        'br-01',
        'user-emp-01',
        'Sarah Connor',
        today,
        AttendanceStatus.present,
        AttendanceReviewStatus.none,
        8,
        2,
        true,
      ),
      _entry(
        'att-02',
        'br-01',
        'user-emp-02',
        'Alex Chen',
        today,
        AttendanceStatus.late,
        AttendanceReviewStatus.needsReview,
        9,
        null,
        false,
        note: 'Check-in was 18 minutes after shift start.',
      ),
      _entry(
        'att-03',
        'br-01',
        'user-emp-05',
        'Mina Patel',
        today,
        AttendanceStatus.incomplete,
        AttendanceReviewStatus.needsReview,
        8,
        null,
        true,
        note: 'Kiosk check-in has no matching check-out.',
      ),
      _entry(
        'att-04',
        'br-02',
        'user-emp-03',
        'Priya Shah',
        today,
        AttendanceStatus.present,
        AttendanceReviewStatus.verified,
        8,
        2,
        true,
      ),
      _entry(
        'att-05',
        'br-02',
        'user-emp-06',
        'Omar Rivera',
        today,
        AttendanceStatus.absent,
        AttendanceReviewStatus.needsReview,
        null,
        null,
        false,
        note: 'No attendance event recorded.',
      ),
      _entry(
        'att-06',
        'br-04',
        'user-emp-04',
        'Daniel Kim',
        today,
        AttendanceStatus.late,
        AttendanceReviewStatus.dismissed,
        9,
        3,
        false,
      ),
      _entry(
        'att-07',
        'br-01',
        'user-emp-01',
        'Sarah Connor',
        today.subtract(const Duration(days: 1)),
        AttendanceStatus.present,
        AttendanceReviewStatus.none,
        8,
        2,
        true,
      ),
      _entry(
        'att-08',
        'br-01',
        'user-emp-02',
        'Alex Chen',
        today.subtract(const Duration(days: 1)),
        AttendanceStatus.present,
        AttendanceReviewStatus.none,
        8,
        2,
        false,
      ),
      _entry(
        'att-09',
        'br-02',
        'user-emp-03',
        'Priya Shah',
        today.subtract(const Duration(days: 1)),
        AttendanceStatus.late,
        AttendanceReviewStatus.verified,
        9,
        2,
        true,
      ),
    ];
    for (final entry in entries) {
      _entries[entry.id] = entry;
    }
  }

  final Map<String, AttendanceEntry> _entries = {};

  @override
  Future<List<AttendanceEntry>> getAttendance({
    required UserAccessContext access,
    required DateTime date,
    String? activeBranchId,
    String? employeeId,
  }) async {
    final organizationId = access.organization?.id;
    if (organizationId == null) return const [];
    final branchId = _validateBranchScope(access, activeBranchId);
    if (access.user.role == UserRole.employee &&
        employeeId != null &&
        employeeId != access.user.id) {
      throw StateError('Employees can only view their own attendance.');
    }
    final scopedEmployee = access.user.role == UserRole.employee
        ? access.user.id
        : employeeId;
    return _entries.values
        .where((entry) {
          if (entry.organizationId != organizationId) {
            return false;
          }
          if (!_sameDate(entry.workDate, date)) {
            return false;
          }
          if (branchId != null && entry.branchId != branchId) {
            return false;
          }
          if (scopedEmployee != null && entry.employeeId != scopedEmployee) {
            return false;
          }
          return true;
        })
        .toList(growable: false)
      ..sort(
        (a, b) =>
            (a.checkInAt ?? a.workDate).compareTo(b.checkInAt ?? b.workDate),
      );
  }

  @override
  Future<AttendanceEntry> reviewException({
    required UserAccessContext access,
    required String entryId,
    required String activeBranchId,
    required AttendanceReviewDecision decision,
  }) async {
    if (access.user.role != UserRole.orgAdmin &&
        access.user.role != UserRole.branchManager) {
      throw StateError('You do not have permission to review attendance.');
    }
    final branchId = _validateBranchScope(access, activeBranchId);
    final entry = _entries[entryId];
    if (entry == null ||
        entry.organizationId != access.organization?.id ||
        (branchId != null && entry.branchId != branchId)) {
      throw StateError('This attendance record is outside your access scope.');
    }
    if (entry.reviewStatus != AttendanceReviewStatus.needsReview) {
      throw StateError('This attendance item has already been reviewed.');
    }
    final updated = entry.copyWith(
      reviewStatus: decision == AttendanceReviewDecision.verify
          ? AttendanceReviewStatus.verified
          : AttendanceReviewStatus.dismissed,
    );
    _entries[entryId] = updated;
    return updated;
  }

  String? _validateBranchScope(UserAccessContext access, String? requested) {
    if (access.user.role == UserRole.branchManager) {
      if (requested == null ||
          !access.assignedBranches.any(
            (branch) => branch.id == requested && branch.isActive,
          )) {
        throw StateError('Choose an active branch assigned to your account.');
      }
      return requested;
    }
    if (requested != null &&
        !access.assignedBranches.any((b) => b.id == requested)) {
      throw StateError('This branch is outside your organization.');
    }
    return requested;
  }

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  AttendanceEntry _entry(
    String id,
    String branchId,
    String employeeId,
    String employeeName,
    DateTime date,
    AttendanceStatus status,
    AttendanceReviewStatus review,
    int? checkInHour,
    int? checkOutHour,
    bool kiosk, {
    String? note,
  }) {
    DateTime? at(int? hour) => hour == null
        ? null
        : DateTime(date.year, date.month, date.day, hour, hour == 9 ? 18 : 0);
    return AttendanceEntry(
      id: id,
      organizationId: 'org-acme',
      branchId: branchId,
      employeeId: employeeId,
      employeeName: employeeName,
      workDate: DateTime(date.year, date.month, date.day),
      status: status,
      reviewStatus: review,
      checkInAt: at(checkInHour),
      checkOutAt: at(checkOutHour),
      note: note,
      kioskEntry: kiosk,
    );
  }
}
