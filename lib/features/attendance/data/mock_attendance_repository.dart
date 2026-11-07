import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

class MockAttendanceRepository implements AttendanceRepository {
  MockAttendanceRepository({Now? now}) : _now = now ?? systemNow {
    final today = BusinessTime.today(_now);
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

  final Now _now;
  final Map<String, AttendanceEntry> _entries = {};

  @override
  Future<List<AttendanceEntry>> getAttendance({
    required UserAccessContext access,
    required DateTime date,
    String? activeBranchId,
    String? employeeId,
  }) async {
    final organizationId = access.organization?.id;
    if (access.user.role.isPlatformLevel || organizationId == null) {
      throw const AccessDeniedException(
        'No organization attendance scope for this session.',
      );
    }
    final branchId = _validateBranchScope(access, activeBranchId);
    if (access.user.role == UserRole.employee &&
        employeeId != null &&
        employeeId != access.user.id) {
      throw const AccessDeniedException(
        'Employees can only view their own attendance.',
      );
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
      throw const AccessDeniedException(
        'You do not have permission to review attendance.',
      );
    }
    final branchId = _validateBranchScope(access, activeBranchId);
    final entry = _entries[entryId];
    if (entry == null ||
        entry.organizationId != access.organization?.id ||
        (branchId != null && entry.branchId != branchId)) {
      throw const AccessDeniedException(
        'This attendance record is outside your access scope.',
      );
    }
    if (entry.reviewStatus != AttendanceReviewStatus.needsReview) {
      throw const DatabaseException(
        'Attendance already reviewed.',
        userMessage: 'This attendance item has already been reviewed.',
      );
    }
    final updated = entry.copyWith(
      reviewStatus: decision == AttendanceReviewDecision.verify
          ? AttendanceReviewStatus.verified
          : AttendanceReviewStatus.dismissed,
    );
    _entries[entryId] = updated;
    return updated;
  }

  @override
  Future<List<AttendanceEntry>> markGroupAttendance({
    required UserAccessContext access,
    required GroupAttendanceRequest request,
  }) async {
    if (access.user.role != UserRole.orgAdmin &&
        access.user.role != UserRole.branchManager) {
      throw const AccessDeniedException(
        'You do not have permission to record group attendance.',
      );
    }
    final branchId = _validateBranchScope(access, request.branchId);
    if (branchId == null) {
      throw const AccessDeniedException(
        'A valid branch must be specified for group attendance.',
      );
    }
    if (request.attendees.isEmpty) {
      throw const DatabaseException(
        'At least one attendee is required.',
        userMessage: 'Select at least one employee.',
      );
    }

    final orgId = access.organization?.id;
    if (orgId == null) {
      throw const AccessDeniedException('An organization context is required.');
    }
    final results = <AttendanceEntry>[];

    // One entry per employee per day: never record the same person twice.
    for (final attendee in request.attendees) {
      final alreadyRecorded = _entries.values.any(
        (entry) =>
            entry.organizationId == orgId &&
            entry.employeeId == attendee.employeeId &&
            _sameDate(entry.workDate, request.workDate),
      );
      if (alreadyRecorded) {
        throw const DatabaseException(
          'Group attendance includes employees already recorded.',
          userMessage:
              'Some selected employees already have attendance for this day.',
        );
      }
    }

    for (final attendee in request.attendees) {
      final entryId =
          'att-grp-${attendee.employeeId}-${BusinessTime.keyOfDate(request.workDate)}';

      final finalNote = request.note != null && request.note!.isNotEmpty
          ? '${request.shiftName}: ${request.note}'
          : 'Group check-in (${request.shiftName})';

      final newEntry = AttendanceEntry(
        id: entryId,
        organizationId: orgId,
        branchId: branchId,
        employeeId: attendee.employeeId,
        employeeName: attendee.employeeName,
        workDate: DateTime(
          request.workDate.year,
          request.workDate.month,
          request.workDate.day,
        ),
        status: request.status,
        reviewStatus: AttendanceReviewStatus.none,
        checkInAt: _now(),
        note: finalNote,
        kioskEntry: false,
      );

      _entries[entryId] = newEntry;
      results.add(newEntry);
    }

    return results;
  }

  String? _validateBranchScope(UserAccessContext access, String? requested) {
    if (access.user.role == UserRole.branchManager) {
      if (requested == null ||
          !access.assignedBranches.any(
            (branch) => branch.id == requested && branch.isActive,
          )) {
        throw const AccessDeniedException(
          'Choose an active branch assigned to your account.',
        );
      }
      return requested;
    }
    if (requested != null &&
        !access.assignedBranches.any((b) => b.id == requested)) {
      throw const AccessDeniedException(
        'This branch is outside your organization.',
      );
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
