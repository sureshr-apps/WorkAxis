import 'package:workaxis/features/attendance/data/attendance_entry_mapper.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/checkout_correction.dart';

/// Maps `attendance_corrections` documents to [CheckoutCorrection].
abstract final class CheckoutCorrectionMapper {
  static CheckoutCorrection fromData(String docId, Map<String, dynamic> data) {
    final workDate = DateTime.tryParse(data['workDateString'] as String? ?? '');
    return CheckoutCorrection(
      id: docId,
      entryId: data['entryId'] as String? ?? '',
      organizationId: data['organizationId'] as String? ?? '',
      branchId: data['branchId'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String? ?? 'Unknown employee',
      workDate: workDate == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime(workDate.year, workDate.month, workDate.day),
      checkInAt: AttendanceEntryMapper.instant(data['checkInAt']),
      recordedCheckOutAt: AttendanceEntryMapper.instant(
        data['recordedCheckOutAt'],
      ),
      requestedCheckOutAt:
          AttendanceEntryMapper.instant(data['requestedCheckOutAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      reason: data['reason'] as String? ?? '',
      status: switch (data['status']) {
        'approved' => CorrectionStatus.approved,
        'rejected' => CorrectionStatus.rejected,
        _ => CorrectionStatus.pending,
      },
      createdAt: AttendanceEntryMapper.instant(data['createdAt']),
      reviewedBy: data['reviewedBy'] as String?,
      reviewNote: data['reviewNote'] as String?,
    );
  }
}
