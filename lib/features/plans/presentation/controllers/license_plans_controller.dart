import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/plans/domain/models/license_plan.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_draft.dart';
import 'package:workaxis/features/plans/domain/models/license_plan_summary.dart';
import 'package:workaxis/features/plans/domain/repositories/license_plans_repository.dart';

/// Controller for the platform license plan catalogue.
///
/// Status and search are server-side filters (they reload the list). The level
/// filter and the level sort run on the loaded rows. Every mutation reloads the
/// list so the screen always shows what the server saved.
class LicensePlansController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  LicensePlansController({
    required this.repository,
    this.searchDebounce = const Duration(milliseconds: 300),
  });

  final LicensePlansRepository repository;

  /// Delay before a search change reloads from the server.
  final Duration searchDebounce;

  int _scopeEpoch = 0;
  bool _isCurrentScope(int epoch) => epoch == _scopeEpoch && !isDisposed;

  final RequestGeneration _listRequests = RequestGeneration();
  Timer? _debounce;

  /// Rows returned by the server for the current status and search filters,
  /// across every level.
  List<LicensePlan> _loadedPlans = const [];

  /// Rows shown after the level filter, ordered by level ascending.
  List<LicensePlan> _visiblePlans = const [];
  LicensePlanSummary _summary = LicensePlanSummary.empty;

  bool _isListLoading = false;
  String? _listErrorMessage;
  bool _isActionLoading = false;
  String? _actionErrorMessage;

  String _searchQuery = '';
  PlanStatus? _statusFilter;
  int? _levelFilter;

  List<LicensePlan> get plans => _visiblePlans;
  LicensePlanSummary get summary => _summary;

  /// The highest-level plan that is visible, or null when none is.
  LicensePlan? get highestVisiblePlan =>
      _visiblePlans.isEmpty ? null : _visiblePlans.last;

  /// Distinct levels present in the loaded rows, ascending.
  List<int> get availableLevels {
    final levels = {for (final plan in _loadedPlans) plan.level}.toList()
      ..sort();
    return levels;
  }

  bool get isListLoading => _isListLoading;
  String? get listErrorMessage => _listErrorMessage;
  bool get isActionLoading => _isActionLoading;
  String? get actionErrorMessage => _actionErrorMessage;
  String get searchQuery => _searchQuery;
  PlanStatus? get statusFilter => _statusFilter;
  int? get levelFilter => _levelFilter;

  bool get hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _statusFilter != null ||
      _levelFilter != null;

  /// A plan from the loaded rows (any level), or null when it is not loaded.
  LicensePlan? findPlan(String id) {
    for (final plan in _loadedPlans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  /// Loads the catalogue with the current status and search filters. A
  /// [silent] reload keeps the visible rows and does not show a loading state.
  Future<void> loadPlans({bool silent = false}) async {
    final token = _listRequests.next();
    if (!silent) {
      _isListLoading = true;
      _listErrorMessage = null;
      notifyListeners();
    }

    final query = _searchQuery.trim();
    try {
      final catalog = await repository.listPlans(
        query: query.isEmpty ? null : query,
        status: _statusFilter,
      );
      if (!_listRequests.isCurrent(token)) return;
      _loadedPlans = List.unmodifiable(catalog.plans);
      _summary = catalog.summary;
      _recomputeVisible();
    } catch (e, st) {
      if (!_listRequests.isCurrent(token)) return;
      if (!silent) {
        _listErrorMessage = userMessageFor(
          e,
          st,
          fallback: 'Could not load license plans. Please try again.',
        );
      }
    }
    _isListLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () => unawaited(loadPlans()));
    notifyListeners();
  }

  void setStatusFilter(PlanStatus? status) {
    _statusFilter = status;
    _debounce?.cancel();
    notifyListeners();
    unawaited(loadPlans());
  }

  /// Level filtering happens on the loaded rows, so it does not reload.
  void setLevelFilter(int? level) {
    _levelFilter = level;
    _recomputeVisible();
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _levelFilter = null;
    _debounce?.cancel();
    notifyListeners();
    unawaited(loadPlans());
  }

  /// Creates a plan. Returns the saved plan, or null with
  /// [actionErrorMessage] set.
  Future<LicensePlan?> createPlan(CreateLicensePlanDraft draft) => _runAction(
    fallback: 'The plan could not be created. Please try again.',
    body: () => repository.createPlan(draft),
  );

  /// Saves an existing plan. Returns false with [actionErrorMessage] set on
  /// failure.
  Future<bool> updatePlan(String id, UpdateLicensePlanDraft draft) async {
    final saved = await _runAction<bool>(
      fallback: 'The plan could not be saved. Please try again.',
      body: () async {
        await repository.updatePlan(id, draft);
        return true;
      },
    );
    return saved ?? false;
  }

  /// Activates or deactivates a plan. Returns false with
  /// [actionErrorMessage] set on failure.
  Future<bool> changeStatus(String id, PlanStatus status) async {
    final changed = await _runAction<bool>(
      fallback: 'The plan status could not be changed. Please try again.',
      body: () async {
        await repository.changeStatus(id, status);
        return true;
      },
    );
    return changed ?? false;
  }

  /// Deletes a plan. A refusal leaves the plan in place and sets
  /// [actionErrorMessage] to the server's message.
  Future<bool> deletePlan(String id) async {
    final deleted = await _runAction<bool>(
      fallback: 'The plan could not be deleted. Please try again.',
      body: () async {
        await repository.deletePlan(id);
        return true;
      },
    );
    return deleted ?? false;
  }

  void clearActionError() {
    if (_actionErrorMessage != null) {
      _actionErrorMessage = null;
      notifyListeners();
    }
  }

  Future<T?> _runAction<T>({
    required String fallback,
    required Future<T> Function() body,
  }) async {
    final epoch = _scopeEpoch;
    _isActionLoading = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final result = await body();
      if (!_isCurrentScope(epoch)) return null;
      await loadPlans();
      if (!_isCurrentScope(epoch)) return null;
      return result;
    } catch (e, st) {
      if (!_isCurrentScope(epoch)) return null;
      _actionErrorMessage = userMessageFor(e, st, fallback: fallback);
      return null;
    } finally {
      if (_isCurrentScope(epoch)) {
        _isActionLoading = false;
        notifyListeners();
      }
    }
  }

  void _recomputeVisible() {
    final level = _levelFilter;
    final visible = [
      for (final plan in _loadedPlans)
        if (level == null || plan.level == level) plan,
    ]..sort((a, b) => a.level.compareTo(b.level));
    _visiblePlans = List.unmodifiable(visible);
  }

  @override
  void reset() {
    _scopeEpoch++;
    _debounce?.cancel();
    _listRequests.invalidate();
    _loadedPlans = const [];
    _visiblePlans = const [];
    _summary = LicensePlanSummary.empty;
    _isListLoading = false;
    _listErrorMessage = null;
    _isActionLoading = false;
    _actionErrorMessage = null;
    _searchQuery = '';
    _statusFilter = null;
    _levelFilter = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
