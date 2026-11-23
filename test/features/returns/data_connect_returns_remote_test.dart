import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/backend/idempotent_creates.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/returns/data/data_connect_returns_remote.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

import '../../helpers/fake_data_gateway.dart';

Map<String, dynamic> _managedRow({bool withBranch = false}) => {
  'id': 'r1',
  if (withBranch) 'branch': {'id': 'b9', 'name': 'North'},
  'employeeId': 'm1',
  'employeeUid': null,
  'employeeName': 'Ravi',
  'customerName': 'Legacy product',
  'invoiceNumber': 'INV-1',
  'status': 'Pending',
  'returnReason': 'damaged',
  'amount': 3,
  'productTitle': null,
  'quantity': null,
  'unit': null,
  'billImageUrl': null,
  'remarks': 'torn',
  'reviewerNotes': null,
  'reviewerUid': null,
  'reviewerName': null,
  'reviewedAt': null,
  'createdAt': '2026-11-07T09:00:00.000Z',
};

const _branch = BranchSummary(
  id: 'b1',
  organizationId: 'org1',
  name: 'Main',
  code: 'MAIN',
  location: '',
  isActive: true,
);

void main() {
  late FakeDataGateway gateway;
  late DataConnectReturnsRemote remote;

  setUp(() {
    gateway = FakeDataGateway();
    var nextRequest = 0;
    remote = DataConnectReturnsRemote(
      gateway: gateway,
      creates: IdempotentCreates(newRequestId: () => 'req-${++nextRequest}'),
    );
  });

  test('listMine omits status when unset and maps rows', () async {
    gateway.respond('ListMyReturns', {
      'returnRecords': [
        {
          'id': 'r1',
          'branch': {'id': 'b1', 'name': 'Main'},
          'employeeId': 'm1',
          'employeeName': 'Ravi',
          'invoiceNumber': 'INV-7',
          'status': 'approved',
          'returnReason': 'expired',
          'productTitle': null,
          'quantity': 2.5,
          'unit': 'kg',
          'billImageUrl': 'https://x/y.jpg',
          'remarks': null,
          'reviewerNotes': 'ok',
          'reviewerName': 'Asha',
          'reviewedAt': '2026-11-08T10:00:00.000Z',
          'createdAt': '2026-11-07T09:00:00.000Z',
        },
      ],
      'total': [
        {'_count': 1},
      ],
    });

    final items = await remote.listMine(
      organizationId: 'org1',
      employeeUid: 'u1',
      limit: 100,
    );

    expect(gateway.singleVarsOf('ListMyReturns'), {'limit': 100, 'offset': 0});
    final r = items.items.single;
    expect(r.employeeId, 'u1');
    expect(r.productTitle, 'Return INV-7');
    expect(r.reason, ReturnReason.expired);
    expect(r.quantity, 2.5);
    expect(r.status, ReturnStatus.approved);
    expect(r.reviewedAt, DateTime.utc(2026, 11, 8, 10));
    expect(r.reviewedBy, 'Asha');
    expect(r.branchName, 'Main');
  });

  test('listMine sends the status filter', () async {
    gateway.respond('ListMyReturns', {'returnRecords': <dynamic>[]});
    await remote.listMine(
      organizationId: 'org1',
      employeeUid: 'u1',
      limit: 10,
      offset: 20,
      status: ReturnStatus.pending,
    );
    expect(gateway.singleVarsOf('ListMyReturns'), {
      'limit': 10,
      'offset': 20,
      'status': 'pending',
    });
  });

  test('listByBranch applies legacy fallbacks', () async {
    gateway.respond('ListReturnsByBranchPaged', {
      'returnRecords': [_managedRow()],
    });

    final items = await remote.listByBranch(
      organizationId: 'org1',
      branch: _branch,
      limit: 100,
    );

    expect(gateway.singleVarsOf('ListReturnsByBranchPaged'), {
      'branchId': 'b1',
      'limit': 100,
      'offset': 0,
    });
    final r = items.items.single;
    expect(r.productTitle, 'Legacy product');
    expect(r.quantity, 3.0);
    expect(r.employeeId, 'm1');
    expect(r.branchId, 'b1');
    expect(r.status, ReturnStatus.pending);
  });

  test('listByOrganization sends optional filters only when set', () async {
    gateway.respond('ListReturnsByOrgPaged', {
      'returnRecords': [_managedRow(withBranch: true)],
    });

    final items = await remote.listByOrganization(
      organizationId: 'org1',
      limit: 50,
    );
    expect(gateway.varsOf('ListReturnsByOrgPaged').single, {
      'orgId': 'org1',
      'limit': 50,
      'offset': 0,
    });
    expect(items.items.single.branchName, 'North');

    await remote.listByOrganization(
      organizationId: 'org1',
      limit: 50,
      offset: 50,
      branchId: 'b2',
      status: ReturnStatus.rejected,
    );
    expect(gateway.varsOf('ListReturnsByOrgPaged').last, {
      'orgId': 'org1',
      'limit': 50,
      'offset': 50,
      'branchId': 'b2',
      'status': 'rejected',
    });
  });

  test('an unknown status is a DatabaseException', () {
    expect(
      () => DataConnectReturnsRemote.mapBranchReturn(
        {..._managedRow(), 'status': 'mystery'},
        organizationId: 'org1',
        branch: _branch,
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('submitBatch omits blank optionals and returns ids in order', () async {
    gateway.respond('SubmitReturnBatch', {
      'returnRecord_inserts': [
        {'id': 'r-a'},
        {'id': 'r-b'},
      ],
    });

    final ids = await remote.submitBatch(
      branchId: 'b1',
      input: const CreateReturnBatchInput(
        invoiceNumber: 'INV-9',
        billNumber: '  ',
        billImageUrl: '',
        items: [
          ReturnLineItemInput(
            productTitle: 'Milk',
            quantity: 4,
            unit: 'ltr',
            reason: ReturnReason.damaged,
            remarks: '  ',
          ),
          ReturnLineItemInput(
            productTitle: 'Eggs',
            quantity: 12,
            reason: ReturnReason.expired,
          ),
        ],
      ),
    );

    expect(ids, ['r-a', 'r-b']);
    expect(gateway.singleVarsOf('SubmitReturnBatch'), {
      'branchId': 'b1',
      'invoiceNumber': 'INV-9',
      'requestId': 'req-1',
      'items': [
        {
          'productTitle': 'Milk',
          'returnReason': 'damaged',
          'quantity': 4.0,
          'unit': 'ltr',
        },
        {
          'productTitle': 'Eggs',
          'returnReason': 'expired',
          'quantity': 12.0,
          'unit': 'units',
        },
      ],
    });
  });

  test(
    'submitBatch sends bill number, business date, photo and remarks',
    () async {
      gateway.respond('SubmitReturnBatch', {
        'returnRecord_inserts': [
          {'id': 'x'},
        ],
      });
      await remote.submitBatch(
        branchId: 'b1',
        input: CreateReturnBatchInput(
          invoiceNumber: 'INV-9',
          billNumber: ' BILL-7 ',
          returnDate: DateTime(2026, 3, 5),
          billImageUrl: 'https://x/bill.jpg',
          remarks: ' counter ',
          items: const [
            ReturnLineItemInput(
              productTitle: 'Milk',
              quantity: 1,
              reason: ReturnReason.other,
              remarks: ' torn ',
            ),
          ],
        ),
      );
      final vars = gateway.singleVarsOf('SubmitReturnBatch');
      expect(vars['billNumber'], 'BILL-7');
      expect(vars['returnDate'], '2026-03-05');
      expect(vars['billImageUrl'], 'https://x/bill.jpg');
      expect((vars['items'] as List).single['remarks'], 'counter - torn');
    },
  );

  test('a retried bill reuses its request id until it succeeds', () async {
    var attempts = 0;
    gateway.handlers['SubmitReturnBatch'] = (_) {
      if (++attempts == 1) throw const NetworkException();
      return {
        'returnRecord_inserts': [
          {'id': 'r-$attempts'},
        ],
      };
    };
    const input = CreateReturnBatchInput(
      invoiceNumber: 'INV-9',
      items: [
        ReturnLineItemInput(
          productTitle: 'Milk',
          quantity: 1,
          reason: ReturnReason.other,
        ),
      ],
    );

    await expectLater(
      remote.submitBatch(branchId: 'b1', input: input),
      throwsA(isA<NetworkException>()),
    );
    await remote.submitBatch(branchId: 'b1', input: input);
    await remote.submitBatch(branchId: 'b1', input: input);

    expect(gateway.varsOf('SubmitReturnBatch').map((v) => v['requestId']), [
      'req-1',
      'req-1',
      'req-2',
    ]);
  });

  test('rows map the stored bill number and return date', () {
    final item = DataConnectReturnsRemote.mapBranchReturn(
      {..._managedRow(), 'billNumber': 'BILL-7', 'returnDate': '2026-03-05'},
      organizationId: 'org1',
      branch: _branch,
    );
    expect(item.billNumber, 'BILL-7');
    expect(item.returnDate, DateTime(2026, 3, 5));
  });

  test('rows saved before the return date existed fall back to createdAt', () {
    final item = DataConnectReturnsRemote.mapBranchReturn(
      _managedRow(),
      organizationId: 'org1',
      branch: _branch,
    );
    expect(item.billNumber, isNull);
    expect(item.returnDate, DateTime.parse('2026-11-07T09:00:00.000Z'));
  });

  test('review sends notes only when given', () async {
    gateway.respond('UpdateReturnRecordReview', {
      'returnRecord_update': {'id': 'r1'},
    });

    await remote.review(returnId: 'r1', decision: ReturnStatus.approved);
    await remote.review(
      returnId: 'r1',
      decision: ReturnStatus.rejected,
      reviewerNotes: ' no ',
    );

    expect(gateway.varsOf('UpdateReturnRecordReview'), [
      {'id': 'r1', 'status': 'approved'},
      {'id': 'r1', 'status': 'rejected', 'reviewerNotes': 'no'},
    ]);
  });

  test('review of a missing return throws NotFoundException', () async {
    gateway.respond('UpdateReturnRecordReview', {'returnRecord_update': null});
    expect(
      remote.review(returnId: 'gone', decision: ReturnStatus.approved),
      throwsA(isA<NotFoundException>()),
    );
  });
}
