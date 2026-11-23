import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/leaves/data/mock_leaves_data_source.dart';
import 'package:workaxis/features/leaves/data/mock_leaves_repository.dart';
import 'package:workaxis/features/leaves/domain/models/leave_queue.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/models/leave_status_counts.dart';

import '../../helpers/access_fixtures.dart';
import 'leave_fixtures.dart';

void main() {
  late MockLeavesDataSource dataSource;
  late MockLeavesRepository repository;

  setUp(() {
    dataSource = MockLeavesDataSource(now: () => DateTime(2026, 11, 23, 9));
    repository = MockLeavesRepository(dataSource, delay: Duration.zero);
  });

  void seed(List<LeaveRequest> requests) => requests.forEach(dataSource.save);

  group('MockLeavesRepository', () {
    test('orders pending first, then by start date ascending', () async {
      seed([
        leaveRequest(
          id: 'a',
          status: LeaveStatus.approved,
          startDate: DateTime(2026, 1, 1),
        ),
        leaveRequest(id: 'b', startDate: DateTime(2026, 12, 30)),
        leaveRequest(id: 'c', startDate: DateTime(2026, 2, 1)),
        leaveRequest(
          id: 'd',
          status: LeaveStatus.rejected,
          startDate: DateTime(2025, 6, 1),
        ),
      ]);

      final page = await repository.getLeaveRequestsPage(
        access: orgAdminAccess(),
        queue: LeaveQueue.organization,
        limit: 100,
      );
      final statuses = page.items.map((r) => r.status).toList();
      final firstSettled = statuses.indexWhere((s) => s != LeaveStatus.pending);

      expect(
        statuses.skip(firstSettled),
        everyElement(isNot(LeaveStatus.pending)),
      );
      for (final group in [
        page.items.take(firstSettled).toList(),
        page.items.skip(firstSettled).toList(),
      ]) {
        for (var i = 1; i < group.length; i++) {
          expect(
            group[i - 1].startDate.isAfter(group[i].startDate),
            isFalse,
            reason: 'start dates ascend within each status group',
          );
        }
      }
      expect(
        page.items.map((r) => r.id),
        containsAllInOrder(['c', 'b', 'd', 'a']),
      );
    });

    test('pages with offset and limit and reports the total', () async {
      seed([
        for (var i = 0; i < 7; i++)
          leaveRequest(id: 'p$i', startDate: DateTime(2027, 1, 1 + i)),
      ]);
      final access = orgAdminAccess();
      final all = await repository.getLeaveRequestsPage(
        access: access,
        queue: LeaveQueue.organization,
        limit: 100,
      );

      final first = await repository.getLeaveRequestsPage(
        access: access,
        queue: LeaveQueue.organization,
        limit: 4,
      );
      final second = await repository.getLeaveRequestsPage(
        access: access,
        queue: LeaveQueue.organization,
        offset: first.nextOffset,
        limit: 4,
      );
      final rest = await repository.getLeaveRequestsPage(
        access: access,
        queue: LeaveQueue.organization,
        offset: second.nextOffset,
        limit: 4,
      );

      expect(first.items, hasLength(4));
      expect(first.total, all.total);
      expect(first.hasMore, isTrue);
      expect(
        [...first.items, ...second.items, ...rest.items].map((r) => r.id),
        all.items.map((r) => r.id),
      );
      expect(rest.hasMore, isFalse);
    });

    test('status filter narrows the page but not the counts', () async {
      final access = orgAdminAccess();
      final pending = await repository.getLeaveRequestsPage(
        access: access,
        queue: LeaveQueue.organization,
        status: LeaveStatus.pending,
      );
      final counts = await repository.getLeaveStatusCounts(
        access: access,
        queue: LeaveQueue.organization,
      );

      expect(pending.items.every((r) => r.status == LeaveStatus.pending), true);
      expect(pending.total, counts.pending);
      expect(
        counts,
        const LeaveStatusCounts(pending: 2, approved: 1, rejected: 0),
      );
    });

    test('Branch Manager queues map to one scope each', () async {
      final access = branchManagerAccess(id: 'user-bm-multi-01');
      seed([
        leaveRequest(id: 'other-branch', branchId: 'br-02'),
        leaveRequest(
          id: 'other-manager',
          applicantUid: 'user-bm-02',
          applicantRole: UserRole.branchManager,
        ),
      ]);

      final mine = await repository.getLeaveRequestsPage(
        access: access,
        queue: LeaveQueue.mine,
      );
      final employees = await repository.getLeaveRequestsPage(
        access: access,
        activeBranchId: 'br-01',
        queue: LeaveQueue.branchEmployees,
      );

      expect(mine.items.map((r) => r.id), ['LV-002']);
      expect(employees.items.map((r) => r.id), ['LV-001', 'LV-003']);
      expect(
        await repository.getLeaveStatusCounts(
          access: access,
          activeBranchId: 'br-01',
          queue: LeaveQueue.branchEmployees,
        ),
        const LeaveStatusCounts(pending: 1, approved: 1, rejected: 0),
      );
    });

    test('rejects a queue the role may not read', () {
      expect(
        repository.getLeaveRequestsPage(
          access: employeeAccess(),
          queue: LeaveQueue.organization,
        ),
        throwsA(isA<AccessDeniedException>()),
      );
      expect(
        repository.getLeaveStatusCounts(
          access: branchManagerAccess(),
          activeBranchId: 'br-04',
          queue: LeaveQueue.branchEmployees,
        ),
        throwsA(isA<BranchAuthorizationException>()),
      );
    });
  });
}
