import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_repository.dart';

class AttendanceController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  AttendanceController({required this.repository, Now now = systemNow})
    : _now = now,
      _selectedDate = BusinessTime.today(now);

  final AttendanceRepository repository;
  final Now _now;
  final RequestGeneration _requests = RequestGeneration();

  /// Bumped by [reset]; in-flight actions started before it must not touch
  /// the (now cleared) state.
  int _epoch = 0;
  List<AttendanceEntry> _entries = const [];
  DateTime _selectedDate;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _actionErrorMessage;

  List<AttendanceEntry> get entries => _entries;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  int get needsReviewCount => _entries
      .where(
        (entry) => entry.reviewStatus == AttendanceReviewStatus.needsReview,
      )
      .length;

  int get onTimeCount =>
      _entries.where((e) => e.status == AttendanceStatus.present).length;
  int get lateCount =>
      _entries.where((e) => e.status == AttendanceStatus.late).length;

  /// Today's business date according to the injected clock.
  DateTime get today => BusinessTime.today(_now);

  /// Yesterday's business date according to the injected clock.
  DateTime get yesterday => today.subtract(const Duration(days: 1));

  bool get isTodaySelected => _sameDate(_selectedDate, today);
  bool get isYesterdaySelected => _sameDate(_selectedDate, yesterday);

  Future<void> loadAttendance({
    required UserAccessContext access,
    String? activeBranchId,
    DateTime? date,
  }) async {
    final token = _requests.next();
    if (date != null) _selectedDate = date;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getAttendance(
        access: access,
        date: _selectedDate,
        activeBranchId: activeBranchId,
      );
      if (!_requests.isCurrent(token)) return;
      _entries = result;
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load attendance. Try again.',
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> reviewException({
    required UserAccessContext access,
    required String entryId,
    required String activeBranchId,
    required AttendanceReviewDecision decision,
  }) async {
    final epoch = _epoch;
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final updated = await repository.reviewException(
        access: access,
        entryId: entryId,
        activeBranchId: activeBranchId,
        decision: decision,
      );
      if (epoch != _epoch) return false;
      _entries = _entries
          .map((entry) => entry.id == updated.id ? updated : entry)
          .toList(growable: false);
      return true;
    } catch (e, st) {
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'This attendance item could not be reviewed.',
      );
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> markGroupAttendance({
    required UserAccessContext access,
    required GroupAttendanceRequest request,
  }) async {
    final epoch = _epoch;
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final updatedEntries = await repository.markGroupAttendance(
        access: access,
        request: request,
      );
      if (epoch != _epoch) return false;
      if (_sameDate(_selectedDate, request.workDate)) {
        final map = {for (final e in _entries) e.id: e};
        for (final e in updatedEntries) {
          map[e.id] = e;
        }
        _entries = map.values.toList()
          ..sort(
            (a, b) => (a.checkInAt ?? a.workDate).compareTo(
              b.checkInAt ?? b.workDate,
            ),
          );
      }
      return true;
    } catch (e, st) {
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not record group attendance. Try again.',
      );
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearActionError() {
    if (_actionErrorMessage != null) {
      _actionErrorMessage = null;
      notifyListeners();
    }
  }

  @override
  void reset() {
    _epoch++;
    _requests.invalidate();
    _entries = const [];
    _selectedDate = BusinessTime.today(_now);
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    _actionErrorMessage = null;
    notifyListeners();
  }

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
