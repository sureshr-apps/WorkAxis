import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/backend/idempotent_creates.dart';
import 'package:workaxis/features/leaves/data/leaves_remote_data_source.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';

import '../../helpers/fake_data_gateway.dart';

void main() {
  late IdempotentCreates creates;
  late List<String?> sent;

  setUp(() {
    var next = 0;
    creates = IdempotentCreates(newRequestId: () => 'req-${++next}');
    sent = [];
  });

  Future<String> send(Map<String, Object?> vars, {bool fail = false}) =>
      creates.run('Create', vars, (withId) async {
        sent.add(withId['requestId'] as String?);
        if (fail) throw StateError('lost response');
        return 'ok';
      });

  test('a failed create is retried with the same request id', () async {
    await expectLater(send({'a': 1}, fail: true), throwsStateError);
    await send({'a': 1});
    expect(sent, ['req-1', 'req-1']);
  });

  test('a successful create releases its id for the next submission', () async {
    await send({'a': 1});
    await send({'a': 1});
    expect(sent, ['req-1', 'req-2']);
  });

  test('changed details get a different request id', () async {
    await expectLater(send({'a': 1}, fail: true), throwsStateError);
    await send({'a': 2});
    expect(sent, ['req-1', 'req-2']);
  });

  test('leave submissions carry a request id', () async {
    final gateway = FakeDataGateway()
      ..respond('SubmitLeaveRequest', {
        'leaveRequest': {
          'id': 'lr1',
          'organizationId': 'o1',
          'branchId': 'b1',
          'branchName': 'Main',
          'applicantMemberId': 'm1',
          'applicantUid': 'u1',
          'applicantName': 'Eve',
          'applicantRole': 'employee',
          'leaveTypeId': 'lt-sick',
          'leaveTypeName': 'Sick leave',
          'leaveTypePaid': true,
          'startDate': '2026-11-24',
          'endDate': '2026-11-25',
          'reason': 'Fever',
          'status': 'pending',
          'createdAt': '2026-11-23T05:00:00.000Z',
          'updatedAt': '2026-11-23T05:00:00.000Z',
        },
      });
    final remote = LeavesRemoteDataSource(gateway, creates: creates);
    await remote.submit(
      branchId: 'b1',
      draft: LeaveRequestDraft(
        leaveTypeId: 'lt-sick',
        startDate: DateTime(2026, 11, 24),
        endDate: DateTime(2026, 11, 25),
        reason: 'Fever',
      ),
    );
    expect(gateway.singleVarsOf('SubmitLeaveRequest')['requestId'], 'req-1');
  });
}
