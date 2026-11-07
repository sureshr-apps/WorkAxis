import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';
import 'package:workaxis/features/reports/domain/models/report_period.dart';
import 'package:workaxis/features/reports/domain/repositories/reports_repository.dart';

class ReportsController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  static const ReportPeriod defaultPeriod = ReportPeriod.thisWeek;

  final ReportsRepository repository;

  final RequestGeneration _requests = RequestGeneration();
  bool _isLoading = false;
  String? _errorMessage;
  OperationalReportSummary? _summary;
  ReportPeriod _selectedPeriod = defaultPeriod;

  ReportsController({required this.repository});

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  OperationalReportSummary? get summary => _summary;
  ReportPeriod get selectedPeriod => _selectedPeriod;

  Future<void> loadReports({
    required UserAccessContext access,
    String? activeBranchId,
    ReportPeriod? period,
  }) async {
    final token = _requests.next();
    _isLoading = true;
    _errorMessage = null;
    if (period != null) _selectedPeriod = period;
    notifyListeners();

    try {
      final result = await repository.getReportSummary(
        access: access,
        activeBranchId: activeBranchId,
        period: _selectedPeriod,
      );
      if (!_requests.isCurrent(token)) return;
      _summary = result;
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Failed to load operational report data.',
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setPeriod(
    ReportPeriod period, {
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    await loadReports(
      access: access,
      activeBranchId: activeBranchId,
      period: period,
    );
  }

  @override
  void reset() {
    _requests.invalidate();
    _isLoading = false;
    _errorMessage = null;
    _summary = null;
    _selectedPeriod = defaultPeriod;
    notifyListeners();
  }
}
