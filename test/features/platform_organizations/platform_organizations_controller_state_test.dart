import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/platform_organizations/data/mock_platform_organizations_repository.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/presentation/controllers/platform_organizations_controller.dart';

class _ControllableDetailRepository
    extends MockPlatformOrganizationsRepository {
  bool failDetail = false;
  final Map<String, Completer<void>> gates = {};

  @override
  Future<CustomerOrganization?> getOrganizationById(String id) async {
    await gates[id]?.future;
    if (failDetail) throw StateError('db host=10.0.0.5 exploded');
    return super.getOrganizationById(id);
  }
}

void main() {
  late _ControllableDetailRepository repository;
  late PlatformOrganizationsController controller;

  setUp(() {
    repository = _ControllableDetailRepository();
    controller = PlatformOrganizationsController(repository: repository);
  });

  tearDown(() => controller.dispose());

  test(
    'a failing detail load does not put the list into an error state',
    () async {
      await controller.loadOrganizations();
      final listCount = controller.organizations.length;
      expect(listCount, greaterThan(0));

      repository.failDetail = true;
      final org = await controller.loadOrganizationDetails('org-acme');

      expect(org, isNull);
      expect(controller.listErrorMessage, isNull);
      expect(controller.detailErrorMessage, isNotNull);
      expect(controller.detailErrorMessage, isNot(contains('10.0.0.5')));
      expect(controller.isListLoading, isFalse);
      expect(controller.isDetailLoading, isFalse);
      expect(controller.organizations, hasLength(listCount));
    },
  );

  test('a slow detail response cannot replace a newer selection', () async {
    await controller.loadOrganizations();
    final slow = Completer<void>();
    repository.gates['org-acme'] = slow;
    final all = controller.organizations;
    final other = all.firstWhere((o) => o.id != 'org-acme');

    final first = controller.loadOrganizationDetails('org-acme');
    await controller.loadOrganizationDetails(other.id);
    slow.complete();
    await first;

    expect(controller.selectedOrganization?.id, other.id);
  });

  test('reset clears loaded data and invalidates in-flight loads', () async {
    final slow = Completer<void>();
    repository.gates['org-acme'] = slow;

    final pending = controller.loadOrganizationDetails('org-acme');
    controller.reset();
    slow.complete();
    await pending;

    expect(controller.selectedOrganization, isNull);
    expect(controller.isDetailLoading, isFalse);
    expect(controller.organizations, isEmpty);
  });

  test('legacy combined flags still reflect either load', () async {
    final slow = Completer<void>();
    repository.gates['org-acme'] = slow;

    final pending = controller.loadOrganizationDetails('org-acme');
    expect(controller.isLoading, isTrue);
    expect(controller.isListLoading, isFalse);

    slow.complete();
    await pending;
    expect(controller.isLoading, isFalse);
  });
}
