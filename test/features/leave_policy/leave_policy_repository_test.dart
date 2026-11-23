import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/leave_policy/data/mock_leave_policy_repository.dart';
import 'package:workaxis/features/leave_policy/data/sql_connect_leave_policy_repository.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_input.dart';

import '../../helpers/access_fixtures.dart';
import '../../helpers/fake_data_gateway.dart';

Map<String, dynamic> _type(
  String id,
  String name, {
  bool paid = true,
  num yearlyDays = 0,
  bool carryForward = false,
}) => {
  'id': id,
  'name': name,
  'paid': paid,
  'yearlyDays': yearlyDays,
  'carryForward': carryForward,
};

void main() {
  group('SqlConnectLeavePolicyRepository', () {
    late FakeDataGateway gateway;
    late SqlConnectLeavePolicyRepository repository;

    setUp(() {
      gateway = FakeDataGateway();
      repository = SqlConnectLeavePolicyRepository(gateway: gateway);
    });

    test('getLeavePolicy parses accrual and types in order', () async {
      gateway.respond('GetLeavePolicy', {
        'leavePolicy': {
          'monthlyAccrual': true,
          'leaveTypes': [
            _type('a', 'Annual leave', yearlyDays: 12, carryForward: true),
            _type('c', 'Study leave', yearlyDays: 1.5),
            _type('u', 'Unpaid leave', paid: false),
          ],
        },
      });

      final policy = await repository.getLeavePolicy(access: orgAdminAccess());

      expect(gateway.singleVarsOf('GetLeavePolicy'), isEmpty);
      expect(policy.monthlyAccrual, isTrue);
      expect(policy.leaveTypes.map((t) => t.id), ['a', 'c', 'u']);
      final annual = policy.leaveTypes.first;
      expect(annual.name, 'Annual leave');
      expect(annual.yearlyDays, 12);
      expect(annual.carryForward, isTrue);
      expect(policy.leaveTypes[1].yearlyDays, 1.5);
      expect(policy.leaveTypes.last.paid, isFalse);
      expect(policy.leaveTypes.last.canBeRemoved, isFalse);
    });

    test('malformed response surfaces as DatabaseException', () async {
      gateway.respond('GetLeavePolicy', {
        'leavePolicy': {'leaveTypes': []},
      });
      await expectLater(
        repository.getLeavePolicy(access: orgAdminAccess()),
        throwsA(isA<DatabaseException>()),
      );
    });

    test(
      'saveLeaveType creates without id and sends whole days as int',
      () async {
        gateway.respond('SaveLeaveType', {
          'leaveType': _type('n', 'Study leave', yearlyDays: 3),
        });

        final saved = await repository.saveLeaveType(
          access: orgAdminAccess(),
          input: const LeaveTypeInput(
            name: '  Study leave ',
            yearlyDays: 3,
            carryForward: false,
          ),
        );

        final vars = gateway.singleVarsOf('SaveLeaveType');
        expect(vars, {
          'name': 'Study leave',
          'yearlyDays': 3,
          'carryForward': false,
        });
        expect(vars['yearlyDays'], isA<int>());
        expect(saved.id, 'n');
        expect(saved.yearlyDays, 3);
      },
    );

    test('saveLeaveType updates with id and fractional days', () async {
      gateway.respond('SaveLeaveType', {
        'leaveType': _type('a', 'Annual', yearlyDays: 12.5, carryForward: true),
      });

      await repository.saveLeaveType(
        access: orgAdminAccess(),
        input: const LeaveTypeInput(
          id: 'a',
          name: 'Annual',
          yearlyDays: 12.5,
          carryForward: true,
        ),
      );

      expect(gateway.singleVarsOf('SaveLeaveType'), {
        'id': 'a',
        'name': 'Annual',
        'yearlyDays': 12.5,
        'carryForward': true,
      });
    });

    test('saveLeaveType rejects invalid input before calling', () async {
      await expectLater(
        repository.saveLeaveType(
          access: orgAdminAccess(),
          input: const LeaveTypeInput(
            name: 'Annual',
            yearlyDays: 1.234,
            carryForward: false,
          ),
        ),
        throwsA(
          isA<DatabaseException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Use at most two decimal places.',
          ),
        ),
      );
      expect(gateway.calls, isEmpty);
    });

    test('archive and accrual send the documented variables', () async {
      gateway
        ..respond('ArchiveLeaveType', {
          'leaveType': {'id': 's'},
        })
        ..respond('SetLeaveAccrual', {
          'leavePolicy': {'monthlyAccrual': true},
        });

      await repository.archiveLeaveType(
        access: orgAdminAccess(),
        leaveTypeId: 's',
      );
      final accrual = await repository.setMonthlyAccrual(
        access: orgAdminAccess(),
        monthlyAccrual: true,
      );

      expect(gateway.singleVarsOf('ArchiveLeaveType'), {'id': 's'});
      expect(gateway.singleVarsOf('SetLeaveAccrual'), {'monthlyAccrual': true});
      expect(accrual, isTrue);
    });

    test('non Org Admins are denied without a backend call', () async {
      final access = branchManagerAccess();
      await expectLater(
        repository.getLeavePolicy(access: access),
        throwsA(isA<AccessDeniedException>()),
      );
      await expectLater(
        repository.setMonthlyAccrual(access: access, monthlyAccrual: true),
        throwsA(isA<AccessDeniedException>()),
      );
      await expectLater(
        repository.archiveLeaveType(access: access, leaveTypeId: 'a'),
        throwsA(isA<AccessDeniedException>()),
      );
      expect(gateway.calls, isEmpty);
    });
  });

  group('MockLeavePolicyRepository', () {
    late MockLeavePolicyRepository repository;

    setUp(() {
      repository = MockLeavePolicyRepository(delay: Duration.zero);
    });

    test('starts from the built-in types with accrual off', () async {
      final policy = await repository.getLeavePolicy(access: orgAdminAccess());

      expect(policy.monthlyAccrual, isFalse);
      expect(
        policy.leaveTypes.map((t) => (t.name, t.yearlyDays, t.paid)).toList(),
        [
          ('Annual leave', 12.0, true),
          ('Sick leave', 6.0, true),
          ('Personal leave', 2.0, true),
          ('Unpaid leave', 0.0, false),
        ],
      );
    });

    test('creates a type before the unpaid type', () async {
      final access = orgAdminAccess();
      final saved = await repository.saveLeaveType(
        access: access,
        input: const LeaveTypeInput(
          name: 'Study leave',
          yearlyDays: 3,
          carryForward: true,
        ),
      );

      final policy = await repository.getLeavePolicy(access: access);
      expect(saved.paid, isTrue);
      expect(policy.leaveTypes.map((t) => t.name), [
        'Annual leave',
        'Sick leave',
        'Personal leave',
        'Study leave',
        'Unpaid leave',
      ]);
    });

    test('rejects a duplicate active name, ignoring case', () async {
      await expectLater(
        repository.saveLeaveType(
          access: orgAdminAccess(),
          input: const LeaveTypeInput(
            name: ' sick LEAVE ',
            yearlyDays: 1,
            carryForward: false,
          ),
        ),
        throwsA(
          isA<DatabaseException>().having(
            (e) => e.userMessage,
            'userMessage',
            MockLeavePolicyRepository.nameInUse,
          ),
        ),
      );
    });

    test('allows keeping the same name on update', () async {
      final saved = await repository.saveLeaveType(
        access: orgAdminAccess(),
        input: const LeaveTypeInput(
          id: 'lt-sick',
          name: 'Sick leave',
          yearlyDays: 8,
          carryForward: true,
        ),
      );
      expect(saved.yearlyDays, 8);
      expect(saved.carryForward, isTrue);
    });

    test('unpaid type has no allowance but can be renamed', () async {
      final access = orgAdminAccess();
      await expectLater(
        repository.saveLeaveType(
          access: access,
          input: const LeaveTypeInput(
            id: 'lt-unpaid',
            name: 'Unpaid leave',
            yearlyDays: 5,
            carryForward: false,
          ),
        ),
        throwsA(
          isA<DatabaseException>().having(
            (e) => e.userMessage,
            'userMessage',
            MockLeavePolicyRepository.unpaidHasNoAllowance,
          ),
        ),
      );

      final renamed = await repository.saveLeaveType(
        access: access,
        input: const LeaveTypeInput(
          id: 'lt-unpaid',
          name: 'Leave without pay',
          yearlyDays: 0,
          carryForward: false,
        ),
      );
      expect(renamed.name, 'Leave without pay');
      expect(renamed.paid, isFalse);
    });

    test('archives paid types but never the unpaid type', () async {
      final access = orgAdminAccess();
      await repository.archiveLeaveType(
        access: access,
        leaveTypeId: 'lt-personal',
      );
      await expectLater(
        repository.archiveLeaveType(access: access, leaveTypeId: 'lt-unpaid'),
        throwsA(isA<NotFoundException>()),
      );

      final policy = await repository.getLeavePolicy(access: access);
      expect(policy.leaveTypes.map((t) => t.id), [
        'lt-annual',
        'lt-sick',
        'lt-unpaid',
      ]);
    });

    test('archived names can be reused', () async {
      final access = orgAdminAccess();
      await repository.archiveLeaveType(
        access: access,
        leaveTypeId: 'lt-personal',
      );
      final saved = await repository.saveLeaveType(
        access: access,
        input: const LeaveTypeInput(
          name: 'Personal leave',
          yearlyDays: 4,
          carryForward: false,
        ),
      );
      expect(saved.id, isNot('lt-personal'));
    });

    test('accrual is stored per organization', () async {
      await repository.setMonthlyAccrual(
        access: orgAdminAccess(),
        monthlyAccrual: true,
      );

      final own = await repository.getLeavePolicy(access: orgAdminAccess());
      final other = await repository.getLeavePolicy(
        access: orgAdminAccess(org: otherOrg),
      );
      expect(own.monthlyAccrual, isTrue);
      expect(other.monthlyAccrual, isFalse);
    });

    test('other roles are denied', () async {
      await expectLater(
        repository.getLeavePolicy(access: branchManagerAccess()),
        throwsA(isA<AccessDeniedException>()),
      );
    });
  });
}
