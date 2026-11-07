import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/organization_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/data/firestore_attendance_repository.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

void main() {
  group('FirestoreAttendanceRepository Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreAttendanceRepository repository;

    final testDate = DateTime(2026, 11, 7, 9, 30);
    const dateStr = '2026-11-07';

    const testOrg = OrganizationSummary(
      id: 'org-test-1',
      name: 'Test Corp',
      code: 'TST',
    );

    const branch1 = BranchSummary(
      id: 'branch-101',
      organizationId: 'org-test-1',
      name: 'Downtown Flagship',
      code: 'DT01',
      location: 'Downtown',
    );

    const branch2 = BranchSummary(
      id: 'branch-102',
      organizationId: 'org-test-1',
      name: 'Uptown Store',
      code: 'UP02',
      location: 'Uptown',
    );

    const platformUser = AppUser(
      id: 'platform-user-1',
      name: 'Super Admin',
      username: 'admin',
      role: UserRole.platformAdmin,
      status: AccountStatus.active,
    );

    const orgAdminUser = AppUser(
      id: 'org-admin-1',
      name: 'Org Executive',
      username: 'org_admin',
      role: UserRole.orgAdmin,
      status: AccountStatus.active,
      organizationId: 'org-test-1',
    );

    const branchManagerUser = AppUser(
      id: 'manager-1',
      name: 'Branch Lead',
      username: 'mgr_lead',
      role: UserRole.branchManager,
      status: AccountStatus.active,
      organizationId: 'org-test-1',
    );

    const employeeUser = AppUser(
      id: 'emp-1',
      name: 'Regular Employee',
      username: 'emp_john',
      role: UserRole.employee,
      status: AccountStatus.active,
      organizationId: 'org-test-1',
    );

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreAttendanceRepository(firestore: fakeFirestore);
    });

    test('getAttendance: platform operator can query across all branches', () async {
      await fakeFirestore.collection('attendance_entries').doc('entry-1').set({
        'organizationId': 'org-test-1',
        'branchId': 'branch-101',
        'employeeId': 'emp-1',
        'employeeName': 'John',
        'workDate': Timestamp.fromDate(testDate),
        'workDateString': dateStr,
        'status': 'present',
        'reviewStatus': 'none',
      });

      const context = UserAccessContext(
        user: platformUser,
        organization: null,
        assignedBranches: [],
      );

      final entries = await repository.getAttendance(
        access: context,
        date: testDate,
      );

      expect(entries.length, equals(1));
      expect(entries.first.id, equals('entry-1'));
    });

    test('getAttendance: non-platform user without org context throws AccessDeniedException', () async {
      const context = UserAccessContext(
        user: orgAdminUser,
        organization: null,
        assignedBranches: [],
      );

      expect(
        () => repository.getAttendance(access: context, date: testDate),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('getAttendance: orgAdmin queries records scoped to org', () async {
      await fakeFirestore.collection('attendance_entries').doc('entry-org1').set({
        'organizationId': 'org-test-1',
        'branchId': 'branch-101',
        'employeeId': 'emp-1',
        'workDate': Timestamp.fromDate(testDate),
        'workDateString': dateStr,
        'status': 'present',
      });
      await fakeFirestore.collection('attendance_entries').doc('entry-org2').set({
        'organizationId': 'org-other-2',
        'branchId': 'branch-201',
        'employeeId': 'emp-other',
        'workDate': Timestamp.fromDate(testDate),
        'workDateString': dateStr,
        'status': 'present',
      });

      const context = UserAccessContext(
        user: orgAdminUser,
        organization: testOrg,
        assignedBranches: [branch1, branch2],
      );

      final entries = await repository.getAttendance(
        access: context,
        date: testDate,
      );

      expect(entries.length, equals(1));
      expect(entries.first.id, equals('entry-org1'));
    });

    test('getAttendance: branchManager with unauthorized branch throws AccessDeniedException', () async {
      const context = UserAccessContext(
        user: branchManagerUser,
        organization: testOrg,
        assignedBranches: [branch1], // only assigned to branch-101
      );

      expect(
        () => repository.getAttendance(
          access: context,
          date: testDate,
          activeBranchId: 'branch-102', // unauthorized branch-102
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('getAttendance: branchManager with assigned branch succeeds', () async {
      await fakeFirestore.collection('attendance_entries').doc('entry-b1').set({
        'organizationId': 'org-test-1',
        'branchId': 'branch-101',
        'employeeId': 'emp-1',
        'workDate': Timestamp.fromDate(testDate),
        'workDateString': dateStr,
        'status': 'late',
      });

      final context = UserAccessContext(
        user: branchManagerUser,
        organization: testOrg,
        assignedBranches: const [branch1],
        activeBranch: ActiveBranchContext.fromBranch(branch1),
      );

      final entries = await repository.getAttendance(
        access: context,
        date: testDate,
        activeBranchId: 'branch-101',
      );

      expect(entries.length, equals(1));
      expect(entries.first.status, equals(AttendanceStatus.late));
    });

    test('getAttendance: employee is strictly restricted to self entries', () async {
      await fakeFirestore.collection('attendance_entries').doc('entry-self').set({
        'organizationId': 'org-test-1',
        'branchId': 'branch-101',
        'employeeId': 'emp-1',
        'workDate': Timestamp.fromDate(testDate),
        'workDateString': dateStr,
        'status': 'present',
      });
      await fakeFirestore.collection('attendance_entries').doc('entry-peer').set({
        'organizationId': 'org-test-1',
        'branchId': 'branch-101',
        'employeeId': 'emp-peer-2',
        'workDate': Timestamp.fromDate(testDate),
        'workDateString': dateStr,
        'status': 'present',
      });

      const context = UserAccessContext(
        user: employeeUser,
        organization: testOrg,
        assignedBranches: [branch1],
      );

      final entries = await repository.getAttendance(
        access: context,
        date: testDate,
      );

      expect(entries.length, equals(1));
      expect(entries.first.id, equals('entry-self'));
      expect(entries.first.employeeId, equals('emp-1'));
    });

    test('reviewException: unauthorized branchManager throws AccessDeniedException', () async {
      const context = UserAccessContext(
        user: branchManagerUser,
        organization: testOrg,
        assignedBranches: [branch1],
      );

      expect(
        () => repository.reviewException(
          access: context,
          entryId: 'entry-1',
          activeBranchId: 'branch-102',
          decision: AttendanceReviewDecision.verify,
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('reviewException: employee cannot review exceptions', () async {
      const context = UserAccessContext(
        user: employeeUser,
        organization: testOrg,
        assignedBranches: [branch1],
      );

      expect(
        () => repository.reviewException(
          access: context,
          entryId: 'entry-1',
          activeBranchId: 'branch-101',
          decision: AttendanceReviewDecision.verify,
        ),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('reviewException: nonexistent record throws NotFoundException', () async {
      const context = UserAccessContext(
        user: orgAdminUser,
        organization: testOrg,
        assignedBranches: [branch1],
      );

      expect(
        () => repository.reviewException(
          access: context,
          entryId: 'nonexistent-doc',
          activeBranchId: 'branch-101',
          decision: AttendanceReviewDecision.verify,
        ),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('reviewException: successfully verifies and updates record', () async {
      await fakeFirestore.collection('attendance_entries').doc('entry-exc-1').set({
        'organizationId': 'org-test-1',
        'branchId': 'branch-101',
        'employeeId': 'emp-1',
        'employeeName': 'John Regular',
        'workDate': Timestamp.fromDate(testDate),
        'workDateString': dateStr,
        'status': 'late',
        'reviewStatus': 'pending',
      });

      const context = UserAccessContext(
        user: branchManagerUser,
        organization: testOrg,
        assignedBranches: [branch1],
      );

      final updated = await repository.reviewException(
        access: context,
        entryId: 'entry-exc-1',
        activeBranchId: 'branch-101',
        decision: AttendanceReviewDecision.verify,
      );

      expect(updated.reviewStatus, equals(AttendanceReviewStatus.verified));

      final persisted =
          await fakeFirestore.collection('attendance_entries').doc('entry-exc-1').get();
      expect(persisted.data()?['reviewStatus'], equals('verified'));
      expect(persisted.data()?['reviewedBy'], equals('Branch Lead'));
      expect(persisted.data()?['reviewedById'], equals('manager-1'));
    });

    test('markGroupAttendance: authorized manager creates batch and attendees records', () async {
      const context = UserAccessContext(
        user: branchManagerUser,
        organization: testOrg,
        assignedBranches: [branch1],
      );

      final request = GroupAttendanceRequest(
        branchId: 'branch-101',
        workDate: testDate,
        shiftName: 'Morning Shift',
        status: AttendanceStatus.present,
        checkInAt: testDate,
        note: 'Team check-in',
        attendees: [
          const GroupAttendanceAttendee(
            employeeId: 'emp-101',
            employeeName: 'Alice Worker',
          ),
          const GroupAttendanceAttendee(
            employeeId: 'emp-102',
            employeeName: 'Bob Builder',
          ),
        ],
      );

      final results = await repository.markGroupAttendance(
        access: context,
        request: request,
      );

      expect(results.length, equals(2));
      expect(results[0].employeeName, equals('Alice Worker'));
      expect(results[1].employeeName, equals('Bob Builder'));

      // Verify batch record in group_attendance_batches
      final batchesSnapshot =
          await fakeFirestore.collection('group_attendance_batches').get();
      expect(batchesSnapshot.docs.length, equals(1));
      expect(batchesSnapshot.docs.first.data()['attendeeCount'], equals(2));
      expect(batchesSnapshot.docs.first.data()['shiftName'], equals('Morning Shift'));

      // Verify individual entries created in attendance_entries
      final entriesSnapshot =
          await fakeFirestore.collection('attendance_entries').get();
      expect(entriesSnapshot.docs.length, equals(2));
    });
  });
}
