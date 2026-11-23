import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/leaves/data/mock_leave_preview_calculator.dart';
import 'package:workaxis/features/leaves/data/mock_leaves_data_source.dart';
import 'package:workaxis/features/leaves/data/mock_leaves_repository.dart';
import 'package:workaxis/features/leaves/domain/models/leave_preview.dart';
import 'package:workaxis/features/leaves/domain/models/leave_queue.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';

import '../../helpers/access_fixtures.dart';
import 'leave_fixtures.dart';

void main() {
  group('MockLeavePreviewCalculator', () {
    const calculator = MockLeavePreviewCalculator();

    test('counts every day except Sunday', () {
      // Mon 30 Nov – Sun 6 Dec 2026.
      expect(
        MockLeavePreviewCalculator.workdaysBetween(
          DateTime(2026, 11, 30),
          DateTime(2026, 12, 6),
        ),
        6,
      );
      expect(
        MockLeavePreviewCalculator.workdaysBetween(
          DateTime(2026, 12, 6),
          DateTime(2026, 12, 6),
        ),
        0,
      );
    });

    test('splits paid and unpaid days by the remaining allowance', () {
      final preview = calculator.preview(
        type: annualLeave,
        yearlyDays: 5,
        startDate: DateTime(2026, 12, 7),
        endDate: DateTime(2026, 12, 11),
        applicantRequests: [
          leaveRequest(
            id: 'used',
            status: LeaveStatus.approved,
            startDate: DateTime(2026, 3, 2),
            endDate: DateTime(2026, 3, 3),
          ),
          leaveRequest(
            id: 'pending',
            startDate: DateTime(2026, 4, 1),
            endDate: DateTime(2026, 4, 30),
          ),
          leaveRequest(
            id: 'other-type',
            type: sickLeave,
            status: LeaveStatus.approved,
            startDate: DateTime(2026, 5, 4),
            endDate: DateTime(2026, 5, 8),
          ),
        ],
      );

      expect(
        preview,
        const LeavePreview(
          leaveTypeId: 'lt-annual',
          availableDays: 3,
          workdays: 5,
          paidDays: 3,
          unpaidDays: 2,
        ),
      );
    });

    test('ignores the excluded request and other years', () {
      final preview = calculator.preview(
        type: annualLeave,
        yearlyDays: 4,
        startDate: DateTime(2027, 1, 4),
        endDate: DateTime(2027, 1, 5),
        applicantRequests: [
          // Mon 28 Dec 2026 – Sat 2 Jan 2027: only Fri 1 and Sat 2 count.
          leaveRequest(
            id: 'across-years',
            status: LeaveStatus.approved,
            startDate: DateTime(2026, 12, 28),
            endDate: DateTime(2027, 1, 2),
          ),
          leaveRequest(
            id: 'self',
            status: LeaveStatus.approved,
            startDate: DateTime(2027, 1, 4),
            endDate: DateTime(2027, 1, 5),
          ),
        ],
        excludeRequestId: 'self',
      );

      expect(preview.availableDays, 2);
      expect(preview.paidDays, 2);
      expect(preview.unpaidDays, 0);
    });

    test('an unpaid type is never paid', () {
      final preview = calculator.preview(
        type: unpaidLeave,
        yearlyDays: 0,
        startDate: DateTime(2026, 11, 24),
        endDate: DateTime(2026, 11, 25),
        applicantRequests: const [],
      );

      expect(preview.availableDays, 0);
      expect(preview.paidDays, 0);
      expect(preview.unpaidDays, 2);
    });
  });

  group('MockLeavesRepository leave types and previews', () {
    late MockLeavesRepository repository;

    setUp(() {
      // Monday; the seeded approved sick leave covers Wed 18 – Thu 19 Nov.
      repository = MockLeavesRepository(
        MockLeavesDataSource(now: () => DateTime(2026, 11, 23, 9)),
        delay: Duration.zero,
      );
    });

    test('lists the seeded organization types', () async {
      final types = await repository.getLeaveTypes(access: employeeAccess());

      expect(types.map((t) => t.name), [
        'Annual leave',
        'Sick leave',
        'Personal leave',
        'Unpaid leave',
      ]);
      expect(types.where((t) => !t.paid).map((t) => t.id), ['lt-unpaid']);
    });

    test('a draft preview deducts approved leave of the same type', () async {
      final preview = await repository.previewLeaveDraft(
        access: employeeAccess(),
        leaveTypeId: 'lt-sick',
        startDate: DateTime(2026, 11, 30),
        endDate: DateTime(2026, 12, 6),
      );

      expect(
        preview,
        const LeavePreview(
          leaveTypeId: 'lt-sick',
          availableDays: 4,
          workdays: 6,
          paidDays: 4,
          unpaidDays: 2,
        ),
      );
    });

    test('a review preview uses the applicant balance and scope', () async {
      final page = await repository.getLeaveRequestsPage(
        access: orgAdminAccess(),
        queue: LeaveQueue.organization,
      );
      final annual = page.items.firstWhere((r) => r.id == 'LV-001');

      final preview = await repository.previewLeaveReview(
        access: orgAdminAccess(),
        request: annual,
      );

      expect(preview.availableDays, 12);
      expect(preview.workdays, 2);
      expect(preview.unpaidDays, 0);
      expect(
        repository.previewLeaveReview(
          access: branchManagerAccess(),
          activeBranchId: 'br-02',
          request: annual,
        ),
        throwsA(isA<BranchAuthorizationException>()),
      );
    });

    test('submitting an unknown type fails like the server', () {
      expect(
        repository.submitLeaveRequest(
          access: employeeAccess(),
          draft: LeaveRequestDraft(
            leaveTypeId: 'lt-archived',
            startDate: DateTime(2026, 12, 1),
            endDate: DateTime(2026, 12, 1),
            reason: 'Trip',
          ),
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Choose an available leave type.',
          ),
        ),
      );
    });

    test('a submitted request carries the type name and paid flag', () async {
      final saved = await repository.submitLeaveRequest(
        access: employeeAccess(),
        draft: LeaveRequestDraft(
          leaveTypeId: 'lt-unpaid',
          startDate: DateTime(2026, 12, 1),
          endDate: DateTime(2026, 12, 1),
          reason: 'Trip',
        ),
      );

      expect(saved.leaveTypeId, 'lt-unpaid');
      expect(saved.leaveTypeName, 'Unpaid leave');
      expect(saved.leaveTypePaid, isFalse);
    });
  });
}
