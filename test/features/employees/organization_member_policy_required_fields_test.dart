import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/member_field.dart';
import 'package:workaxis/features/employees/domain/policies/member_form_values.dart';
import 'package:workaxis/features/employees/domain/policies/organization_member_policy.dart';

MemberFormValues _complete({UserRole role = UserRole.employee}) =>
    MemberFormValues(
      role: role,
      fullName: 'Jane Employee',
      username: 'jane.employee',
      password: 'Password123!',
      aadhaarNumber: '1234 5678 9012',
      aadhaarPhotoPath: '/tmp/aadhaar.jpg',
      designation: 'Cashier',
      salaryText: '25000',
      workHoursText: '8',
      shiftHours: '09:00 AM - 05:00 PM',
      branchIds: const {'br-01'},
    );

Map<MemberField, String> _validate(
  MemberFormValues values, {
  bool isCreation = true,
  bool manager = false,
  String? activeBranchId = 'br-01',
}) => OrganizationMemberPolicy.validateForSave(
  values: values,
  isCreation: isCreation,
  actorIsBranchManager: manager,
  activeBranchId: activeBranchId,
);

void main() {
  group('requiredFields', () {
    test('employee creation requires identity, KYC and compensation', () {
      expect(
        OrganizationMemberPolicy.requiredFields(
          role: UserRole.employee,
          isCreation: true,
        ),
        {
          MemberField.fullName,
          MemberField.username,
          MemberField.password,
          MemberField.aadhaarNumber,
          MemberField.aadhaarPhoto,
          MemberField.designation,
          MemberField.salary,
          MemberField.dailyWorkHours,
          MemberField.shiftHours,
          MemberField.branches,
        },
      );
    });

    test('employee edit drops creation-only and private-HR requirements', () {
      expect(
        OrganizationMemberPolicy.requiredFields(
          role: UserRole.employee,
          isCreation: false,
        ),
        {
          MemberField.fullName,
          MemberField.dailyWorkHours,
          MemberField.shiftHours,
          MemberField.branches,
        },
      );
    });

    test('branch manager creation is not asked for employee KYC', () {
      final required = OrganizationMemberPolicy.requiredFields(
        role: UserRole.branchManager,
        isCreation: true,
      );
      expect(required, contains(MemberField.username));
      expect(required, contains(MemberField.branches));
      expect(required, isNot(contains(MemberField.aadhaarNumber)));
      expect(required, isNot(contains(MemberField.salary)));
    });

    test('organization admin needs no branches', () {
      final required = OrganizationMemberPolicy.requiredFields(
        role: UserRole.orgAdmin,
        isCreation: true,
      );
      expect(required, isNot(contains(MemberField.branches)));
      expect(required, isNot(contains(MemberField.designation)));
    });

    test('mobile number and profile photo are never required', () {
      for (final role in [
        UserRole.orgAdmin,
        UserRole.branchManager,
        UserRole.employee,
      ]) {
        for (final creating in [true, false]) {
          final required = OrganizationMemberPolicy.requiredFields(
            role: role,
            isCreation: creating,
          );
          expect(required, isNot(contains(MemberField.phone)));
          expect(required, isNot(contains(MemberField.profilePhoto)));
        }
      }
    });
  });

  group('validateForSave', () {
    test('a complete employee is valid', () {
      expect(_validate(_complete()), isEmpty);
    });

    test('every required employee-creation field reports its own error', () {
      const blank = MemberFormValues(
        role: UserRole.employee,
        workHoursText: '8',
        shiftHours: '09:00 AM - 05:00 PM',
        branchIds: {'br-01'},
      );
      expect(_validate(blank).keys, [
        MemberField.fullName,
        MemberField.username,
        MemberField.password,
        MemberField.aadhaarNumber,
        MemberField.aadhaarPhoto,
        MemberField.designation,
        MemberField.salary,
      ]);
    });

    test('errors come back in form order so the first one can be revealed', () {
      final errors = _validate(
        MemberFormValues(
          role: UserRole.employee,
          fullName: 'A',
          username: 'jane.employee',
          password: 'Password123!',
          workHoursText: '99',
          shiftHours: '09:00 AM - 05:00 PM',
          branchIds: const {'br-01'},
        ),
      );
      expect(errors.keys.first, MemberField.aadhaarNumber);
      expect(errors.keys.last, MemberField.dailyWorkHours);
    });

    test('editing an employee does not demand creation-only fields', () {
      final errors = _validate(
        MemberFormValues(
          role: UserRole.employee,
          fullName: 'Jane',
          workHoursText: '8',
          shiftHours: '09:00 AM - 05:00 PM',
          branchIds: const {'br-01'},
        ),
        isCreation: false,
      );
      expect(errors, isEmpty);
    });

    test('malformed optional values are still rejected on edit', () {
      final errors = _validate(
        MemberFormValues(
          role: UserRole.employee,
          fullName: 'Jane',
          aadhaarNumber: '12345',
          salaryText: '-5',
          email: 'nope',
          phone: '12',
          workHoursText: '8',
          shiftHours: '09:00 AM - 05:00 PM',
          branchIds: const {'br-01'},
        ),
        isCreation: false,
      );
      expect(errors.keys, [
        MemberField.phone,
        MemberField.email,
        MemberField.aadhaarNumber,
        MemberField.salary,
      ]);
    });

    test('an empty mobile number is accepted', () {
      expect(_validate(_complete()), isNot(contains(MemberField.phone)));
    });

    test('branch rules differ by actor and role', () {
      expect(
        _validate(
          MemberFormValues(
            role: UserRole.branchManager,
            fullName: 'Bea',
            username: 'bea.manager',
            password: 'Password123!',
            workHoursText: '8',
            shiftHours: '09:00 AM - 05:00 PM',
          ),
        ).keys,
        [MemberField.branches],
      );
      expect(
        _validate(
          MemberFormValues(
            role: UserRole.orgAdmin,
            fullName: 'Ola',
            username: 'ola.admin',
            password: 'Password123!',
            workHoursText: '8',
            shiftHours: '09:00 AM - 05:00 PM',
          ),
        ),
        isEmpty,
      );
      final managerNoBranch = _validate(
        _complete().copyOnlyBranches(const {}),
        manager: true,
        activeBranchId: null,
      );
      expect(managerNoBranch[MemberField.branches], contains('active branch'));
    });

    test('a branch manager always saves as employee', () {
      expect(
        _validate(_complete(role: UserRole.branchManager), manager: true),
        isEmpty,
        reason: 'the form role is ignored for a manager actor',
      );
    });

    test('platform roles cannot be created inside an organization', () {
      final errors = _validate(_complete(role: UserRole.platformAdmin));
      expect(errors[MemberField.role], isNotNull);
    });
  });
}

extension on MemberFormValues {
  MemberFormValues copyOnlyBranches(Set<String> branches) => MemberFormValues(
    role: role,
    fullName: fullName,
    username: username,
    password: password,
    aadhaarNumber: aadhaarNumber,
    aadhaarPhotoPath: aadhaarPhotoPath,
    designation: designation,
    salaryText: salaryText,
    workHoursText: workHoursText,
    shiftHours: shiftHours,
    branchIds: branches,
  );
}
