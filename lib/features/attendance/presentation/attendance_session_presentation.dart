import 'package:flutter/material.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_day_summary.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/presentation/attendance_time_format.dart';

/// How a check-out state is shown: a text label (never colour alone), the
/// chip styling, an icon and an optional explanation.
class CheckoutStateDisplay {
  const CheckoutStateDisplay({
    required this.status,
    required this.label,
    required this.type,
    required this.icon,
    this.detail,
  });

  final CheckoutStatus status;
  final String label;
  final StatusType type;
  final IconData icon;
  final String? detail;
}

/// Shift, check-out and overtime display for one attendance session.
extension AttendanceSessionPresentation on AttendanceEntry {
  /// The recorded check-out state; a corrected check-out counts as corrected
  /// even when the server left the status unset.
  CheckoutStatus get effectiveCheckoutStatus =>
      checkoutStatus == CheckoutStatus.none && checkOutCorrected
      ? CheckoutStatus.corrected
      : checkoutStatus;

  /// Whether the system closed this session without a check-out.
  bool get isMissingCheckout =>
      checkOutAt == null &&
      (effectiveCheckoutStatus == CheckoutStatus.missing ||
          sessionClosedAt != null);

  CheckoutStateDisplay? get checkoutStateDisplay {
    if (isMissingCheckout) {
      return CheckoutStateDisplay(
        status: CheckoutStatus.missing,
        label: 'Missing check-out',
        type: StatusType.urgent,
        icon: Icons.report_gmailerrorred_outlined,
        detail: _closedByLabel,
      );
    }
    return switch (effectiveCheckoutStatus) {
      CheckoutStatus.overdue => const CheckoutStateDisplay(
        status: CheckoutStatus.overdue,
        label: 'Overdue',
        type: StatusType.pending,
        icon: Icons.timer_off_outlined,
        detail:
            'No check-out after the shift end and overtime allowance; '
            'the employee may still be working.',
      ),
      CheckoutStatus.late => const CheckoutStateDisplay(
        status: CheckoutStatus.late,
        label: 'Late check-out',
        type: StatusType.pending,
        icon: Icons.schedule_outlined,
        detail: 'Checked out after the overtime allowance.',
      ),
      CheckoutStatus.corrected => const CheckoutStateDisplay(
        status: CheckoutStatus.corrected,
        label: 'Corrected',
        type: StatusType.active,
        icon: Icons.edit_calendar_outlined,
        detail: 'Check-out set by an approved correction.',
      ),
      // A missing status without the closure is still shown as missing.
      CheckoutStatus.missing || CheckoutStatus.none => null,
    };
  }

  String get _closedByLabel {
    final closedAt = sessionClosedAt;
    // A pending server timestamp maps to the epoch: closed, time unknown.
    final known = closedAt != null && closedAt.millisecondsSinceEpoch > 0;
    final when = known
        ? 'Closed by system at ${AttendanceTimeFormat.dateTime(closedAt)}'
        : 'Closed by system';
    return '$when. No check-out was recorded.';
  }

  /// e.g. `Shift 9:00 PM – 5:00 AM (next day)`; null when unscheduled.
  String? get shiftWindowLabel {
    final start = scheduledStartAt;
    final end = scheduledEndAt;
    if (start == null || end == null) return null;
    final endsNextDay = AttendanceTimeFormat.isAfterShiftDate(
      end,
      BusinessTime.dateOf(start),
    );
    return 'Shift ${AttendanceTimeFormat.time(start)} – '
        '${AttendanceTimeFormat.time(end)}${endsNextDay ? ' (next day)' : ''}';
  }

  /// The check-out cell: the time (noting the next day for night shifts) or
  /// why there is none.
  String get checkOutLabel {
    final out = checkOutAt;
    if (out != null) return AttendanceTimeFormat.timeOnShift(out, workDate);
    if (isMissingCheckout) return 'Missing';
    if (checkInAt == null) return '—';
    if (effectiveCheckoutStatus == CheckoutStatus.overdue) return 'Overdue';
    return 'In progress';
  }

  /// The employee's correction request state, when it needs mentioning.
  String? get correctionLabel => switch (correctionStatus) {
    CorrectionStatus.pending => 'Correction pending review',
    CorrectionStatus.rejected => 'Correction rejected',
    CorrectionStatus.approved || CorrectionStatus.none => null,
  };

