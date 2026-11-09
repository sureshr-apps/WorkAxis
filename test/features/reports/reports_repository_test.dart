import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/reports/data/mock_reports_repository.dart';
import 'package:workaxis/features/reports/data/report_period_range.dart';
import 'package:workaxis/features/reports/data/reports_remote.dart';
import 'package:workaxis/features/reports/data/sql_connect_reports_repository.dart';
import 'package:workaxis/features/reports/domain/models/report_period.dart';
import 'package:workaxis/features/reports/domain/repositories/reports_repository.dart';

import '../../helpers/access_fixtures.dart';

class _FakeReportsRemote implements ReportsRemote {
  Map<String, int> byBranch = {
    'br-01': 5,
    'br-02': 2,
    'br-04': 0,
    'suspended-branch': 99,
  };
  Map<String, int> byReason = {'damaged': 4, 'expired': 2, 'weird-legacy': 1};
  Object? failWith;
  final List<String> calls = [];
  ReportRange? lastRange;

  @override
  Future<ReportReturnStats> returnStatsForOrganization(
    String organizationId,
    ReportRange range,
  ) async {
    calls.add('org:$organizationId');
    lastRange = range;
    if (failWith != null) throw failWith!;
    return ReportReturnStats(byBranch: byBranch, byReason: byReason);
  }

  @override
  Future<ReportReturnStats> returnStatsForBranch(
    String branchId,
    ReportRange range,
  ) async {
    calls.add('branch:$branchId');
    lastRange = range;
    if (failWith != null) throw failWith!;
    return ReportReturnStats(
      byBranch: {branchId: byBranch[branchId] ?? 0},
      byReason: byReason,
    );
  }
}

void _contract(String name, ReportsRepository Function() create) {
  group('ReportsRepository contract: $name', () {
    late ReportsRepository repo;
    setUp(() => repo = create());

    test('org admin report covers the organization\'s branches only', () async {
      final report = await repo.getReportSummary(
        access: orgAdminAccess(),
        period: ReportPeriod.thisMonth,
      );
      expect(report.period, ReportPeriod.thisMonth);
      expect(report.branchMetrics.map((m) => m.branchId), [
        'br-01',
        'br-02',
        'br-04',
      ]);
    });

    test('branch manager report covers only the active branch', () async {
      final report = await repo.getReportSummary(
        access: branchManagerAccess(),
        activeBranchId: 'br-01',
      );
      expect(report.branchMetrics.map((m) => m.branchId), ['br-01']);
    });

    test('a branch outside the assigned set is rejected', () {
      expect(
        () => repo.getReportSummary(
          access: branchManagerAccess(branchIds: ['br-01']),
          activeBranchId: 'br-02',
        ),
        throwsA(isA<BranchAuthorizationException>()),
      );
    });

    test('employees and platform users have no reports', () {
      expect(
        () => repo.getReportSummary(access: employeeAccess()),
        throwsA(isA<AccessDeniedException>()),
      );
      expect(
        () => repo.getReportSummary(access: platformAccess()),
        throwsA(isA<AccessDeniedException>()),
      );
    });
  });
}

void main() {
  _contract('mock', () => MockReportsRepository(delay: Duration.zero));
  _contract(
    'SQL Connect (fake remote)',
    () => SqlConnectReportsRepository(remote: _FakeReportsRemote()),
  );

  group('SqlConnectReportsRepository', () {
    late _FakeReportsRemote remote;
    late SqlConnectReportsRepository repo;
    setUp(() {
      remote = _FakeReportsRemote();
      repo = SqlConnectReportsRepository(remote: remote);
    });

    test('uses one aggregate query for the organization (no N+1)', () async {
      final report = await repo.getReportSummary(access: orgAdminAccess());
      expect(remote.calls, ['org:org-acme']);
      expect(report.returnVolume, 106);
      final byId = {for (final m in report.branchMetrics) m.branchId: m};
      expect(byId['br-01']!.returnCount, 5);
      expect(byId['br-04']!.returnCount, 0);
      expect(report.returnCountsCoverPeriod, isTrue);
    });

    test('counts are scoped to the period and grouped by reason', () async {
      final fixed = DateTime.utc(2026, 11, 11, 6); // Wed, 11:30 IST
      repo = SqlConnectReportsRepository(remote: remote, now: () => fixed);
      final report = await repo.getReportSummary(
        access: orgAdminAccess(),
        period: ReportPeriod.thisWeek,
      );
      // Monday 2026-11-09 00:00 IST .. Thursday 2026-11-12 00:00 IST.
      expect(remote.lastRange!.from, DateTime.utc(2026, 11, 8, 18, 30));
      expect(remote.lastRange!.to, DateTime.utc(2026, 11, 11, 18, 30));
      expect(report.returnCountsCoverPeriod, isTrue);
      final cats = {
        for (final c in report.returnCategories) c.categoryName: c.count,
      };
      expect(cats['Damaged Product'], 4);
      expect(cats['Other Reason'], 1); // unknown legacy reason
      expect(
        report.returnCategories.fold<double>(0, (s, c) => s + c.percentage),
        closeTo(100, 0.001),
      );
    });

    test('an org admin narrowed to a branch uses the branch query', () async {
      await repo.getReportSummary(
        access: orgAdminAccess(),
        activeBranchId: 'br-01',
      );
      expect(remote.calls, ['branch:br-01']);
    });

    test('branch managers use the branch stats query', () async {
      final report = await repo.getReportSummary(
        access: branchManagerAccess(),
        activeBranchId: 'br-02',
      );
      expect(remote.calls, ['branch:br-02']);
      expect(report.returnVolume, 2);
    });

    test(
      'metrics the backend cannot compute are unavailable, not invented',
      () async {
        final report = await repo.getReportSummary(access: orgAdminAccess());
        expect(report.attendanceRate, isNull);
        expect(report.onTimeRate, isNull);
        expect(report.totalHoursLogged, isNull);
        expect(report.exceptionCount, isNull);
        expect(report.returnRate, isNull);
        expect(report.dailyTrends, isEmpty);
        for (final m in report.branchMetrics) {
          expect(m.attendanceRate, isNull);
          expect(m.activeEmployees, isNull);
          expect(m.pendingExceptions, isNull);
        }
      },
    );

    test('failures are typed and never replaced by numbers', () async {
      remote.failWith = StateError('boom');
      await expectLater(
        repo.getReportSummary(access: orgAdminAccess()),
        throwsA(isA<DatabaseException>()),
      );
      remote.failWith = const NetworkException();
      await expectLater(
        repo.getReportSummary(access: orgAdminAccess()),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('ReportPeriodRange', () {
    final now = DateTime.utc(2026, 11, 11, 6);
    test('month, last month and quarter use the business calendar', () {
      final month = ReportPeriodRange.resolve(
        ReportPeriod.thisMonth,
        () => now,
      );
      expect(month.from, DateTime.utc(2026, 10, 31, 18, 30));
      final last = ReportPeriodRange.resolve(ReportPeriod.lastMonth, () => now);
      expect(last.from, DateTime.utc(2026, 9, 30, 18, 30));
      expect(last.to, month.from);
      final q = ReportPeriodRange.resolve(
        ReportPeriod.quarterToDate,
        () => now,
      );
      expect(q.from, DateTime.utc(2026, 9, 30, 18, 30)); // Oct 1 IST
    });
  });

  test('ReportPeriod has display labels', () {
    expect(ReportPeriod.thisWeek.label, 'This Week');
    expect(ReportPeriod.quarterToDate.label, 'Quarter to Date');
  });
}
