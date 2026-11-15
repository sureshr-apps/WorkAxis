import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/reports/data/report_period_range.dart';
import 'package:workaxis/features/reports/data/reports_remote.dart';

import '../../helpers/fake_data_gateway.dart';

void main() {
  final range = ReportRange(
    from: DateTime.utc(2026, 11, 1),
    to: DateTime.utc(2026, 11, 8),
  );
  late FakeDataGateway gateway;
  late DataConnectReportsRemote remote;

  setUp(() {
    gateway = FakeDataGateway();
    remote = DataConnectReportsRemote(gateway: gateway);
  });

  test('organization stats group by branch and reason', () async {
    gateway.respond('GetReturnCountsByBranch', {
      'returnRecords': [
        {'branchId': 'b1', 'status': 'pending', '_count': 2},
        {'branchId': 'b1', 'status': 'approved', '_count': 1},
        {'branchId': 'b2', 'status': 'pending', '_count': 4},
      ],
      'returnsByReason': [
        {'returnReason': 'damaged', '_count': 5},
        {'returnReason': 'expired', '_count': 2},
      ],
    });

    final stats = await remote.returnStatsForOrganization('org1', range);

    expect(gateway.singleVarsOf('GetReturnCountsByBranch'), {
      'orgId': 'org1',
      'from': '2026-11-01T00:00:00.000Z',
      'to': '2026-11-08T00:00:00.000Z',
    });
    expect(stats.byBranch, {'b1': 3, 'b2': 4});
    expect(stats.byReason, {'damaged': 5, 'expired': 2});
  });

  test('branch stats total the statuses under the branch id', () async {
    gateway.respond('GetBranchStats', {
      'memberCount': [
        {'_count': 3},
      ],
      'returnsByStatus': [
        {'status': 'pending', '_count': 2},
        {'status': 'rejected', '_count': 3},
      ],
      'returnsByReason': [
        {'returnReason': 'other', '_count': 5},
      ],
    });

    final stats = await remote.returnStatsForBranch('b1', range);

    expect(gateway.singleVarsOf('GetBranchStats'), {
      'branchId': 'b1',
      'from': '2026-11-01T00:00:00.000Z',
      'to': '2026-11-08T00:00:00.000Z',
    });
    expect(stats.byBranch, {'b1': 5});
    expect(stats.byReason, {'other': 5});
  });
}
