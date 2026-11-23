import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/payroll/domain/models/monthly_payroll.dart';
import 'package:workaxis/features/payroll/domain/repositories/payroll_repository.dart';

class PayslipsController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  PayslipsController({required this.repository});

  final PayrollRepository repository;
  MonthlyPayroll? _payroll;
  String? _errorMessage;
  bool _isLoading = false;
  int _generation = 0;

  MonthlyPayroll? get payroll => _payroll;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> load({
    required UserAccessContext access,
    required String month,
    String? activeBranchId,
    PayrollView view = PayrollView.self,
    String? selectedMemberId,
  }) async {
    final generation = ++_generation;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getMonthlyPayroll(
        access: access,
        month: month,
        activeBranchId: activeBranchId,
        view: view,
        selectedMemberId: selectedMemberId,
      );
      if (generation != _generation) return;
      _payroll = result;
    } catch (error, stackTrace) {
      if (generation != _generation) return;
      _errorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'Monthly pay could not be loaded.',
      );
    } finally {
      if (generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void reset() {
    _generation++;
    _payroll = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
