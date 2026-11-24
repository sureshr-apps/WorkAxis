import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/checkout_correction.dart';

/// Attendance exceptions that need a person to act: check-out corrections
/// (the employee requests, a manager decides) and overtime approval.
abstract interface class AttendanceExceptionsRepository {
  /// The caller's own sessions whose check-out is missing or late and that
  /// have no correction waiting for review, newest first.
  Future<List<AttendanceEntry>> getCorrectableEntries({
    required UserAccessContext access,
  });

  /// Asks a manager to set the check-out of [entryId] to [checkOutAt].
  Future<void> requestCheckoutCorrection({
    required UserAccessContext access,
    required String entryId,
    required DateTime checkOutAt,
    required String reason,
  });

  /// Correction requests waiting for review: the organization for Org
  /// Admins, the active branch for Branch Managers. Oldest first.
  Future<List<CheckoutCorrection>> getPendingCorrections({
    required UserAccessContext access,
    String? activeBranchId,
  });

  Future<void> reviewCorrection({
    required UserAccessContext access,
    required String correctionId,
    required CorrectionDecision decision,
    String? note,
    String? activeBranchId,
  });

  /// Sessions with overtime waiting for approval, scoped like
  /// [getPendingCorrections]. Oldest shift first.
  Future<List<AttendanceEntry>> getPendingOvertime({
    required UserAccessContext access,
    String? activeBranchId,
  });

  /// Approves [approvedHours] (default: all potential hours) or rejects.
  Future<void> reviewOvertime({
    required UserAccessContext access,
    required String entryId,
    required OvertimeDecision decision,
    double? approvedHours,
    String? activeBranchId,
  });
}
