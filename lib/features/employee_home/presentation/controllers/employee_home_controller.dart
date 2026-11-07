import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_attendance_state.dart';
import 'package:workaxis/features/employee_home/domain/models/employee_home_summary.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_repository.dart';
import 'package:workaxis/features/employee_home/domain/repositories/employee_home_simulator.dart';

enum EmployeeHomeStatus { initial, loading, loaded, error }

/// Controller managing Employee Home presentation state.
class EmployeeHomeController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  final EmployeeHomeRepository repository;

  final RequestGeneration _requests = RequestGeneration();
  final RequestGeneration _actionRequests = RequestGeneration();
  EmployeeHomeStatus _status = EmployeeHomeStatus.initial;
  EmployeeHomeSummary? _summary;
  String? _errorMessage;
  String? _actionErrorMessage;
  bool _isActionProcessing = false;
  UserAccessContext? _access;

  EmployeeHomeController({required this.repository});

  /// The debug-only simulator, or null in production builds and for any
  /// repository that is not a mock. Screens render demo controls only when
  /// this is non-null.
  EmployeeHomeSimulator? get simulator {
    if (!kDebugMode) return null;
    final repo = repository;
    if (repo is EmployeeHomeSimulator) return repo as EmployeeHomeSimulator;
    return null;
  }

  EmployeeHomeStatus get status => _status;
  bool get isLoading => _status == EmployeeHomeStatus.loading;
  bool get hasError => _status == EmployeeHomeStatus.error;
  bool get isActionProcessing => _isActionProcessing;
  EmployeeHomeSummary? get summary => _summary;

  /// Failure from the last load attempt.
  String? get errorMessage => _errorMessage;

  /// Failure from the last attendance action; kept separate from load errors so
  /// a failed punch never replaces the loaded summary with an error state.
  String? get actionErrorMessage => _actionErrorMessage;

  Future<void> loadHomeSummary({required UserAccessContext access}) async {
    _access = access;
    final token = _requests.next();
    _status = EmployeeHomeStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getEmployeeHomeSummary(access: access);
      if (!_requests.isCurrent(token)) return;
      _summary = result;
      _status = EmployeeHomeStatus.loaded;
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load your home summary. Please try again.',
      );
      _status = EmployeeHomeStatus.error;
    }
    notifyListeners();
  }

  /// Dispatches an attendance action to the repository and updates summary.
  /// Returns whether it was recorded; on failure [actionErrorMessage] is set.
  Future<bool> recordAttendanceAction(AttendanceAction action) async {
    final access = _access;
    if (_summary == null || access == null || _isActionProcessing) {
      return false;
    }
    return _runAction(
      () => repository.recordAttendanceAction(access: access, action: action),
      fallback: 'The attendance action could not be recorded. Try again.',
    );
  }

  /// Triggers the next suggested attendance action based on current state.
  Future<bool> performNextAttendanceAction() async {
    final next = _summary?.currentStatus.nextAction;
    if (next == null) return false;
    return recordAttendanceAction(next);
  }

  /// Explicit check out action dispatch.
  Future<bool> performCheckOut() =>
      recordAttendanceAction(AttendanceAction.checkOut);

  /// Applies a simulated status. Only available when [simulator] is non-null
  /// (mock backend in debug builds); otherwise a no-op returning false.
  Future<bool> setSimulatedStatus(AttendanceStatus status) async {
    final sim = simulator;
    if (sim == null || _isActionProcessing) return false;
    return _runAction(
      () => sim.setSimulatedStatus(status),
      fallback: 'The simulated status could not be applied.',
    );
  }

  void clearActionError() {
    if (_actionErrorMessage != null) {
      _actionErrorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> _runAction(
    Future<EmployeeHomeSummary> Function() action, {
    required String fallback,
  }) async {
    final token = _actionRequests.next();
    _isActionProcessing = true;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await action();
      if (!_actionRequests.isCurrent(token)) return false;
      _summary = updated;
      _isActionProcessing = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      if (!_actionRequests.isCurrent(token)) return false;
      _actionErrorMessage = userMessageFor(e, st, fallback: fallback);
      _isActionProcessing = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void reset() {
    _requests.invalidate();
    _actionRequests.invalidate();
    _status = EmployeeHomeStatus.initial;
    _summary = null;
    _errorMessage = null;
    _actionErrorMessage = null;
    _isActionProcessing = false;
    _access = null;
    notifyListeners();
  }
}
