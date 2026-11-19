import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/leaves/domain/models/leave_request.dart';
import 'package:workaxis/features/leaves/domain/repositories/leaves_repository.dart';

class LeavesController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  LeavesController({required this.repository});

  final LeavesRepository repository;
  final RequestGeneration _requests = RequestGeneration();
  int _epoch = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _actionErrorMessage;
  List<LeaveRequest> _items = const [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  List<LeaveRequest> get items => _items;
  int get pendingCount =>
      _items.where((item) => item.status == LeaveStatus.pending).length;

  Future<void> loadLeaveRequests({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    final token = _requests.next();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final items = await repository.getLeaveRequests(
        access: access,
        activeBranchId: activeBranchId,
      );
      if (!_requests.isCurrent(token)) return;
      _items = List.unmodifiable(items);
    } catch (error, stackTrace) {
      if (!_requests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'Leave requests could not be loaded. Please try again.',
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitLeaveRequest({
    required UserAccessContext access,
    String? branchId,
    String? activeBranchId,
    required LeaveRequestDraft draft,
  }) => _save(
    () => repository.submitLeaveRequest(
      access: access,
      branchId: branchId,
      activeBranchId: activeBranchId,
      draft: draft,
    ),
    onSaved: (request) => _items = [request, ..._items],
    fallback: 'The leave request could not be submitted.',
  );

  Future<bool> updatePendingLeaveRequest({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
    required LeaveRequestDraft draft,
  }) => _save(
    () => repository.updatePendingLeaveRequest(
      access: access,
      activeBranchId: activeBranchId,
      request: request,
      draft: draft,
    ),
    onSaved: _replace,
    fallback: 'The pending leave request could not be updated.',
  );

  Future<bool> reviewLeaveRequest({
    required UserAccessContext access,
    String? activeBranchId,
    required LeaveRequest request,
    required LeaveStatus decision,
    String? reviewerNotes,
  }) => _save(
    () => repository.reviewLeaveRequest(
      access: access,
      activeBranchId: activeBranchId,
      request: request,
      decision: decision,
      reviewerNotes: reviewerNotes,
    ),
    onSaved: _replace,
    fallback: 'The leave decision could not be saved.',
  );

  Future<bool> _save(
    Future<LeaveRequest> Function() action, {
    required ValueChanged<LeaveRequest> onSaved,
    required String fallback,
  }) async {
    final epoch = _epoch;
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final result = await action();
      if (epoch != _epoch || isDisposed) return false;
      onSaved(result);
      return true;
    } catch (error, stackTrace) {
      if (epoch != _epoch || isDisposed) return false;
      _actionErrorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: fallback,
      );
      return false;
    } finally {
      if (epoch == _epoch && !isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  void _replace(LeaveRequest request) {
    _items = [
      for (final existing in _items)
        if (existing.id == request.id) request else existing,
    ];
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
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    _actionErrorMessage = null;
    _items = const [];
    notifyListeners();
  }
}
