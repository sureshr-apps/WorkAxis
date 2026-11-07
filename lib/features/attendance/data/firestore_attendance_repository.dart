import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/data/attendance_entry_mapper.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Production [AttendanceRepository] on Cloud Firestore.
///
/// Reads are scoped before they are sent (organization, active branch or own
/// uid) so the queries satisfy `firestore.rules`. Manager-created entries and
/// reviews carry `FieldValue.serverTimestamp()` because the rules require
/// `checkInAt == request.time` / `reviewedAt == request.time`; business-day
/// keys are computed in the business timezone from the injected clock, never
/// from the device-local date. Employee punches do not go through here: they
/// use the `recordAttendancePunch` callable.
class FirestoreAttendanceRepository implements AttendanceRepository {
  FirestoreAttendanceRepository({FirebaseFirestore? firestore, Now? now})
    : _customFirestore = firestore,
      _now = now ?? systemNow;

  /// Upper bound on documents returned by one query.
  static const int maxEntriesPerQuery = 500;

  /// Firestore batches hold at most 500 writes (one per attendee plus the
  /// audit record).
  static const int maxGroupAttendees = 400;

  /// How far back a manager may record a group check-in (see rules).
  static const int maxBackdateDays = 6;

  /// Written as `source` on manager group entries; the rules require it.
  static const String groupEntrySource = 'manager-group';

  final FirebaseFirestore? _customFirestore;
  final Now _now;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('attendance_entries');

