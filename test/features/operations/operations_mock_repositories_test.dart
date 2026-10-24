import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/data/mock_access_data_source.dart';
import 'package:workaxis/features/access/data/mock_access_repository.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/data/mock_attendance_repository.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/branches/data/mock_branch_management_repository.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/employees/data/mock_organization_members_repository.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

void main() {
  group('Mock branch management', () {
    test('creates branches, assigns managers and pairs a kiosk', () async {
      final dataSource = MockAccessDataSource();
      final repository = MockBranchManagementRepository(
        accessDataSource: dataSource,
      );
      final orgAdmin = await _accessFor(
        dataSource,
        id: 'user-oa-01',
        name: 'Jordan Lee',
        role: UserRole.orgAdmin,
      );

      final saved = await repository.saveBranch(
        access: orgAdmin,
        branch: _branch(id: '', managerIds: const ['user-bm-single-01']),
      );

      expect(saved.code, 'BR-105');
      expect(saved.geofenceRadiusMeters, 210);
      expect(saved.managerIds, ['user-bm-single-01']);
      expect(
        (await MockAccessRepository(
          dataSource: dataSource,
          delay: Duration.zero,
        ).getAssignedBranches('user-bm-single-01')).map((branch) => branch.id),
        contains(saved.id),
      );

      final token = await repository.createKioskPairingToken(
        access: orgAdmin,
        branchId: saved.id,
      );
      expect(token.value, startsWith('WA-'));
      expect(
        (await repository.getBranch(orgAdmin, saved.id))?.kioskStatus,
        KioskPairingStatus.pairingPending,
      );
      await repository.completeKioskPairing(
        access: orgAdmin,
        branchId: saved.id,
      );
      expect(
        (await repository.getBranch(orgAdmin, saved.id))?.kioskStatus,
        KioskPairingStatus.paired,
      );
    });

    test(
      'prevents branch managers from changing branch configuration',
      () async {
        final dataSource = MockAccessDataSource();
        final repository = MockBranchManagementRepository(
          accessDataSource: dataSource,
        );
        final manager = await _accessFor(
          dataSource,
          id: 'user-bm-multi-01',
          name: 'Marcus Chen',
          role: UserRole.branchManager,
        );

        await expectLater(
          repository.getBranches(manager),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('Mock organization member scope', () {
    test(
      'branch manager sees and manages only employees in the active branch',
      () async {
        final dataSource = MockAccessDataSource();
        final repository = MockOrganizationMembersRepository(
          accessDataSource: dataSource,
        );
        final manager = await _accessFor(
          dataSource,
          id: 'user-bm-multi-01',
          name: 'Marcus Chen',
          role: UserRole.branchManager,
        );

        final branchEmployees = await repository.getMembers(
          access: manager,
          activeBranchId: 'br-01',
        );
        expect(
          branchEmployees.map((member) => member.fullName),
          contains('Sarah Connor'),
        );
        expect(
          branchEmployees.map((member) => member.fullName),
          isNot(contains('Priya Shah')),
        );
        expect(
          branchEmployees.every((member) => member.role == UserRole.employee),
          isTrue,
        );
        await expectLater(
          repository.getMembers(access: manager, activeBranchId: 'br-04'),
          throwsA(isA<StateError>()),
        );

        final saved = await repository.saveMember(
          access: manager,
          activeBranchId: 'br-01',
          initialPassword: 'Temporary!123',
          member: _member(id: '', branchIds: const ['br-01']),
        );
        expect(saved.branchIds, ['br-01']);
        expect(dataSource.getAssignedBranchIds(saved.id), ['br-01']);
        await expectLater(
          repository.saveMember(
            access: manager,
            activeBranchId: 'br-01',
            initialPassword: '',
            member: OrganizationMember(
              id: 'user-bm-single-01',
              organizationId: 'org-acme',
              fullName: 'Sophia Patel',
              username: 'sophia.patel',
              email: 'sophia.patel@example.com',
              role: UserRole.employee,
              branchIds: const ['br-01'],
              status: AccountStatus.active,
            ),
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'organization admin may create a branch manager within the organization',
      () async {
        final dataSource = MockAccessDataSource();
        final repository = MockOrganizationMembersRepository(
          accessDataSource: dataSource,
        );
        final orgAdmin = await _accessFor(
          dataSource,
          id: 'user-oa-01',
          name: 'Jordan Lee',
          role: UserRole.orgAdmin,
        );

        final manager = await repository.saveMember(
          access: orgAdmin,
          initialPassword: 'Temporary!123',
          member: _member(
            id: '',
            role: UserRole.branchManager,
            branchIds: const ['br-01', 'br-02'],
          ),
        );

        expect(dataSource.getAssignedBranchIds(manager.id), ['br-01', 'br-02']);
        expect(
          dataSource
              .getUsersWithRole(UserRole.branchManager, 'org-acme')
              .map((user) => user.id),
          contains(manager.id),
        );
      },
    );
  });

  group('Mock attendance scope and exception review', () {
    test(
      'employee history is self-only and branch manager review is branch-only',
      () async {
        final dataSource = MockAccessDataSource();
        final repository = MockAttendanceRepository();
        final employee = await _accessFor(
          dataSource,
          id: 'user-emp-01',
          name: 'Sarah Connor',
          role: UserRole.employee,
        );
        final today = DateTime.now();
        final mine = await repository.getAttendance(
          access: employee,
          date: today,
        );
        expect(mine, hasLength(1));
        expect(mine.single.employeeId, 'user-emp-01');
        await expectLater(
          repository.getAttendance(
            access: employee,
            date: today,
            employeeId: 'user-emp-02',
          ),
          throwsA(isA<StateError>()),
        );

        final manager = await _accessFor(
          dataSource,
          id: 'user-bm-multi-01',
          name: 'Marcus Chen',
          role: UserRole.branchManager,
        );
        final branchEntries = await repository.getAttendance(
          access: manager,
          date: today,
          activeBranchId: 'br-01',
        );
        expect(
          branchEntries.every((entry) => entry.branchId == 'br-01'),
          isTrue,
        );
        await expectLater(
          repository.getAttendance(
            access: manager,
            date: today,
            activeBranchId: 'br-04',
          ),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          repository.reviewException(
            access: manager,
            entryId: 'att-04',
            activeBranchId: 'br-01',
            decision: AttendanceReviewDecision.verify,
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('organization admin can verify an exception', () async {
      final dataSource = MockAccessDataSource();
      final repository = MockAttendanceRepository();
      final orgAdmin = await _accessFor(
        dataSource,
        id: 'user-oa-01',
        name: 'Jordan Lee',
        role: UserRole.orgAdmin,
      );

      final updated = await repository.reviewException(
        access: orgAdmin,
        entryId: 'att-02',
        activeBranchId: 'br-01',
        decision: AttendanceReviewDecision.verify,
      );
      expect(updated.reviewStatus, AttendanceReviewStatus.verified);
    });
  });
}

Future<UserAccessContext> _accessFor(
  MockAccessDataSource dataSource, {
  required String id,
  required String name,
  required UserRole role,
}) => MockAccessRepository(dataSource: dataSource, delay: Duration.zero)
    .resolveCurrentUserAccess(
      AppUser(
        id: id,
        name: name,
        username: name.toLowerCase().replaceAll(' ', '.'),
        role: role,
        organizationId: 'org-acme',
      ),
    );

BranchRecord _branch({
  required String id,
  List<String> managerIds = const [],
}) => BranchRecord(
  summary: BranchSummary(
    id: id,
    organizationId: 'org-acme',
    name: 'New Training Center',
    code: '',
    location: 'Midtown',
    isActive: true,
  ),
  geofenceRadiusMeters: 210,
  latitude: 40.75,
  longitude: -73.99,
  managerIds: managerIds,
  kioskStatus: KioskPairingStatus.notPaired,
);

OrganizationMember _member({
  required String id,
  UserRole role = UserRole.employee,
  required List<String> branchIds,
}) => OrganizationMember(
  id: id,
  organizationId: 'org-acme',
  fullName: 'Taylor Morgan',
  username: 'taylor.morgan',
  email: 'taylor.morgan@example.com',
  role: role,
  branchIds: branchIds,
  status: AccountStatus.active,
);
