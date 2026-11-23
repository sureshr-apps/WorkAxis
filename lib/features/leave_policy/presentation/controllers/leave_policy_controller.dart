import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_policy.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_input.dart';
import 'package:workaxis/features/leave_policy/domain/models/leave_type_policy.dart';
import 'package:workaxis/features/leave_policy/domain/repositories/leave_policy_repository.dart';

enum LeavePolicyLoadStatus { initial, loading, loaded, error }

/// Presentation state of the organization's leave policy (Org Admin).
///
/// Load state ([status], [loadErrorMessage]) is kept apart from change state
/// ([isSavingType], [isUpdatingAccrual], [actionErrorMessage]) so a failed
/// change never discards the loaded policy. Every change saves immediately.
class LeavePolicyController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  LeavePolicyController({required this.repository});

  final LeavePolicyRepository repository;

  final RequestGeneration _loads = RequestGeneration();

  /// Bumped only by [reset]; changes started before it are dropped.
  int _scopeGeneration = 0;

  LeavePolicyLoadStatus _status = LeavePolicyLoadStatus.initial;
  LeavePolicy? _policy;
  String? _loadErrorMessage;
  String? _actionErrorMessage;
  bool _isSavingType = false;
  bool _isUpdatingAccrual = false;

  LeavePolicyLoadStatus get status => _status;
  LeavePolicy? get policy => _policy;
  String? get loadErrorMessage => _loadErrorMessage;

  /// Why the last save, removal or accrual change failed.
  String? get actionErrorMessage => _actionErrorMessage;
  bool get isSavingType => _isSavingType;
  bool get isUpdatingAccrual => _isUpdatingAccrual;

  Future<void> load(UserAccessContext access) async {
    final token = _loads.next();
    _status = LeavePolicyLoadStatus.loading;
    _loadErrorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getLeavePolicy(access: access);
      if (!_loads.isCurrent(token)) return;
      _policy = result;
      _status = LeavePolicyLoadStatus.loaded;
    } catch (error, stackTrace) {
      if (!_loads.isCurrent(token)) return;
      _loadErrorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: 'Could not load the leave policy. Please try again.',
      );
      _status = LeavePolicyLoadStatus.error;
    }
    notifyListeners();
  }

  /// Creates or updates a leave type; returns whether it was saved.
  Future<bool> saveLeaveType(UserAccessContext access, LeaveTypeInput input) {
    return _change(
      setBusy: (busy) => _isSavingType = busy,
      fallback: 'The leave type could not be saved. Please try again.',
      run: () async {
        final saved = await repository.saveLeaveType(
          access: access,
          input: input,
        );
        return (LeavePolicy policy) => policy.withSavedType(saved);
      },
    );
  }

  /// Archives [type]; returns whether it was removed.
  Future<bool> archiveLeaveType(
    UserAccessContext access,
    LeaveTypePolicy type,
  ) {
    return _change(
      setBusy: (busy) => _isSavingType = busy,
      fallback: 'The leave type could not be removed. Please try again.',
      run: () async {
        await repository.archiveLeaveType(access: access, leaveTypeId: type.id);
        return (LeavePolicy policy) => policy.withoutType(type.id);
      },
    );
  }

  /// Turns monthly accrual on or off; returns whether it was saved. On
  /// failure the previous value stays in [policy].
  Future<bool> setMonthlyAccrual(UserAccessContext access, bool enabled) {
    return _change(
      setBusy: (busy) => _isUpdatingAccrual = busy,
      fallback: 'Monthly accrual could not be changed. Please try again.',
      run: () async {
        final saved = await repository.setMonthlyAccrual(
          access: access,
          monthlyAccrual: enabled,
        );
        return (LeavePolicy policy) => policy.copyWith(monthlyAccrual: saved);
      },
    );
  }

  void clearActionError() {
    if (_actionErrorMessage == null) return;
    _actionErrorMessage = null;
    notifyListeners();
  }

  /// Runs a change and applies its result to the loaded policy, unless the
  /// session was [reset] meanwhile.
  Future<bool> _change({
    required void Function(bool busy) setBusy,
    required String fallback,
    required Future<LeavePolicy Function(LeavePolicy)> Function() run,
  }) async {
    final scope = _scopeGeneration;
    _actionErrorMessage = null;
    setBusy(true);
    notifyListeners();
    try {
      final apply = await run();
      if (scope != _scopeGeneration) return false;
      final policy = _policy;
      if (policy != null) _policy = apply(policy);
      return true;
    } catch (error, stackTrace) {
      if (scope != _scopeGeneration) return false;
      _actionErrorMessage = userMessageFor(
        error,
        stackTrace,
        fallback: fallback,
      );
      return false;
    } finally {
      if (scope == _scopeGeneration) {
        setBusy(false);
        notifyListeners();
      }
    }
  }

  @override
  void reset() {
    _loads.invalidate();
    _scopeGeneration++;
    _status = LeavePolicyLoadStatus.initial;
    _policy = null;
    _loadErrorMessage = null;
    _actionErrorMessage = null;
    _isSavingType = false;
    _isUpdatingAccrual = false;
    notifyListeners();
  }
}
