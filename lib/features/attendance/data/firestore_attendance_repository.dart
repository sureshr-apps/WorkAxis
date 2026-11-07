import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Production implementation of [AttendanceRepository] utilizing Cloud Firestore (NoSQL)
/// for high-throughput, exponentially growing attendance event records and batch punches.
class FirestoreAttendanceRepository implements AttendanceRepository {
  FirestoreAttendanceRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('attendance_entries');

  @override
  Future<List<AttendanceEntry>> getAttendance({
    required UserAccessContext access,
    required DateTime date,
    String? activeBranchId,
    String? employeeId,
  }) async {
    final dateString = _dateFormat.format(date);
    Query<Map<String, dynamic>> query =
        _collection.where('workDateString', isEqualTo: dateString);

    // Enforce role-based access scoping
    if (access.user.isPlatformLevel) {
      // Platform operators may optionally filter by branch or view all
      if (activeBranchId != null && activeBranchId.isNotEmpty) {
        query = query.where('branchId', isEqualTo: activeBranchId);
      }
    } else {
      final orgId = access.organization?.id;
      if (orgId == null || orgId.isEmpty) {
        throw const AccessDeniedException(
          'No organization context associated with current session.',
        );
      }
      query = query.where('organizationId', isEqualTo: orgId);

      switch (access.user.role) {
        case UserRole.orgAdmin:
          if (activeBranchId != null && activeBranchId.isNotEmpty) {
            query = query.where('branchId', isEqualTo: activeBranchId);
          }
          break;

        case UserRole.branchManager:
          final effectiveBranch = activeBranchId ?? access.activeBranch?.branchId;
          if (effectiveBranch == null ||
              !access.assignedBranches.any((b) => b.id == effectiveBranch)) {
            throw const AccessDeniedException(
              'Branch Manager is not authorized for the requested branch context.',
            );
          }
          query = query.where('branchId', isEqualTo: effectiveBranch);
          break;

        case UserRole.employee:
          // Employees are strictly restricted to their own attendance entries
          query = query.where('employeeId', isEqualTo: access.user.id);
          break;

        default:
          throw const AccessDeniedException('Unauthorized role for attendance queries.');
      }
    }

    if (employeeId != null && employeeId.isNotEmpty) {
      query = query.where('employeeId', isEqualTo: employeeId);
    }

    try {
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => _mapDocToEntry(doc.id, doc.data())).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to retrieve attendance entries: ${e.toString()}');
    }
  }

  @override
  Future<AttendanceEntry> reviewException({
    required UserAccessContext access,
    required String entryId,
    required String activeBranchId,
    required AttendanceReviewDecision decision,
  }) async {
    // Only Org Admins or authorized Branch Managers may review exceptions
    if (access.user.role == UserRole.branchManager) {
      if (!access.assignedBranches.any((b) => b.id == activeBranchId)) {
        throw const AccessDeniedException(
          'You are not authorized to review exceptions for this branch.',
        );
      }
    } else if (access.user.role != UserRole.orgAdmin && !access.user.isPlatformLevel) {
      throw const AccessDeniedException(
        'You lack permissions to review attendance exceptions.',
      );
    }

    final docRef = _collection.doc(entryId);
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists || docSnapshot.data() == null) {
      throw const NotFoundException('Attendance record not found.');
    }

    final newReviewStatus = decision == AttendanceReviewDecision.verify
        ? AttendanceReviewStatus.verified
        : AttendanceReviewStatus.dismissed;

    final updatePayload = <String, dynamic>{
      'reviewStatus': newReviewStatus.name,
      'reviewedBy': access.user.name,
      'reviewedById': access.user.id,
      'reviewedAt': FieldValue.serverTimestamp(),
    };

    await docRef.update(updatePayload);

    final updatedData = Map<String, dynamic>.from(docSnapshot.data()!)
      ..addAll(updatePayload);

    return _mapDocToEntry(entryId, updatedData);
  }

  @override
  Future<List<AttendanceEntry>> markGroupAttendance({
    required UserAccessContext access,
    required GroupAttendanceRequest request,
  }) async {
    if (access.user.role == UserRole.branchManager) {
      if (!access.assignedBranches.any((b) => b.id == request.branchId)) {
        throw const AccessDeniedException(
          'You are not authorized to record group check-in for this branch.',
        );
      }
    } else if (access.user.role != UserRole.orgAdmin && !access.user.isPlatformLevel) {
      throw const AccessDeniedException(
        'You lack permissions to record group attendance.',
      );
    }

    final orgId = access.organization?.id ?? 'org-platform';
    final dateString = _dateFormat.format(request.workDate);
    final batch = _firestore.batch();
    final results = <AttendanceEntry>[];

    final batchLogRef = _firestore.collection('group_attendance_batches').doc();
    batch.set(batchLogRef, {
      'id': batchLogRef.id,
      'organizationId': orgId,
      'branchId': request.branchId,
      'workDate': dateString,
      'shiftName': request.shiftName,
      'attendeeCount': request.attendees.length,
      'createdBy': access.user.name,
      'createdById': access.user.id,
      'createdAt': FieldValue.serverTimestamp(),
      'note': request.note,
    });

    for (final attendee in request.attendees) {
      final docRef = _collection.doc();
      final entry = AttendanceEntry(
        id: docRef.id,
        organizationId: orgId,
        branchId: request.branchId,
        employeeId: attendee.employeeId,
        employeeName: attendee.employeeName,
        workDate: DateTime(
          request.workDate.year,
          request.workDate.month,
          request.workDate.day,
        ),
        status: request.status,
        reviewStatus: AttendanceReviewStatus.none,
        checkInAt: request.checkInAt,
        note: request.note,
        kioskEntry: false,
      );

      batch.set(docRef, {
        'id': entry.id,
        'organizationId': entry.organizationId,
        'branchId': entry.branchId,
        'employeeId': entry.employeeId,
        'employeeName': entry.employeeName,
        'workDate': Timestamp.fromDate(entry.workDate),
        'workDateString': dateString,
        'status': entry.status.name,
        'reviewStatus': entry.reviewStatus.name,
        'checkInAt': Timestamp.fromDate(entry.checkInAt!),
        'checkOutAt': null,
        'note': entry.note,
        'kioskEntry': entry.kioskEntry,
        'source': 'group_batch',
        'createdAt': FieldValue.serverTimestamp(),
      });

      results.add(entry);
    }

    try {
      await batch.commit();
      return results;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to commit group attendance batch: ${e.toString()}');
    }
  }

  AttendanceEntry _mapDocToEntry(String docId, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    final workDate = parseDate(data['workDate'], DateTime.now());
    final checkInAt = data['checkInAt'] != null
        ? parseDate(data['checkInAt'], workDate)
        : null;
    final checkOutAt = data['checkOutAt'] != null
        ? parseDate(data['checkOutAt'], workDate)
        : null;

    final statusStr = data['status'] as String? ?? 'present';
    final reviewStr = data['reviewStatus'] as String? ?? 'none';

    final status = AttendanceStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == statusStr.toLowerCase(),
      orElse: () => AttendanceStatus.present,
    );

    final reviewStatus = AttendanceReviewStatus.values.firstWhere(
      (r) => r.name.toLowerCase() == reviewStr.toLowerCase(),
      orElse: () => AttendanceReviewStatus.none,
    );

    return AttendanceEntry(
      id: docId,
      organizationId: data['organizationId'] as String? ?? '',
      branchId: data['branchId'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String? ?? 'Employee',
      workDate: workDate,
      status: status,
      reviewStatus: reviewStatus,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt,
      note: data['note'] as String?,
      kioskEntry: data['kioskEntry'] as bool? ?? false,
    );
  }
}
