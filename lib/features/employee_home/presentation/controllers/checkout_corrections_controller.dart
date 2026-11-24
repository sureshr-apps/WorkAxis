import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_exceptions_repository.dart';

enum CheckoutCorrectionsStatus { initial, loading, loaded, error }

/// The signed-in user's sessions with a missing or late check-out, and their
/// correction requests. Created by the Employee Home section that shows it.
class CheckoutCorrectionsController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  CheckoutCorrectionsController({required this.repository});

  final AttendanceExceptionsRepository repository;

  final RequestGeneration _loads = RequestGeneration();
  final RequestGeneration _submits = RequestGeneration();
  CheckoutCorrectionsStatus _status = CheckoutCorrectionsStatus.initial;
  List<AttendanceEntry> _entries = const [];
  String? _errorMessage;
  String? _submitErrorMessage;
  bool _isSubmitting = false;
  UserAccessContext? _access;

  CheckoutCorrectionsStatus get status => _status;
  bool get isLoading => _status == CheckoutCorrectionsStatus.loading;
  bool get hasError => _status == CheckoutCorrectionsStatus.error;
  List<AttendanceEntry> get entries => _entries;
  String? get errorMessage => _errorMessage;

  /// Failure of the last correction request; the dialog shows it in place.
  String? get submitErrorMessage => _submitErrorMessage;
  bool get isSubmitting => _isSubmitting;

  Future<void> load({required UserAccessContext access}) async {
    _access = access;
    final token = _loads.next();
    _status = CheckoutCorrectionsStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final entries = await repository.getCorrectableEntries(access: access);
      if (!_loads.isCurrent(token)) return;
      _entries = entries;
      _status = CheckoutCorrectionsStatus.loaded;
    } catch (e, st) {
      if (!_loads.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Check-outs to correct could not be loaded. Try again.',
      );
      _status = CheckoutCorrectionsStatus.error;
    }
    notifyListeners();
  }

  /// Reloads with the last access context, if any.
  Future<void> retry() async {
    final access = _access;
    if (access != null) await load(access: access);
  }

  /// Sends the request and refreshes the list. Returns whether it was sent;
  /// on failure [submitErrorMessage] explains why.
  Future<bool> requestCorrection({
    required String entryId,
    required DateTime checkOutAt,
    required String reason,
  }) async {
    final access = _access;
    if (access == null || _isSubmitting) return false;
    final token = _submits.next();
    _isSubmitting = true;
    _submitErrorMessage = null;
    notifyListeners();
    try {
      await repository.requestCheckoutCorrection(
        access: access,
        entryId: entryId,
        checkOutAt: checkOutAt,
        reason: reason.trim(),
      );
      if (!_submits.isCurrent(token)) return false;
      _isSubmitting = false;
      notifyListeners();
      await load(access: access);
      return true;
    } catch (e, st) {
      if (!_submits.isCurrent(token)) return false;
      _submitErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'The correction request could not be sent. Try again.',
      );
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void clearSubmitError() {
    if (_submitErrorMessage == null) return;
    _submitErrorMessage = null;
    notifyListeners();
  }

  @override
  void reset() {
    _loads.invalidate();
    _submits.invalidate();
    _status = CheckoutCorrectionsStatus.initial;
    _entries = const [];
    _errorMessage = null;
    _submitErrorMessage = null;
    _isSubmitting = false;
    _access = null;
    notifyListeners();
  }
}
