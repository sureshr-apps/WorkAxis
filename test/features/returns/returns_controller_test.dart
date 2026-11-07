import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/domain/repositories/returns_repository.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';

import '../../helpers/fixed_clock.dart';
import '../../helpers/session_fakes.dart';

class _ConstListReturnsRepository implements ReturnsRepository {
  bool failSubmit = false;

  @override
  Future<List<ReturnItem>> getReturns({
    required UserAccessContext access,
    String? activeBranchId,
    ReturnStatus? statusFilter,
  }) async => const [];

  @override
  Future<ReturnItem> submitReturn({
    required UserAccessContext access,
    String? branchId,
    required CreateReturnInput input,
  }) async {
    if (failSubmit) throw StateError('nope');
    return _item('created', ReturnStatus.pending);
  }

  @override
  Future<ReturnItem> reviewReturn({
    required UserAccessContext access,
    String? activeBranchId,
    required ReturnItem returnItem,
    required ReturnStatus decision,
    String? reviewerNotes,
  }) async => _item(returnItem.id, decision);
}

ReturnItem _item(String id, ReturnStatus status) => ReturnItem(
  id: id,
  organizationId: 'org-test',
  branchId: 'br-1',
  branchName: 'Branch 1',
  employeeId: 'emp-1',
  employeeName: 'Emp',
  productTitle: 'Milk',
  reason: ReturnReason.damaged,
  quantity: 1,
  unit: 'pcs',
  invoiceNumber: 'INV-1',
  returnDate: testNow,
  status: status,
);

void main() {
  final access = UserAccessContext(user: testUser(UserRole.employee));
  const input = CreateReturnInput(
    productTitle: 'Milk',
    reason: ReturnReason.damaged,
    quantity: 1,
    unit: 'pcs',
    invoiceNumber: 'INV-1',
  );

  late _ConstListReturnsRepository repository;
  late ReturnsController controller;

  setUp(() {
    repository = _ConstListReturnsRepository();
    controller = ReturnsController(repository: repository);
  });

  tearDown(() => controller.dispose());

  test(
    'submit succeeds when the repository returned a const empty list',
    () async {
      await controller.loadReturns(access: access);
      expect(controller.items, isEmpty);

      final ok = await controller.submitReturn(access: access, input: input);

      expect(ok, isTrue);
      expect(controller.items.single.id, 'created');
      expect(controller.actionErrorMessage, isNull);
    },
  );

  test('submit also works before any load (initial const list)', () async {
    final ok = await controller.submitReturn(access: access, input: input);

    expect(ok, isTrue);
    expect(controller.items, hasLength(1));
  });

  test('review replaces the item without mutating the list', () async {
    await controller.loadReturns(access: access);
    await controller.submitReturn(access: access, input: input);

    final ok = await controller.reviewReturn(
      access: access,
      item: controller.items.single,
      decision: ReturnStatus.approved,
      reviewerNotes: 'ok',
    );

    expect(ok, isTrue);
    expect(controller.items.single.status, ReturnStatus.approved);
  });

  test(
    'action failures do not replace the loaded list with an error state',
    () async {
      await controller.loadReturns(access: access);
      repository.failSubmit = true;

      final ok = await controller.submitReturn(access: access, input: input);

      expect(ok, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.actionErrorMessage, isNotNull);
      expect(controller.actionErrorMessage, isNot(contains('nope')));
      controller.clearActionError();
      expect(controller.actionErrorMessage, isNull);
    },
  );

  test('reset clears items, filters and errors', () async {
    await controller.submitReturn(access: access, input: input);
    controller.setSearchQuery('milk');
    controller.setFilter(ReturnStatus.pending);

    controller.reset();

    expect(controller.items, isEmpty);
    expect(controller.searchQuery, isEmpty);
    expect(controller.statusFilter, isNull);
  });
}
