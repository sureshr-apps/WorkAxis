import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access_control/data/datasources/firestore_access_data_source.dart';
import 'package:workaxis/features/access_control/domain/entities/app_user.dart';
import 'package:workaxis/features/access_control/domain/entities/user_role.dart';

void main() {
  group('FirestoreAccessDataSource Contracts & Mapping', () {
    test('UserRole parsing correctly maps role strings', () {
      expect(UserRole.fromString('orgAdmin'), UserRole.orgAdmin);
      expect(UserRole.fromString('admin'), UserRole.orgAdmin);
      expect(UserRole.fromString('organization admin'), UserRole.orgAdmin);

      expect(UserRole.fromString('branchManager'), UserRole.branchManager);
      expect(UserRole.fromString('manager'), UserRole.branchManager);
      expect(UserRole.fromString('branch manager'), UserRole.branchManager);

      expect(UserRole.fromString('employee'), UserRole.employee);
      expect(UserRole.fromString('staff'), UserRole.employee);
      expect(UserRole.fromString('unknown'), UserRole.employee);
    });

    test('AccountStatus correctly evaluates active vs disabled', () {
      const activeUser = AppUser(
        id: 'usr_01',
        phoneNumber: '+15551234567',
        status: AccountStatus.active,
      );
      expect(activeUser.isActive, isTrue);
      expect(activeUser.isDisabled, isFalse);

      const disabledUser = AppUser(
        id: 'usr_02',
        phoneNumber: '+15554567890',
        status: AccountStatus.disabled,
      );
      expect(disabledUser.isActive, isFalse);
      expect(disabledUser.isDisabled, isTrue);
    });

    test('FirestoreAccessDataSource instance initializes properly', () {
      final dataSource = FirestoreAccessDataSource();
      expect(dataSource, isNotNull);
    });
  });
}