  /// e.g. `2h potential OT · Pending`, `1.5h OT approved`; null when none.
  String? get overtimeLabel {
    final potential = AttendanceTimeFormat.hours(potentialOvertimeHours);
    return switch (overtimeStatus) {
      OvertimeStatus.pending => '$potential potential OT · Pending',
      OvertimeStatus.approved => _approvedOvertimeLabel,
      OvertimeStatus.rejected => '$potential potential OT · Rejected',
      OvertimeStatus.none =>
        potentialOvertimeHours > 0 ? '$potential potential OT' : null,
    };
  }

  String get _approvedOvertimeLabel {
    final approved = approvedOvertimeHours ?? potentialOvertimeHours;
    final label = '${AttendanceTimeFormat.hours(approved)} OT approved';
    return approved < potentialOvertimeHours
        ? '$label of ${AttendanceTimeFormat.hours(potentialOvertimeHours)}'
        : label;
  }

  StatusType get overtimeChipType => switch (overtimeStatus) {
    OvertimeStatus.pending => StatusType.pending,
    OvertimeStatus.approved => StatusType.active,
    OvertimeStatus.rejected || OvertimeStatus.none => StatusType.neutral,
  };

  /// Time between check-in and check-out less completed breaks.
  Duration? get workedDuration {
    final start = checkInAt;
    final end = checkOutAt;
    if (start == null || end == null || !end.isAfter(start)) return null;
    var worked = end.difference(start);
    for (final item in breaks) {
      final breakEnd = item.endAt;
      if (breakEnd != null && breakEnd.isAfter(item.startAt)) {
        worked -= breakEnd.difference(item.startAt);
      }
    }
    return worked.isNegative ? Duration.zero : worked;
  }
}

/// The same display rolled up for an employee's day.
extension AttendanceDaySummarySessionPresentation on AttendanceDaySummary {
  /// The most pressing check-out state among the sessions.
  CheckoutStateDisplay? get checkoutStateDisplay {
    CheckoutStateDisplay? worst;
    for (final session in sessions) {
      final display = session.checkoutStateDisplay;
      if (display == null) continue;
      if (worst == null ||
          _severity(display.status) > _severity(worst.status)) {
        worst = display;
      }
    }
    return worst;
  }

  /// The day's last check-out, or why the day has none yet.
  String get lastCheckOutLabel {
    if (sessions.any((s) => s.isMissingCheckout)) return 'Missing';
    final open = sessions.where((s) => s.isOpen);
    if (open.any((s) => s.effectiveCheckoutStatus == CheckoutStatus.overdue)) {
      return 'Overdue';
    }
    if (open.isNotEmpty) return 'In progress';
    final last = sessions
        .where((s) => s.checkOutAt != null)
        .fold<AttendanceEntry?>(
          null,
          (latest, s) =>
              latest == null || s.checkOutAt!.isAfter(latest.checkOutAt!)
              ? s
              : latest,
        );
    return last?.checkOutLabel ?? '—';
  }

  String? get shiftWindowLabel =>
      sessions.map((s) => s.shiftWindowLabel).nonNulls.firstOrNull;

  /// Pending overtime first (it needs action), then approved, then rejected.
  String? get overtimeLabel {
    double pending = 0;
    double approved = 0;
    var rejected = false;
    for (final s in sessions) {
      switch (s.overtimeStatus) {
        case OvertimeStatus.pending:
          pending += s.potentialOvertimeHours;
        case OvertimeStatus.approved:
          approved += s.approvedOvertimeHours ?? s.potentialOvertimeHours;
        case OvertimeStatus.rejected:
          rejected = true;
        case OvertimeStatus.none:
          break;
      }
    }
    if (pending > 0) {
      return '${AttendanceTimeFormat.hours(pending)} potential OT · Pending';
    }
    if (approved > 0) {
      return '${AttendanceTimeFormat.hours(approved)} OT approved';
    }
    return rejected ? 'Overtime rejected' : null;
  }

  StatusType get overtimeChipType {
    if (sessions.any((s) => s.overtimeStatus == OvertimeStatus.pending)) {
      return StatusType.pending;
    }
    if (sessions.any((s) => s.overtimeStatus == OvertimeStatus.approved)) {
      return StatusType.active;
    }
    return StatusType.neutral;
  }

  static int _severity(CheckoutStatus status) => switch (status) {
    CheckoutStatus.missing => 4,
    CheckoutStatus.overdue => 3,
    CheckoutStatus.late => 2,
    CheckoutStatus.corrected => 1,
    CheckoutStatus.none => 0,
  };
}