  @override
  Future<List<AttendanceEntry>> getAttendance({
    required UserAccessContext access,
    required DateTime date,
    String? activeBranchId,
    String? employeeId,
  }) async {
    try {
      final query = _scopedQuery(
        access: access,
        dayKey: BusinessTime.keyOfDate(date),
        requestedBranchId: activeBranchId,
        requestedEmployeeId: employeeId,
      );
      final snapshot = await query.limit(maxEntriesPerQuery).get();
      final entries = [
        for (final doc in snapshot.docs)
          AttendanceEntryMapper.fromData(doc.id, doc.data()),
      ];
      entries.sort(
        (a, b) =>
            (a.checkInAt ?? a.workDate).compareTo(b.checkInAt ?? b.workDate),
      );
      return entries;
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<AttendanceEntry> reviewException({
    required UserAccessContext access,
    required String entryId,
    required String activeBranchId,
    required AttendanceReviewDecision decision,
  }) async {
    try {
      final orgId = _requireManagerOrg(access, 'review attendance exceptions');
      final isBranchManager = access.user.role == UserRole.branchManager;
      if (isBranchManager) {
        _requireAssignedActiveBranch(access, activeBranchId);
      }

      final docRef = _collection.doc(entryId);
      final snapshot = await docRef.get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw const NotFoundException('Attendance record not found.');
      }
      final inScope =
          data['organizationId'] == orgId &&
          (!isBranchManager || data['branchId'] == activeBranchId);
      if (!inScope) {
        throw const AccessDeniedException(
          'Attendance record is outside the reviewer scope.',
        );
      }

      final newStatus = decision == AttendanceReviewDecision.verify
          ? AttendanceReviewStatus.verified
          : AttendanceReviewStatus.dismissed;

      await docRef.update({
        'reviewStatus': newStatus.name,
        'reviewedBy': access.user.name,
        'reviewedById': access.user.id,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      return AttendanceEntryMapper.fromData(entryId, {
        ...data,
        'reviewStatus': newStatus.name,
      });
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<List<AttendanceEntry>> markGroupAttendance({
    required UserAccessContext access,
    required GroupAttendanceRequest request,
  }) async {
    try {
      final orgId = _requireManagerOrg(access, 'record group attendance');
      _requireAssignedActiveBranch(access, request.branchId);
      _validateGroupRequest(request);

      final workDate = DateTime(
        request.workDate.year,
        request.workDate.month,
        request.workDate.day,
      );
      _requireWithinBackdateWindow(workDate);
      final dayKey = BusinessTime.keyOfDate(workDate);

      await _rejectAlreadyRecorded(orgId, request, dayKey);

      final batch = _firestore.batch();
      final batchLogRef = _firestore
          .collection('group_attendance_batches')
          .doc();
      batch.set(batchLogRef, {
        'id': batchLogRef.id,
        'organizationId': orgId,
        'branchId': request.branchId,
        'workDate': dayKey,
        'shiftName': request.shiftName,
        'attendeeCount': request.attendees.length,
        'createdBy': access.user.name,
        'createdById': access.user.id,
        'createdAt': FieldValue.serverTimestamp(),
        'note': request.note,
      });

      final recordedAt = _now();
      final results = <AttendanceEntry>[];
      for (final attendee in request.attendees) {
        // One entry per employee per day, same id scheme as employee punches.
        final entryId = '${attendee.employeeId}_$dayKey';
        batch.set(_collection.doc(entryId), {
          'id': entryId,
          'organizationId': orgId,
          'branchId': request.branchId,
          'employeeId': attendee.employeeId,
          'employeeName': attendee.employeeName,
          'workDate': Timestamp.fromDate(BusinessTime.startOfDay(workDate)),
          'workDateString': dayKey,
          'status': request.status.name,
          'reviewStatus': AttendanceReviewStatus.none.name,
          'checkInAt': FieldValue.serverTimestamp(),
          'note': request.note,
          'kioskEntry': false,
          'source': groupEntrySource,
          'createdAt': FieldValue.serverTimestamp(),
        });
        results.add(
          AttendanceEntry(
            id: entryId,
            organizationId: orgId,
            branchId: request.branchId,
            employeeId: attendee.employeeId,
            employeeName: attendee.employeeName,
            workDate: workDate,
            status: request.status,
            reviewStatus: AttendanceReviewStatus.none,
            // Provisional until the next load returns the server timestamp.
            checkInAt: recordedAt,
            note: request.note,
          ),
        );
      }

      await batch.commit();
      return results;
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  Query<Map<String, dynamic>> _scopedQuery({
    required UserAccessContext access,
    required String dayKey,
    required String? requestedBranchId,
    required String? requestedEmployeeId,
  }) {
    final role = access.user.role;
    if (role.isPlatformLevel) {
      throw const AccessDeniedException(
        'Platform users do not have an organization attendance scope.',
      );
    }
    final orgId = access.organization?.id;
    if (orgId == null || orgId.isEmpty) {
      throw const AccessDeniedException(
        'No organization context associated with current session.',
      );
    }

    var query = _collection
        .where('organizationId', isEqualTo: orgId)
        .where('workDateString', isEqualTo: dayKey);

    switch (role) {
      case UserRole.orgAdmin:
        if (requestedBranchId != null && requestedBranchId.isNotEmpty) {
          query = query.where('branchId', isEqualTo: requestedBranchId);
        }
      case UserRole.branchManager:
        final branchId = requestedBranchId ?? access.activeBranch?.branchId;
        if (branchId == null) {
          throw const AccessDeniedException(
            'Branch Manager has no active branch context.',
          );
        }
        _requireAssignedActiveBranch(access, branchId);
        query = query.where('branchId', isEqualTo: branchId);
      case UserRole.employee:
        if (requestedEmployeeId != null &&
            requestedEmployeeId.isNotEmpty &&
            requestedEmployeeId != access.user.id) {
          throw const AccessDeniedException(
            'Employees can only view their own attendance.',
          );
        }
        query = query.where('employeeId', isEqualTo: access.user.id);
      default:
        throw const AccessDeniedException(
          'Unauthorized role for attendance queries.',
        );
    }

    if (role != UserRole.employee &&
        requestedEmployeeId != null &&
        requestedEmployeeId.isNotEmpty) {
      query = query.where('employeeId', isEqualTo: requestedEmployeeId);
    }
    return query;
  }

  /// Org Admins and Branch Managers only; returns the organization id.
  String _requireManagerOrg(UserAccessContext access, String action) {
    final role = access.user.role;
    if (role != UserRole.orgAdmin && role != UserRole.branchManager) {
      throw AccessDeniedException('Role ${role.name} may not $action.');
    }
    final orgId = access.organization?.id;
    if (orgId == null || orgId.isEmpty) {
      throw const AccessDeniedException(
        'No organization context associated with current session.',
      );
    }
    return orgId;
  }

  /// [branchId] must be an active branch in the user's assigned set.
  void _requireAssignedActiveBranch(UserAccessContext access, String branchId) {
    final BranchSummary? branch = access.assignedBranches
        .where((b) => b.id == branchId)
        .firstOrNull;
    if (branch == null || !branch.isActive) {
      throw const AccessDeniedException(
        'Branch is not an active branch assigned to the current user.',
      );
    }
  }

  void _validateGroupRequest(GroupAttendanceRequest request) {
    if (request.attendees.isEmpty) {
      throw const DatabaseException(
        'Group attendance without attendees.',
        userMessage: 'Select at least one employee.',
      );
    }
    if (request.attendees.length > maxGroupAttendees) {
      throw const DatabaseException(
        'Too many group attendees.',
        userMessage: 'Record at most $maxGroupAttendees employees at a time.',
      );
    }
    if (request.status != AttendanceStatus.present &&
        request.status != AttendanceStatus.late) {
      throw const DatabaseException(
        'Group attendance status must be present or late.',
        userMessage: 'Group check-in can only mark employees present or late.',
      );
    }
  }

  void _requireWithinBackdateWindow(DateTime workDate) {
    final today = BusinessTime.today(_now);
    final earliest = today.subtract(const Duration(days: maxBackdateDays));
    if (workDate.isAfter(today) || workDate.isBefore(earliest)) {
      throw const DatabaseException(
        'Group attendance date outside the allowed window.',
        userMessage:
            'Group check-in can only be recorded for today or the last '
            '$maxBackdateDays days.',
      );
    }
  }

  /// One entry per employee per day: refuse to overwrite existing ones.
  Future<void> _rejectAlreadyRecorded(
    String orgId,
    GroupAttendanceRequest request,
    String dayKey,
  ) async {
    final existing = await _collection
        .where('organizationId', isEqualTo: orgId)
        .where('branchId', isEqualTo: request.branchId)
        .where('workDateString', isEqualTo: dayKey)
        .limit(maxEntriesPerQuery)
        .get();
    final recorded = {
      for (final doc in existing.docs) doc.data()['employeeId'] as String?,
    };
    final duplicates = request.attendees.where(
      (a) => recorded.contains(a.employeeId),
    );
    if (duplicates.isNotEmpty) {
      throw const DatabaseException(
        'Group attendance includes employees already recorded.',
        userMessage:
            'Some selected employees already have attendance for this day.',
      );
    }
  }
}
