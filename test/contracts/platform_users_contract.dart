import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/domain/repositories/platform_users_repository.dart';

const _password = 'Str0ng-Pass!';

PlatformAdministrator adminDraft({
  String username = 'new.admin',
  String fullName = 'New Admin',
  String email = '',
  String? phone,
}) => PlatformAdministrator(
  id: '',
  fullName: fullName,
  username: username,
  email: email,
  phone: phone,
  status: AccountStatus.active,
  createdAt: DateTime(2026, 1, 1),
);

/// Behaviour every [PlatformUsersRepository] must provide. The fixture has
/// four administrators: three active and one suspended (Devendra Patel).
void runPlatformUsersContract(
  String label,
  PlatformUsersRepository Function() create,
) {
  group('PlatformUsersRepository contract ($label)', () {
    late PlatformUsersRepository repo;
    setUp(() => repo = create());

    test('pages through every administrator once', () async {
      final seen = <String>[];
      var offset = 0;
      while (true) {
        final page = await repo.getAdministratorsPage(limit: 3, offset: offset);
        expect(page.total, 4);
        seen.addAll(page.items.map((a) => a.id));
        if (!page.hasMore) break;
        offset = page.nextOffset;
      }
      expect(seen.toSet().length, 4);
      expect(seen.length, 4);
    });

    test('filters by status and name and counts by status', () async {
      final suspended = await repo.getAdministratorsPage(
        status: AccountStatus.suspended,
      );
      expect(suspended.items.single.fullName, 'Devendra Patel');
      final byName = await repo.getAdministratorsPage(query: 'elena');
      expect(byName.items.single.fullName, 'Elena Lindqvist');
      expect(await repo.countAdministrators(), 4);
      expect(await repo.countAdministrators(status: AccountStatus.active), 3);
      expect(
        await repo.countAdministrators(status: AccountStatus.suspended),
        1,
      );
    });

    test('create returns the saved account with a server id', () async {
      final created = await repo.createAdministrator(
        administrator: adminDraft(
          username: ' New.Admin ',
          email: 'new@workaxis.example',
          phone: '+1 (202) 555-0137',
        ),
        initialPassword: _password,
      );
      expect(created.id, isNotEmpty);
      expect(created.username, 'new.admin');
      expect(created.status, AccountStatus.active);
      expect(created.phone, '+12025550137');
      expect(await repo.getAdministratorById(created.id), isNotNull);
      expect(await repo.countAdministrators(), 5);
    });

    test('create validates username, password, email and phone', () async {
      Future<void> rejected(
        PlatformAdministrator draft, [
        String pw = _password,
      ]) => expectLater(
        repo.createAdministrator(administrator: draft, initialPassword: pw),
        throwsA(isA<ValidationException>()),
      );
      await rejected(adminDraft(username: 'a'));
      await rejected(adminDraft(), 'short');
      await rejected(adminDraft(email: 'nope'));
      await rejected(adminDraft(phone: '12345'));
      await rejected(adminDraft(fullName: '  '));
    });

    test('rejects a duplicate username', () async {
      await expectLater(
        repo.createAdministrator(
          administrator: adminDraft(username: 'dwarner'),
          initialPassword: _password,
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('update changes details but never the username', () async {
      final existing = (await repo.getAdministratorsPage(query: 'marcus'))
          .items
          .single;
      final updated = await repo.updateAdministrator(
        existing.copyWith(fullName: 'Marcus S.', username: 'hijacked'),
      );
      expect(updated.fullName, 'Marcus S.');
      expect(updated.username, existing.username);
    });

    test('suspends and restores', () async {
      final target = (await repo.getAdministratorsPage(query: 'david'))
          .items
          .single;
      final suspended = await repo.updateAdministratorStatus(
        target.id,
        AccountStatus.suspended,
      );
      expect(suspended.status, AccountStatus.suspended);
      expect(
        await repo.countAdministrators(status: AccountStatus.suspended),
        2,
      );
      final restored = await repo.updateAdministratorStatus(
        target.id,
        AccountStatus.active,
      );
      expect(restored.status, AccountStatus.active);
    });

    test('password reset validates the new password', () async {
      final target = (await repo.getAdministratorsPage(query: 'david'))
          .items
          .single;
      await repo.resetAdministratorPassword(
        id: target.id,
        newPassword: _password,
      );
      await expectLater(
        repo.resetAdministratorPassword(id: target.id, newPassword: 'short'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('unknown administrators are reported as missing', () async {
      expect(await repo.getAdministratorById('nope'), isNull);
    });
  });
}
