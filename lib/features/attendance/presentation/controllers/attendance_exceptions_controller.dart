import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/checkout_correction.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_exceptions_repository.dart';

/// Pending check-out corrections and overtime for a manager to decide:
/// organization-wide for Org Admins, the active branch for Branch Managers.
/// Created per screen; [reset] clears it when the active branch changes.
class AttendanceExceptionsController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  AttendanceExceptionsController({required this.repository});

  final AttendanceExceptionsRepository repository;
  final RequestGeneration _requests = RequestGeneration();

  /// Bumped by [reset]; decisions started before it must not touch state.
  int _epoch = 0;
  List<CheckoutCorrection> _corrections = const [];
  List<AttendanceEntry> _overtime = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _actionErrorMessage;

  List<CheckoutCorrection> get corrections => _corrections;
  List<AttendanceEntry> get overtime => _overtime;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  int get pendingCount => _corrections.length + _overtime.length;

  Future<void> load({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    final token = _requests.next();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        repository.getPendingCorrections(
          access: access,
          activeBranchId: activeBranchId,
        ),
        repository.getPendingOvertime(
          access: access,
          activeBranchId: activeBranchId,
        ),
      ]);
      if (!_requests.isCurrent(token)) return;
      _corrections = List.unmodifiable(results[0] as List<CheckoutCorrection>);
      _overtime = List.unmodifiable(results[1] as List<AttendanceEntry>);
      _hasLoaded = true;
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load attendance exceptions. Try again.',
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> reviewCorrection({
    required UserAccessContext access,
    required String correctionId,
    required CorrectionDecision decision,
    String? note,
    String? activeBranchId,
  }) => _decide(
    access: access,
    activeBranchId: activeBranchId,
    fallback: 'This correction could not be reviewed.',
    request: () => repository.reviewCorrection(
      access: access,
      correctionId: correctionId,
      decision: decision,
      note: _blankToNull(note),
      activeBranchId: activeBranchId,
    ),
  );

  Future<bool> reviewOvertime({
    required UserAccessContext access,
    required String entryId,
    required OvertimeDecision decision,
    double? approvedHours,
    String? activeBranchId,
  }) => _decide(
    access: access,
    activeBranchId: activeBranchId,
    fallback: 'This overtime could not be reviewed.',
    request: () => repository.reviewOvertime(
      access: access,
      entryId: entryId,
      decision: decision,
      approvedHours: decision == OvertimeDecision.approve
          ? approvedHours
          : null,
      activeBranchId: activeBranchId,
    ),
  );

  /// Runs a decision and, on success, reloads both lists so the decided item
  /// leaves and anything decided elsewhere is reflected.
  Future<bool> _decide({
    required UserAccessContext access,
    required String? activeBranchId,
    required String fallback,
    required Future<void> Function() request,
  }) async {
    final epoch = _epoch;
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      await request();
      if (epoch != _epoch || isDisposed) return false;
      _isSaving = false;
      await load(access: access, activeBranchId: activeBranchId);
      return true;
    } catch (e, st) {
      if (epoch != _epoch || isDisposed) return false;
      _actionErrorMessage = userMessageFor(e, st, fallback: fallback);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void clearActionError() {
    if (_actionErrorMessage == null) return;
    _actionErrorMessage = null;
    notifyListeners();
  }

  @override
  void reset() {
    _epoch++;
    _requests.invalidate();
    _corrections = const [];
    _overtime = const [];
    _isLoading = false;
    _hasLoaded = false;
    _isSaving = false;
    _errorMessage = null;
    _actionErrorMessage = null;
    notifyListeners();
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
