import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/plans/domain/license_plan_policy.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';

CreateLicensePlanDraft _create({
  String name = 'Professional',
  String description = '',
  int level = 2,
  int maxStores = 5,
  int maxUsers = 25,
}) => CreateLicensePlanDraft(
  name: name,
  description: description,
  level: level,
  maxStores: maxStores,
  maxUsers: maxUsers,
);

UpdateLicensePlanDraft _update({
  String name = 'Professional',
  String description = '',
  int level = 2,
  int maxStores = 5,
  int maxUsers = 25,
}) => UpdateLicensePlanDraft(
  name: name,
  description: description,
  level: level,
  maxStores: maxStores,
  maxUsers: maxUsers,
);

void main() {
  group('LicensePlanPolicy on add', () {
    test('a complete draft has no errors', () {
      expect(LicensePlanPolicy.validate(_create()), isEmpty);
    });

    test('blank or whitespace-only name is required', () {
      for (final name in ['', '   ']) {
        expect(LicensePlanPolicy.validate(_create(name: name)), {
          LicensePlanField.name: 'Plan Name is required.',
        }, reason: 'name "$name"');
      }
    });

    test('level must be a positive whole number', () {
      expect(LicensePlanPolicy.validate(_create(level: 0)), {
        LicensePlanField.level: 'Plan Level must be a positive whole number.',
      });
      expect(
        LicensePlanPolicy.validate(_create(level: -3)),
        contains(LicensePlanField.level),
      );
      expect(LicensePlanPolicy.validate(_create(level: 1)), isEmpty);
    });

    test('maximum stores must be at least 1', () {
      expect(LicensePlanPolicy.validate(_create(maxStores: 0)), {
        LicensePlanField.maxStores:
            'Maximum Stores must be a positive whole number.',
      });
      expect(LicensePlanPolicy.validate(_create(maxStores: 1)), isEmpty);
    });

    test('maximum users must be at least 1', () {
      expect(LicensePlanPolicy.validate(_create(maxUsers: 0)), {
        LicensePlanField.maxUsers:
            'Maximum Users must be a positive whole number.',
      });
      expect(LicensePlanPolicy.validate(_create(maxUsers: 1)), isEmpty);
    });

    test('description may be empty and is limited to 200 characters', () {
      expect(LicensePlanPolicy.validate(_create(description: '')), isEmpty);
      expect(
        LicensePlanPolicy.validate(_create(description: 'a' * 200)),
        isEmpty,
      );
      expect(LicensePlanPolicy.validate(_create(description: 'a' * 201)), {
        LicensePlanField.description:
            'Description must be at most 200 characters.',
      });
    });

    test('description length is measured after trimming', () {
      expect(
        LicensePlanPolicy.validate(_create(description: '  ${'a' * 200}  ')),
        isEmpty,
      );
    });

    test('reports every invalid field at once', () {
      final errors = LicensePlanPolicy.validate(
        _create(name: ' ', level: 0, maxStores: 0, maxUsers: 0),
      );
      expect(
        errors.keys,
        unorderedEquals([
          LicensePlanField.name,
          LicensePlanField.level,
          LicensePlanField.maxStores,
          LicensePlanField.maxUsers,
        ]),
      );
    });
  });

  group('LicensePlanPolicy on edit', () {
    test('applies the same rules to an update draft', () {
      expect(LicensePlanPolicy.validate(_update()), isEmpty);
      expect(LicensePlanPolicy.validate(_update(name: '')), {
        LicensePlanField.name: 'Plan Name is required.',
      });
      expect(
        LicensePlanPolicy.validate(_update(level: 0)),
        contains(LicensePlanField.level),
      );
      expect(
        LicensePlanPolicy.validate(_update(maxStores: 0)),
        contains(LicensePlanField.maxStores),
      );
      expect(
        LicensePlanPolicy.validate(_update(maxUsers: 0)),
        contains(LicensePlanField.maxUsers),
      );
      expect(
        LicensePlanPolicy.validate(_update(description: 'a' * 201)),
        contains(LicensePlanField.description),
      );
    });
  });

  group('LicensePlanPolicy.ensureValid', () {
    test('throws a user-safe validation exception for the first problem', () {
      expect(
        () => LicensePlanPolicy.ensureValid(_update(maxUsers: 0)),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.userMessage,
            'userMessage',
            LicensePlanPolicy.maxUsersMessage,
          ),
        ),
      );
    });

    test('passes a valid draft silently', () {
      expect(() => LicensePlanPolicy.ensureValid(_create()), returnsNormally);
    });
  });

  group('PlanStatus', () {
    test(
      'parses active case-insensitively and treats anything else as inactive',
      () {
        expect(PlanStatus.fromString('active'), PlanStatus.active);
        expect(PlanStatus.fromString(' ACTIVE '), PlanStatus.active);
        expect(PlanStatus.fromString('inactive'), PlanStatus.inactive);
        expect(PlanStatus.fromString('retired'), PlanStatus.inactive);
        expect(PlanStatus.fromString(null), PlanStatus.inactive);
      },
    );
  });
}
