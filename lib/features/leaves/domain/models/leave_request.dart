import 'package:workaxis/features/authentication/domain/models/user_role.dart';

enum LeaveStatus {
  pending,
  approved,
  rejected;

  static LeaveStatus? tryParse(String? raw) {
    final value = raw?.trim().toLowerCase();
    for (final status in values) {
      if (status.name == value) return status;
    }
    return null;
  }

  String get label => switch (this) {
    LeaveStatus.pending => 'Pending',
    LeaveStatus.approved => 'Approved',
    LeaveStatus.rejected => 'Rejected',
  };
}

class LeaveRequestDraft {
  const LeaveRequestDraft({
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  /// Id of one of the organization's active leave types.
  final String leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
}

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.organizationId,
    required this.branchId,
    required this.branchName,
    required this.applicantMemberId,
    required this.applicantUid,
    required this.applicantName,
    required this.applicantRole,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.leaveTypePaid,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.reviewerUid,
    this.reviewerName,
    this.reviewerNotes,
    this.reviewedAt,
    this.createdAt,
  });

  final String id;
  final String organizationId;
  final String branchId;
  final String branchName;
  final String applicantMemberId;
  final String applicantUid;
  final String applicantName;
  final UserRole applicantRole;
  final String leaveTypeId;
  final String leaveTypeName;

  /// False for a type that is never paid (e.g. the built-in "Unpaid leave").
  final bool leaveTypePaid;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final String? reviewerUid;
  final String? reviewerName;
  final String? reviewerNotes;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  int get inclusiveDays => endDate.difference(startDate).inDays + 1;

  bool get needsOrganizationAdminReview =>
      applicantRole == UserRole.branchManager;

  LeaveRequest copyWith({
    String? leaveTypeId,
    String? leaveTypeName,
    bool? leaveTypePaid,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    LeaveStatus? status,
    String? reviewerUid,
    String? reviewerName,
    String? reviewerNotes,
    DateTime? reviewedAt,
  }) => LeaveRequest(
    id: id,
    organizationId: organizationId,
    branchId: branchId,
    branchName: branchName,
    applicantMemberId: applicantMemberId,
    applicantUid: applicantUid,
    applicantName: applicantName,
    applicantRole: applicantRole,
    leaveTypeId: leaveTypeId ?? this.leaveTypeId,
    leaveTypeName: leaveTypeName ?? this.leaveTypeName,
    leaveTypePaid: leaveTypePaid ?? this.leaveTypePaid,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    reason: reason ?? this.reason,
    status: status ?? this.status,
    reviewerUid: reviewerUid ?? this.reviewerUid,
    reviewerName: reviewerName ?? this.reviewerName,
    reviewerNotes: reviewerNotes ?? this.reviewerNotes,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    createdAt: createdAt,
  );
}
