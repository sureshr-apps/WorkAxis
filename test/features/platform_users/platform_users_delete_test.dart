import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/data/mock_platform_users_repository.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/domain/platform_administrator_validator.dart';
import 'package:workaxis/features/platform_users/presentation/controllers/platform_users_controller.dart';

class _FailingDeleteRepository extends MockPlatformUsersRepository {
  @override
  Future<void> deleteAdministrator(String id) =>
      Future.error(StateError('backend unavailable'));
}

PlatformAdministrator _draft({String? phone = '+15550003'}) =>
    PlatformAdministrator(
      id: '',
      fullName: 'Jordan Kim',
      username: 'jkim',
      email: 'j.kim@workaxis.example',
      phone: phone,
      status: AccountStatus.active,
      createdAt: DateTime(2026, 10, 17),
    );

void main() {
  group('deleting a platform administrator', () {
    test('the mock repository removes the administrator', () async {
      final repository = MockPlatformUsersRepository();
      final before = await repository.countAdministrators();
      final target = (await repository.getAdministratorsPage()).items.first;

      await repository.deleteAdministrator(target.id);

      expect(await repository.getAdministratorById(target.id), isNull);
      expect(await repository.countAdministrators(), before - 1);
    });

    test('the controller drops the row and updates the counts', () async {
      final controller = PlatformUsersController(
        repository: MockPlatformUsersRepository(),
      );
      addTearDown(controller.dispose);
      await controller.loadAdministrators();
      final target = controller.administrators.first;
      final total = controller.totalCount;

      expect(await controller.deleteAdministrator(target.id), isTrue);

      expect(controller.administrators.any((a) => a.id == target.id), isFalse);
      expect(controller.totalCount, total - 1);
      expect(controller.actionErrorMessage, isNull);
    });

    test(
      'a failed delete keeps the administrator and reports the error',
      () async {
        final controller = PlatformUsersController(
          repository: _FailingDeleteRepository(),
        );
        addTearDown(controller.dispose);
        await controller.loadAdministrators();
        final target = controller.administrators.first;

        expect(await controller.deleteAdministrator(target.id), isFalse);

        expect(controller.administrators.any((a) => a.id == target.id), isTrue);
        expect(controller.actionErrorMessage, isNotNull);
      },
    );
  });

  group('platform administrator phone is required', () {
    test('create and edit reject a missing or blank phone', () {
      expect(
        () => PlatformAdministratorValidator.prepare(
          _draft(phone: null),
          isCreate: true,
          initialPassword: 'WorkAxis!2026',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => PlatformAdministratorValidator.prepare(
          _draft(phone: '   '),
          isCreate: false,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('a valid phone is normalized and accepted on edit', () {
      final prepared = PlatformAdministratorValidator.prepare(
        _draft(phone: '+1 (202) 555-0137'),
        isCreate: false,
      );
      expect(prepared.phone, '+12025550137');
    });
  });
}
