import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_type_option.dart';

const annualLeave = LeaveTypeOption(
  id: 'lt-annual',
  name: 'Annual leave',
  paid: true,
);
const sickLeave = LeaveTypeOption(
  id: 'lt-sick',
  name: 'Sick leave',
  paid: true,
);
const unpaidLeave = LeaveTypeOption(
  id: 'lt-unpaid',
  name: 'Unpaid leave',
  paid: false,
);

LeaveRequest leaveRequest({
  String id = 'leave-1',
  String organizationId = 'org-acme',
  String branchId = 'br-01',
  String applicantUid = 'user-emp-01',
  UserRole applicantRole = UserRole.employee,
  LeaveStatus status = LeaveStatus.pending,
  LeaveTypeOption type = annualLeave,
  DateTime? startDate,
  DateTime? endDate,
  DateTime? createdAt,
}) {
  final start = startDate ?? DateTime(2026, 11, 20);
  return LeaveRequest(
    id: id,
    organizationId: organizationId,
    branchId: branchId,
    branchName: 'Downtown Flagship',
    applicantMemberId: applicantUid,
    applicantUid: applicantUid,
    applicantName: 'Applicant',
    applicantRole: applicantRole,
    leaveTypeId: type.id,
    leaveTypeName: type.name,
    leaveTypePaid: type.paid,
    startDate: start,
    endDate: endDate ?? start.add(const Duration(days: 1)),
    reason: 'Personal leave',
    status: status,
    createdAt: createdAt,
  );
}

/// Server-shaped JSON row for [request]. `leaveType` is the legacy code,
/// null for organization-defined types.
Map<String, dynamic> leaveRow(LeaveRequest request) => {
  'id': request.id,
  'organizationId': request.organizationId,
  'branchId': request.branchId,
  'branchName': request.branchName,
  'applicantMemberId': request.applicantMemberId,
  'applicantUid': request.applicantUid,
  'applicantName': request.applicantName,
  'applicantRole': request.applicantRole.name,
  'leaveTypeId': request.leaveTypeId,
  'leaveTypeName': request.leaveTypeName,
  'leaveTypePaid': request.leaveTypePaid,
  'startDate': _date(request.startDate),
  'endDate': _date(request.endDate),
  'reason': request.reason,
  'status': request.status.name,
};

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
