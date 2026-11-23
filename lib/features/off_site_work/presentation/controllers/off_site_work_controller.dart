import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/off_site_work/domain/models/off_site_work_assignment.dart';
import 'package:workaxis/features/off_site_work/domain/repositories/off_site_work_repository.dart';

class OffSiteWorkController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  OffSiteWorkController({required this.repository});

  final OffSiteWorkRepository repository;
  final RequestGeneration _requests = RequestGeneration();
  int _scopeEpoch = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _actionErrorMessage;
  List<OffSiteWorkAssignment> _items = const [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  List<OffSiteWorkAssignment> get items => _items;

  Future<void> load({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    final epoch = _scopeEpoch;
    final token = _requests.next();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final items = await repository.getAssignments(
        access: access,
        activeBranchId: activeBranchId,
      );
      if (!_isCurrent(epoch) || !_requests.isCurrent(token)) return;
      _items = items;
    } catch (e, st) {
      if (!_isCurrent(epoch) || !_requests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Off-site assignments could not be loaded. Try again.',
      );
    } finally {
      if (_isCurrent(epoch) && _requests.isCurrent(token)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<OffSiteWorkAssignment?> getAssignment({
    required UserAccessContext access,
    required String assignmentId,
    String? activeBranchId,
  }) async {
    final epoch = _scopeEpoch;
    try {
      return await repository.getAssignment(
        access: access,
        assignmentId: assignmentId,
        activeBranchId: activeBranchId,
      );
    } catch (e, st) {
      if (_isCurrent(epoch)) {
        _actionErrorMessage = userMessageFor(
          e,
          st,
          fallback: 'This assignment could not be loaded.',
        );
        notifyListeners();
      }
      return null;
    }
  }

  Future<bool> createAssignment({
    required UserAccessContext access,
    String? activeBranchId,
    required OffSiteWorkAssignmentDraft draft,
  }) => _perform(
    () => repository.createAssignment(
      access: access,
      activeBranchId: activeBranchId,
      draft: draft,
    ),
    _replace,
    fallback: 'The assignment could not be created.',
  );

  Future<bool> deleteAssignment({
    required UserAccessContext access,
    String? activeBranchId,
    required String assignmentId,
  }) => _perform<void>(
    () => repository.deleteAssignment(
      access: access,
      activeBranchId: activeBranchId,
      assignmentId: assignmentId,
    ),
    (_) => _items = _items.where((item) => item.id != assignmentId).toList(),
    fallback: 'The assignment could not be deleted. Refresh and try again.',
  );

  Future<bool> recordMilestone({
    required UserAccessContext access,
    String? activeBranchId,
    required String assignmentId,
    required OffSiteWorkMilestone milestone,
    String? note,
    List<String> evidenceLocalPaths = const [],
  }) => _perform(
    () => repository.recordMilestone(
      access: access,
      activeBranchId: activeBranchId,
      assignmentId: assignmentId,
      milestone: milestone,
      note: note,
      evidenceLocalPaths: evidenceLocalPaths,
    ),
    _replace,
    fallback:
        'The milestone could not be saved. Check your location and retry.',
  );

  /// Runs [request] and applies its result only while the scope that started
  /// it is still current, so a response that lands after a branch switch or
  /// sign-out never reaches the new scope's list.
  Future<bool> _perform<T>(
    Future<T> Function() request,
    void Function(T result) apply, {
    required String fallback,
  }) async {
    final epoch = _scopeEpoch;
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final result = await request();
      if (!_isCurrent(epoch)) return false;
      apply(result);
      return true;
    } catch (e, st) {
      if (_isCurrent(epoch)) {
        _actionErrorMessage = userMessageFor(e, st, fallback: fallback);
      }
      return false;
    } finally {
      if (_isCurrent(epoch)) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  void _replace(OffSiteWorkAssignment assignment) {
    final index = _items.indexWhere((item) => item.id == assignment.id);
    if (index < 0) {
      _items = [assignment, ..._items];
    } else {
      final next = [..._items];
      next[index] = assignment;
      _items = next;
    }
  }

  bool _isCurrent(int epoch) => epoch == _scopeEpoch && !isDisposed;

  void clearActionError() {
    if (_actionErrorMessage == null) return;
    _actionErrorMessage = null;
    notifyListeners();
  }

  @override
  void reset() {
    _scopeEpoch++;
    _requests.next();
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    _actionErrorMessage = null;
    _items = const [];
    notifyListeners();
  }
}
