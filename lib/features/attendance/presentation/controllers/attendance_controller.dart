import 'package:flutter/foundation.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';
import 'package:workaxis/features/attendance/domain/models/group_attendance_request.dart';
import 'package:workaxis/features/attendance/domain/repositories/attendance_repository.dart';

class AttendanceController extends ChangeNotifier {
  AttendanceController({required this.repository});

  final AttendanceRepository repository;
  List<AttendanceEntry> _entries = const [];
  DateTime _selectedDate = DateTime.now();
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

  Future<void> loadAttendance({
    required UserAccessContext access,
    String? activeBranchId,
    DateTime? date,
  }) async {
    if (date != null) _selectedDate = date;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _entries = await repository.getAttendance(
        access: access,
        date: _selectedDate,
        activeBranchId: activeBranchId,
      );
    } catch (_) {
      _errorMessage = 'Could not load attendance. Try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reviewException({
    required UserAccessContext access,
    required String entryId,
    required String activeBranchId,
    required AttendanceReviewDecision decision,
  }) async {
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
      _entries = _entries
          .map((entry) => entry.id == updated.id ? updated : entry)
          .toList(growable: false);
      return true;
    } catch (_) {
      _actionErrorMessage = 'This attendance item could not be reviewed.';
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
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final updatedEntries = await repository.markGroupAttendance(
        access: access,
        request: request,
      );
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
    } catch (_) {
      _actionErrorMessage = 'Could not record group attendance. Try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
