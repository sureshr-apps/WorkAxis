import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/data/sql_connect_leaves_repository.dart';
import 'package:workaxis/features/leaves/domain/models/leave_preview.dart';
import 'package:workaxis/features/leaves/domain/models/leave_queue.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_status_counts.dart';

import '../../helpers/access_fixtures.dart';
import '../../helpers/fake_data_gateway.dart';
import 'leave_fixtures.dart';

void main() {
  late FakeDataGateway gateway;
  late SqlConnectLeavesRepository repository;

  Map<String, dynamic> pageResponse(List<LeaveRequest> rows, int total) => {
    'leaveRequests': [for (final row in rows) leaveRow(row)],
    'total': [
      {'_count': total},
    ],
  };

  setUp(() {
    gateway = FakeDataGateway();
    repository = SqlConnectLeavesRepository(gateway: gateway);
  });

  group('SqlConnectLeavesRepository paging', () {
    test('mine queue reads one page of ListMyLeaveRequests', () async {
      gateway.respond(
        'ListMyLeaveRequests',
        pageResponse([leaveRequest(id: 'a'), leaveRequest(id: 'b')], 7),
      );

      final page = await repository.getLeaveRequestsPage(
        access: employeeAccess(),
        queue: LeaveQueue.mine,
        offset: 25,
        limit: 2,
      );

      expect(gateway.calls, hasLength(1));
      expect(gateway.singleVarsOf('ListMyLeaveRequests'), {
        'limit': 2,
        'offset': 25,
      });
      expect(page.items.map((r) => r.id), ['a', 'b']);
      expect(page.total, 7);
      expect(page.offset, 25);
    });

    test('employee queue sends the active branch and the status', () async {
      gateway.respond(
        'ListEmployeeLeaveRequestsByBranchPaged',
        pageResponse([], 0),
      );

      await repository.getLeaveRequestsPage(
        access: branchManagerAccess(),
        activeBranchId: 'br-02',
        queue: LeaveQueue.branchEmployees,
        status: LeaveStatus.pending,
      );

      expect(gateway.singleVarsOf('ListEmployeeLeaveRequestsByBranchPaged'), {
        'branchId': 'br-02',
        'limit': 25,
        'offset': 0,
        'status': 'pending',
      });
    });

    test('organization queue uses the org paged op without a branch', () async {
      gateway.respond(
        'ListOrganizationLeaveRequestsPaged',
        pageResponse([], 3),
      );

      final page = await repository.getLeaveRequestsPage(
        access: orgAdminAccess(),
        queue: LeaveQueue.organization,
        status: LeaveStatus.approved,
      );

      expect(gateway.singleVarsOf('ListOrganizationLeaveRequestsPaged'), {
        'limit': 25,
        'offset': 0,
        'status': 'approved',
      });
      expect(page.total, 3);
    });

    test('a Branch Manager never merges queues client-side', () async {
      gateway.respond('ListMyLeaveRequests', pageResponse([], 0));

      await repository.getLeaveRequestsPage(
        access: branchManagerAccess(),
        queue: LeaveQueue.mine,
      );

      expect(gateway.calls.map((c) => c.op), ['ListMyLeaveRequests']);
    });

    test('an unauthorized queue is rejected before calling the server', () {
      expect(
        repository.getLeaveRequestsPage(
          access: branchManagerAccess(),
          activeBranchId: 'br-04',
          queue: LeaveQueue.branchEmployees,
        ),
        throwsA(isA<BranchAuthorizationException>()),
      );
      expect(gateway.calls, isEmpty);
    });
  });

  group('SqlConnectLeavesRepository status counts', () {
    test('reads GetLeaveStatusCounts for each queue scope', () async {
      gateway.respond('GetLeaveStatusCounts', {
        'counts': {'pending': 4, 'approved': 9, 'rejected': 1},
      });

      final mine = await repository.getLeaveStatusCounts(
        access: branchManagerAccess(),
        queue: LeaveQueue.mine,
      );
      await repository.getLeaveStatusCounts(
        access: branchManagerAccess(),
        activeBranchId: 'br-01',
        queue: LeaveQueue.branchEmployees,
      );
      await repository.getLeaveStatusCounts(
        access: orgAdminAccess(),
        queue: LeaveQueue.organization,
      );

      expect(
        mine,
        const LeaveStatusCounts(pending: 4, approved: 9, rejected: 1),
      );
      expect(gateway.varsOf('GetLeaveStatusCounts'), [
        {'scope': 'mine'},
        {'scope': 'branchEmployees', 'branchId': 'br-01'},
        {'scope': 'organization'},
      ]);
    });
  });

  group('SqlConnectLeavesRepository organization leave types', () {
    final draft = LeaveRequestDraft(
      leaveTypeId: 'lt-sick',
      startDate: DateTime(2026, 11, 24),
      endDate: DateTime(2026, 11, 26),
      reason: ' Fever ',
    );

    test('parses the leave type fields of a row', () async {
      gateway.respond(
        'ListMyLeaveRequests',
        pageResponse([leaveRequest(type: unpaidLeave)], 1),
      );

      final page = await repository.getLeaveRequestsPage(
        access: employeeAccess(),
        queue: LeaveQueue.mine,
      );

      final request = page.items.single;
      expect(request.leaveTypeId, 'lt-unpaid');
      expect(request.leaveTypeName, 'Unpaid leave');
      expect(request.leaveTypePaid, isFalse);
    });

    test('submit sends leaveTypeId and never the legacy leaveType', () async {
      gateway.respond('SubmitLeaveRequest', {
        'leaveRequest': leaveRow(leaveRequest(type: sickLeave)),
      });

      final saved = await repository.submitLeaveRequest(
        access: employeeAccess(),
        draft: draft,
      );

      final vars = gateway.singleVarsOf('SubmitLeaveRequest');
      expect(vars['leaveTypeId'], 'lt-sick');
      expect(vars.containsKey('leaveType'), isFalse);
      expect(vars['startDate'], '2026-11-24');
      expect(vars['endDate'], '2026-11-26');
      expect(vars['reason'], 'Fever');
      expect(saved.leaveTypeName, 'Sick leave');
    });

    test('update sends leaveTypeId and never the legacy leaveType', () async {
      gateway.respond('UpdateMyPendingLeaveRequest', {
        'leaveRequest': leaveRow(leaveRequest(type: sickLeave)),
      });

      await repository.updatePendingLeaveRequest(
        access: employeeAccess(),
        request: leaveRequest(),
        draft: draft,
      );

      expect(gateway.singleVarsOf('UpdateMyPendingLeaveRequest'), {
        'id': 'leave-1',
        'leaveTypeId': 'lt-sick',
        'startDate': '2026-11-24',
        'endDate': '2026-11-26',
        'reason': 'Fever',
      });
    });

    test('ListLeaveTypes returns the organization types in order', () async {
      gateway.respond('ListLeaveTypes', {
        'leaveTypes': [
          {'id': 'lt-annual', 'name': 'Annual leave', 'paid': true},
          {'id': 'lt-unpaid', 'name': 'Unpaid leave', 'paid': false},
        ],
      });

      final types = await repository.getLeaveTypes(access: orgAdminAccess());

      expect(gateway.singleVarsOf('ListLeaveTypes'), isEmpty);
      expect(types, [annualLeave, unpaidLeave]);
    });

    test('platform users cannot list leave types', () {
      expect(
        repository.getLeaveTypes(access: platformAccess()),
        throwsA(isA<AccessDeniedException>()),
      );
      expect(gateway.calls, isEmpty);
    });

    test('a draft preview sends the type, dates and edited id', () async {
      gateway.respond('PreviewLeaveRequest', {
        'leavePreview': {
          'leaveTypeId': 'lt-annual',
          'availableDays': 2,
          'workdays': 3,
          'paidDays': 2,
          'unpaidDays': 1,
        },
      });

      final preview = await repository.previewLeaveDraft(
        access: branchManagerAccess(),
        leaveTypeId: 'lt-annual',
        startDate: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, 3),
        editingRequestId: 'leave-9',
      );
      await repository.previewLeaveDraft(
        access: employeeAccess(),
        leaveTypeId: 'lt-annual',
        startDate: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, 1),
      );

      expect(gateway.varsOf('PreviewLeaveRequest'), [
        {
          'leaveTypeId': 'lt-annual',
          'startDate': '2026-12-01',
          'endDate': '2026-12-03',
          'id': 'leave-9',
        },
        {
          'leaveTypeId': 'lt-annual',
          'startDate': '2026-12-01',
          'endDate': '2026-12-01',
        },
      ]);
      expect(
        preview,
        const LeavePreview(
          leaveTypeId: 'lt-annual',
          availableDays: 2,
          workdays: 3,
          paidDays: 2,
          unpaidDays: 1,
        ),
      );
    });

    test('Org Admins cannot preview a draft', () {
      expect(
        repository.previewLeaveDraft(
          access: orgAdminAccess(),
          leaveTypeId: 'lt-annual',
          startDate: DateTime(2026, 12, 1),
          endDate: DateTime(2026, 12, 1),
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      expect(gateway.calls, isEmpty);
    });

    test('a review preview sends the request id and manager branch', () async {
      gateway.respond('PreviewLeaveRequest', {
        'leavePreview': {
          'leaveTypeId': 'lt-annual',
          'availableDays': 5,
          'workdays': 2,
          'paidDays': 2,
          'unpaidDays': 0,
        },
      });

      await repository.previewLeaveReview(
        access: branchManagerAccess(),
        request: leaveRequest(id: 'leave-7'),
      );
      await repository.previewLeaveReview(
        access: orgAdminAccess(),
        request: leaveRequest(id: 'leave-8'),
      );

      expect(gateway.varsOf('PreviewLeaveRequest'), [
        {'id': 'leave-7', 'activeBranchId': 'br-01'},
        {'id': 'leave-8'},
      ]);
    });

    test('a review preview outside the active branch is rejected', () {
      expect(
        repository.previewLeaveReview(
          access: branchManagerAccess(),
          request: leaveRequest(branchId: 'br-02'),
        ),
        throwsA(isA<BranchAuthorizationException>()),
      );
      expect(
        repository.previewLeaveReview(
          access: branchManagerAccess(),
          request: leaveRequest(applicantRole: UserRole.branchManager),
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      expect(gateway.calls, isEmpty);
    });
  });
}
