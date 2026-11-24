import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/data/attendance_entry_mapper.dart';
import 'package:workaxis/features/attendance/data/checkout_correction_mapper.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/checkout_correction.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_exceptions_repository.dart';
import 'package:workaxis/features/attendance/domain/services/attendance_exceptions_scope.dart';
import 'package:workaxis/features/attendance/domain/services/checkout_stage.dart';

/// Reads exceptions from Firestore (scoped so the queries satisfy
/// `firestore.rules`) and sends every decision through the `dataOp`
/// operations `RequestCheckoutCorrection`, `ReviewCheckoutCorrection` and
/// `ReviewOvertime`, which update the attendance entry server-side.
class FirestoreAttendanceExceptionsRepository
    implements AttendanceExceptionsRepository {
  FirestoreAttendanceExceptionsRepository({
    required this.gateway,
    FirebaseFirestore? firestore,
  }) : _customFirestore = firestore;

  /// Upper bound on documents returned by one query.
  static const int maxPerQuery = 200;

  final DataGateway gateway;
  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<List<AttendanceEntry>> getCorrectableEntries({
    required UserAccessContext access,
  }) async {
    final uid = AttendanceExceptionsScope.requester(access);
    try {
      final snapshot = await _firestore
          .collection('attendance_entries')
          .where('employeeId', isEqualTo: uid)
          .where('checkoutStatus', whereIn: const ['missing', 'late'])
          .limit(maxPerQuery)
          .get();
      final entries =
          snapshot.docs
              .map((d) => AttendanceEntryMapper.fromData(d.id, d.data()))
              .where((e) => e.canRequestCheckoutCorrection)
              .toList()
            ..sort((a, b) => b.workDate.compareTo(a.workDate));
      return List.unmodifiable(entries);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<void> requestCheckoutCorrection({
    required UserAccessContext access,
    required String entryId,
    required DateTime checkOutAt,
    required String reason,
  }) async {
    AttendanceExceptionsScope.requester(access);
    await gateway.call('RequestCheckoutCorrection', {
      'entryId': entryId,
      'checkOutAt': checkOutAt.toUtc().toIso8601String(),
      'reason': reason.trim(),
    });
  }

  @override
  Future<List<CheckoutCorrection>> getPendingCorrections({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    final scope = AttendanceExceptionsScope.reviewer(access, activeBranchId);
    try {
      var query = _firestore
          .collection('attendance_corrections')
          .where('organizationId', isEqualTo: scope.organizationId)
          .where('status', isEqualTo: 'pending');
      if (scope.branchId != null) {
        query = query.where('branchId', isEqualTo: scope.branchId);
      }
      final snapshot = await query.limit(maxPerQuery).get();
      final corrections =
          snapshot.docs
              .map((d) => CheckoutCorrectionMapper.fromData(d.id, d.data()))
              .where((c) => c.employeeId != access.user.id)
              .toList()
            ..sort(
              (a, b) => (a.createdAt ?? a.requestedCheckOutAt).compareTo(
                b.createdAt ?? b.requestedCheckOutAt,
              ),
            );
      return List.unmodifiable(corrections);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<void> reviewCorrection({
    required UserAccessContext access,
    required String correctionId,
    required CorrectionDecision decision,
    String? note,
    String? activeBranchId,
  }) async {
    final scope = AttendanceExceptionsScope.reviewer(access, activeBranchId);
    final trimmed = note?.trim();
    await gateway.call('ReviewCheckoutCorrection', {
      'id': correctionId,
      'decision': decision.name,
      if (trimmed != null && trimmed.isNotEmpty) 'note': trimmed,
      'activeBranchId': ?scope.branchId,
    });
  }

  @override
  Future<List<AttendanceEntry>> getPendingOvertime({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    final scope = AttendanceExceptionsScope.reviewer(access, activeBranchId);
    try {
      var query = _firestore
          .collection('attendance_entries')
          .where('organizationId', isEqualTo: scope.organizationId)
          .where('overtimeStatus', isEqualTo: 'pending');
      if (scope.branchId != null) {
        query = query.where('branchId', isEqualTo: scope.branchId);
      }
      final snapshot = await query.limit(maxPerQuery).get();
      final entries =
          snapshot.docs
              .map((d) => AttendanceEntryMapper.fromData(d.id, d.data()))
              .where((e) => e.hasPendingOvertime)
              .where((e) => e.employeeId != access.user.id)
              .toList()
            ..sort((a, b) => a.workDate.compareTo(b.workDate));
      return List.unmodifiable(entries);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<void> reviewOvertime({
    required UserAccessContext access,
    required String entryId,
    required OvertimeDecision decision,
    double? approvedHours,
    String? activeBranchId,
  }) async {
    final scope = AttendanceExceptionsScope.reviewer(access, activeBranchId);
    await gateway.call('ReviewOvertime', {
      'entryId': entryId,
      'decision': decision.name,
      if (decision == OvertimeDecision.approve && approvedHours != null)
        'approvedHours': approvedHours,
      'activeBranchId': ?scope.branchId,
    });
  }
}
