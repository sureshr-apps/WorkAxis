import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/checkout_correction.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_exceptions_repository.dart';
import 'package:workaxis/features/attendance/domain/services/attendance_exceptions_scope.dart';
import 'package:workaxis/features/attendance/domain/services/checkout_stage.dart';

/// In-memory [AttendanceExceptionsRepository] for demo mode and tests:
/// a night shift with a missing check-out, a pending correction and a
/// session with overtime waiting for approval.
class MockAttendanceExceptionsRepository
    implements AttendanceExceptionsRepository {
  MockAttendanceExceptionsRepository({
    Now? now,
    List<AttendanceEntry>? entries,
    List<CheckoutCorrection>? corrections,
  }) : _now = now ?? systemNow {
    final today = _now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    _entries = entries ?? _demoEntries(yesterday);
    _corrections = corrections ?? _demoCorrections(yesterday);
  }

  final Now _now;
  late List<AttendanceEntry> _entries;
  late List<CheckoutCorrection> _corrections;
  int _sequence = 0;

  @override
  Future<List<AttendanceEntry>> getCorrectableEntries({
    required UserAccessContext access,
  }) async {
    final uid = AttendanceExceptionsScope.requester(access);
    return List.unmodifiable(
      _entries
          .where((e) => e.employeeId == uid && e.canRequestCheckoutCorrection)
          .toList()
        ..sort((a, b) => b.workDate.compareTo(a.workDate)),
    );
  }

  @override
  Future<void> requestCheckoutCorrection({
    required UserAccessContext access,
    required String entryId,
    required DateTime checkOutAt,
    required String reason,
  }) async {
    final uid = AttendanceExceptionsScope.requester(access);
    final index = _entries.indexWhere(
      (e) => e.id == entryId && e.employeeId == uid,
    );
    if (index < 0) {
      throw const NotFoundException('Attendance record not found.');
    }
    final entry = _entries[index];
    final checkInAt = entry.checkInAt;
    if (!entry.canRequestCheckoutCorrection || checkInAt == null) {
      throw const DatabaseException(
        'Not correctable.',
        userMessage: 'Only a missing or late check-out can be corrected.',
      );
    }
    if (!checkOutAt.isAfter(checkInAt) || checkOutAt.isAfter(_now())) {
      throw const DatabaseException(
        'Invalid correction time.',
        userMessage: 'The check-out time must be after the check-in and not in the future.',
      );
    }
    final id = 'corr-mock-${++_sequence}';
    _corrections.add(
      CheckoutCorrection(
        id: id,
        entryId: entry.id,
        organizationId: entry.organizationId,
        branchId: entry.branchId,
        employeeId: entry.employeeId,
        employeeName: entry.employeeName,
        workDate: entry.workDate,
        checkInAt: checkInAt,
        recordedCheckOutAt: entry.checkOutAt,
        requestedCheckOutAt: checkOutAt,
        reason: reason.trim(),
        status: CorrectionStatus.pending,
        createdAt: _now(),
      ),
    );
    _entries[index] = entry.copyWith(
      correctionStatus: CorrectionStatus.pending,
      correctionId: id,
    );
  }

  @override
  Future<List<CheckoutCorrection>> getPendingCorrections({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    final scope = AttendanceExceptionsScope.reviewer(access, activeBranchId);
    return List.unmodifiable(
      _corrections.where(
        (c) =>
            c.status == CorrectionStatus.pending &&
            c.organizationId == scope.organizationId &&
            (scope.branchId == null || c.branchId == scope.branchId) &&
            c.employeeId != access.user.id,
      ),
    );
  }

  @override
  Future<void> reviewCorrection({
    required UserAccessContext access,
    required String correctionId,
    required CorrectionDecision decision,
    String? note,
    String? activeBranchId,
  }) async {
    final pending = await getPendingCorrections(
      access: access,
      activeBranchId: activeBranchId,
    );
    final correction = pending.where((c) => c.id == correctionId).firstOrNull;
    if (correction == null) {
      throw const NotFoundException('Correction request not found.');
    }
    final status = decision == CorrectionDecision.approve
        ? CorrectionStatus.approved
        : CorrectionStatus.rejected;
    _corrections = [
      for (final c in _corrections)
        if (c.id == correctionId)
          CheckoutCorrection(
            id: c.id,
            entryId: c.entryId,
            organizationId: c.organizationId,
            branchId: c.branchId,
            employeeId: c.employeeId,
            employeeName: c.employeeName,
            workDate: c.workDate,
            checkInAt: c.checkInAt,
            recordedCheckOutAt: c.recordedCheckOutAt,
            requestedCheckOutAt: c.requestedCheckOutAt,
            reason: c.reason,
            status: status,
            createdAt: c.createdAt,
            reviewNote: note,
          )
        else
          c,
    ];
    _entries = [
      for (final e in _entries)
        if (e.id == correction.entryId)
          e.copyWith(correctionStatus: status)
        else
          e,
    ];
  }

  @override
  Future<List<AttendanceEntry>> getPendingOvertime({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    final scope = AttendanceExceptionsScope.reviewer(access, activeBranchId);
    return List.unmodifiable(
      _entries.where(
        (e) =>
            e.hasPendingOvertime &&
            e.organizationId == scope.organizationId &&
            (scope.branchId == null || e.branchId == scope.branchId) &&
            e.employeeId != access.user.id,
      ),
    );
  }

  @override
  Future<void> reviewOvertime({
    required UserAccessContext access,
    required String entryId,
    required OvertimeDecision decision,
    double? approvedHours,
    String? activeBranchId,
  }) async {
    final pending = await getPendingOvertime(
      access: access,
      activeBranchId: activeBranchId,
    );
    final entry = pending.where((e) => e.id == entryId).firstOrNull;
    if (entry == null) {
      throw const NotFoundException('Attendance record not found.');
    }
    final hours = approvedHours ?? entry.potentialOvertimeHours;
    if (decision == OvertimeDecision.approve &&
        (hours <= 0 || hours > entry.potentialOvertimeHours)) {
      throw DatabaseException(
        'Invalid overtime hours.',
        userMessage:
            'Approved overtime must be more than 0 and at most '
            '${entry.potentialOvertimeHours} hours.',
      );
    }
    _entries = [
      for (final e in _entries)
        if (e.id == entryId)
          e.copyWith(
            overtimeStatus: decision == OvertimeDecision.approve
                ? OvertimeStatus.approved
                : OvertimeStatus.rejected,
            approvedOvertimeHours: decision == OvertimeDecision.approve
                ? hours
                : null,
          )
        else
          e,
    ];
  }

  static List<AttendanceEntry> _demoEntries(DateTime day) {
    DateTime at(int dayOffset, int hour) =>
        DateTime(day.year, day.month, day.day + dayOffset, hour);
    return [
      AttendanceEntry(
        id: 'att-night-missing',
        organizationId: 'org-acme',
        branchId: 'br-01',
        employeeId: 'user-emp-01',
        employeeName: 'Sarah Connor',
        workDate: day,
        status: AttendanceStatus.incomplete,
        reviewStatus: AttendanceReviewStatus.needsReview,
        checkInAt: at(0, 21),
        scheduledStartAt: at(0, 21),
        scheduledEndAt: at(1, 5),
        scheduledHours: 8,
        checkoutStatus: CheckoutStatus.missing,
        sessionClosedAt: at(1, 13),
      ),
      AttendanceEntry(
        id: 'att-day-overtime',
        organizationId: 'org-acme',
        branchId: 'br-01',
        employeeId: 'user-emp-02',
        employeeName: 'Alex Chen',
        workDate: day,
        status: AttendanceStatus.present,
        reviewStatus: AttendanceReviewStatus.none,
        checkInAt: at(0, 9),
        checkOutAt: at(0, 19),
        scheduledStartAt: at(0, 9),
        scheduledEndAt: at(0, 17),
        scheduledHours: 8,
        potentialOvertimeHours: 2,
        overtimeStatus: OvertimeStatus.pending,
      ),
    ];
  }

  static List<CheckoutCorrection> _demoCorrections(DateTime day) => [
    CheckoutCorrection(
      id: 'corr-demo-1',
      entryId: 'att-late-demo',
      organizationId: 'org-acme',
      branchId: 'br-01',
      employeeId: 'user-emp-05',
      employeeName: 'Mina Patel',
      workDate: day,
      checkInAt: DateTime(day.year, day.month, day.day, 9),
      recordedCheckOutAt: DateTime(day.year, day.month, day.day, 23, 40),
      requestedCheckOutAt: DateTime(day.year, day.month, day.day, 17, 10),
      reason: 'Forgot to check out when leaving; checked out from home later.',
      status: CorrectionStatus.pending,
      createdAt: DateTime(day.year, day.month, day.day + 1, 9),
    ),
  ];
}
