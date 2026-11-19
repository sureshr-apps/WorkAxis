import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/services/leave_scope.dart';

import '../../helpers/access_fixtures.dart';

void main() {
  const scope = LeaveScope();

  group('LeaveScope', () {
    test('employees can apply only for an assigned active branch', () {
      final access = employeeAccess();

      expect(scope.forSubmit(access).id, 'br-01');
      expect(
        () => scope.forSubmit(access, branchId: 'br-02'),
        throwsA(isA<BranchAuthorizationException>()),
      );
    });

    test('Branch Managers must apply for their active branch', () {
      final access = branchManagerAccess();

      expect(
        scope.forSubmit(access, branchId: 'br-01', activeBranchId: 'br-01').id,
        'br-01',
      );
      expect(
        () =>
            scope.forSubmit(access, branchId: 'br-02', activeBranchId: 'br-01'),
        throwsA(isA<BranchAuthorizationException>()),
      );
    });

    test(
      'Branch Managers can review employee requests in the active branch',
      () {
        final access = branchManagerAccess();

        expect(
          scope
              .forReview(access, activeBranchId: 'br-01', request: _request())
              .id,
          'br-01',
        );
        expect(
          () => scope.forReview(
            access,
            activeBranchId: 'br-02',
            request: _request(),
          ),
          throwsA(isA<BranchAuthorizationException>()),
        );
      },
    );

    test('only Organization Admins can review a Branch Manager request', () {
      final managerRequest = _request(
        applicantUid: 'user-bm-01',
        applicantRole: UserRole.branchManager,
      );

      expect(
        () => scope.forReview(
          branchManagerAccess(),
          activeBranchId: 'br-01',
          request: managerRequest,
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      expect(
        scope
            .forReview(
              orgAdminAccess(),
              activeBranchId: null,
              request: managerRequest,
            )
            .id,
        'br-01',
      );
    });

    test('only the applicant can edit pending requests', () {
      final request = _request();

      expect(
        () => scope.assertCanEditPending(
          employeeAccess(id: 'another-employee'),
          request,
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      expect(
        () => scope.assertCanEditPending(
          employeeAccess(),
          _request(status: LeaveStatus.approved),
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      expect(
        () => scope.assertCanEditPending(employeeAccess(), request),
        returnsNormally,
      );
    });

    test('customer users cannot read across organizations', () {
      expect(
        () => scope.forReview(
          orgAdminAccess(),
          activeBranchId: null,
          request: _request(organizationId: 'org-other'),
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });
  });
}

LeaveRequest _request({
  String organizationId = 'org-acme',
  String branchId = 'br-01',
  String applicantUid = 'user-emp-01',
  UserRole applicantRole = UserRole.employee,
  LeaveStatus status = LeaveStatus.pending,
}) => LeaveRequest(
  id: 'leave-1',
  organizationId: organizationId,
  branchId: branchId,
  branchName: 'Downtown Flagship',
  applicantMemberId: applicantUid,
  applicantUid: applicantUid,
  applicantName: 'Applicant',
  applicantRole: applicantRole,
  leaveType: LeaveType.annual,
  startDate: DateTime.utc(2026, 11, 20),
  endDate: DateTime.utc(2026, 11, 21),
  reason: 'Personal leave',
  status: status,
);
