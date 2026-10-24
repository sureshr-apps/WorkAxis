import 'package:flutter/foundation.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_repository.dart';

enum EmployeeHomeStatus { initial, loading, loaded, error }

/// Controller managing Employee Home presentation state.
class EmployeeHomeController extends ChangeNotifier {
  final EmployeeHomeRepository repository;

  EmployeeHomeStatus _status = EmployeeHomeStatus.initial;
  EmployeeHomeSummary? _summary;
  String? _errorMessage;
  bool _isActionProcessing = false;

  EmployeeHomeController({required this.repository});

  EmployeeHomeStatus get status => _status;
  bool get isLoading => _status == EmployeeHomeStatus.loading;
  bool get hasError => _status == EmployeeHomeStatus.error;
  bool get isActionProcessing => _isActionProcessing;
  EmployeeHomeSummary? get summary => _summary;
  String? get errorMessage => _errorMessage;

  Future<void> loadHomeSummary() async {
    _status = EmployeeHomeStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getEmployeeHomeSummary();
      _summary = result;
      _status = EmployeeHomeStatus.loaded;
    } catch (e) {
      _errorMessage = 'Failed to load employee home: $e';
      _status = EmployeeHomeStatus.error;
    } finally {
      notifyListeners();
    }
  }

  /// Dispatches an attendance action to the repository and updates summary.
  Future<void> recordAttendanceAction(AttendanceAction action) async {
    if (_summary == null || _isActionProcessing) return;

    _isActionProcessing = true;
    notifyListeners();

    try {
      _summary = await repository.recordAttendanceAction(action);
    } catch (e) {
      _errorMessage = 'Attendance action failed: $e';
    } finally {
      _isActionProcessing = false;
      notifyListeners();
    }
  }

  /// Triggers the next suggested attendance action based on current state.
  Future<void> performNextAttendanceAction() async {
    final next = _summary?.currentStatus.nextAction;
    if (next != null) {
      await recordAttendanceAction(next);
    }
  }

  /// Explicit check out action dispatch.
  Future<void> performCheckOut() async {
    await recordAttendanceAction(AttendanceAction.checkOut);
  }

  /// Sets simulated status for frontline simulation controls.
  Future<void> setSimulatedStatus(AttendanceStatus status) async {
    if (_isActionProcessing) return;
    _isActionProcessing = true;
    notifyListeners();

    try {
      _summary = await repository.setSimulatedStatus(status);
    } catch (e) {
      _errorMessage = 'Simulation failed: $e';
    } finally {
      _isActionProcessing = false;
      notifyListeners();
    }
  }
}
