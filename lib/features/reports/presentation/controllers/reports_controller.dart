import 'package:flutter/foundation.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/reports/domain/models/operational_report_summary.dart';
import 'package:workaxis/features/reports/domain/repositories/reports_repository.dart';

class ReportsController extends ChangeNotifier {
  final ReportsRepository repository;

  bool _isLoading = false;
  String? _errorMessage;
  OperationalReportSummary? _summary;
  String _selectedPeriod = 'This Week';

  ReportsController({required this.repository});

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  OperationalReportSummary? get summary => _summary;
  String get selectedPeriod => _selectedPeriod;

  Future<void> loadReports({
    required UserAccessContext access,
    String? activeBranchId,
    String? period,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    if (period != null) _selectedPeriod = period;
    notifyListeners();

    try {
      _summary = await repository.getReportSummary(
        access: access,
        activeBranchId: activeBranchId,
        period: _selectedPeriod,
      );
    } catch (e) {
      _errorMessage = 'Failed to load operational report data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPeriod(
    String period, {
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
}
