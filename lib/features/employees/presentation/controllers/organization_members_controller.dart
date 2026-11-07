import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/errors/user_message.dart';
import 'package:workaxis/core/session/session_scoped.dart';
import 'package:workaxis/core/state/request_generation.dart';
import 'package:workaxis/core/state/safe_notifier.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

class OrganizationMembersController extends ChangeNotifier
    with SafeNotifier
    implements SessionScoped {
  OrganizationMembersController({
    required this.repository,
    this.searchDebounce = const Duration(milliseconds: 300),
    this.pageSize = defaultPageSize,
  });

  final OrganizationMembersRepository repository;

  /// Accounts requested per page.
  final int pageSize;

  /// Delay applied to [setQuery] so typing does not hit the backend per key.
  final Duration searchDebounce;

  final RequestGeneration _requests = RequestGeneration();
  List<OrganizationMember> _members = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingMore = false;
  int _total = 0;
  AccountStatus? _statusFilter;
  UserRole? _roleFilter;
  String? _errorMessage;
  String? _actionErrorMessage;
  String _query = '';
  Timer? _debounceTimer;
  Completer<void>? _pendingSearch;

  List<OrganizationMember> get members => _members;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isLoadingMore => _isLoadingMore;

  /// Matching accounts on the server (not just the loaded pages).
  int get totalCount => _total;
  bool get hasMore => _members.length < _total;
  AccountStatus? get statusFilter => _statusFilter;
  UserRole? get roleFilter => _roleFilter;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  /// Current search text; seed search fields with it so the visible box and
  /// the applied filter never drift apart.
  String get query => _query;
  String get searchQuery => _query;

  /// Loads the first page for the current search and filters.
  Future<void> loadMembers({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    final token = _requests.next();
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    notifyListeners();
    try {
      final page = await repository.getMembersPage(
        access: access,
        activeBranchId: activeBranchId,
        query: _query,
        status: _statusFilter,
        role: _roleFilter,
        limit: pageSize,
      );
      if (!_requests.isCurrent(token)) return;
      _members = List.unmodifiable(page.items);
      _total = page.total;
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return;
      _errorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load organization accounts. Try again.',
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Appends the next page when more accounts exist.
  Future<void> loadMore({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    if (_isLoading || _isLoadingMore || !hasMore) return;
    final token = _requests.next();
    _isLoadingMore = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final page = await repository.getMembersPage(
        access: access,
        activeBranchId: activeBranchId,
        query: _query,
        status: _statusFilter,
        role: _roleFilter,
        offset: _members.length,
        limit: pageSize,
      );
      if (!_requests.isCurrent(token)) return;
      _members = List.unmodifiable([..._members, ...page.items]);
      _total = page.total;
    } catch (e, st) {
      if (!_requests.isCurrent(token)) return;
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'Could not load more accounts. Try again.',
      );
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Applies a status and/or role filter (server-side) and reloads.
  Future<void> setFilters({
    required UserAccessContext access,
    AccountStatus? status,
    UserRole? role,
    String? activeBranchId,
  }) {
    _statusFilter = status;
    _roleFilter = role;
    return loadMembers(access: access, activeBranchId: activeBranchId);
  }

  /// Updates the search text and reloads after [searchDebounce] of inactivity.
  /// The returned future completes when the (possibly coalesced) load finishes.
  Future<void> setQuery({
    required UserAccessContext access,
    required String query,
    String? activeBranchId,
  }) {
    _query = query;
    _debounceTimer?.cancel();
    final superseded = _pendingSearch;
    if (superseded != null && !superseded.isCompleted) superseded.complete();

    if (searchDebounce == Duration.zero) {
      return loadMembers(access: access, activeBranchId: activeBranchId);
    }

    final completer = Completer<void>();
    _pendingSearch = completer;
    _debounceTimer = Timer(searchDebounce, () async {
      try {
        await loadMembers(access: access, activeBranchId: activeBranchId);
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    });
    return completer.future;
  }

  Future<OrganizationMember?> getMember({
    required UserAccessContext access,
    required String memberId,
    String? activeBranchId,
  }) async {
    try {
      return await repository.getMember(
        access: access,
        memberId: memberId,
        activeBranchId: activeBranchId,
      );
    } catch (e, st) {
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'This account is outside your access scope.',
      );
      notifyListeners();
      return null;
    }
  }

  Future<OrganizationMember?> saveMember({
    required UserAccessContext access,
    required OrganizationMember member,
    required String initialPassword,
    String? activeBranchId,
  }) async {
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final result = await repository.saveMember(
        access: access,
        member: member,
        initialPassword: initialPassword,
        activeBranchId: activeBranchId,
      );
      await loadMembers(access: access, activeBranchId: activeBranchId);
      return result;
    } catch (error, st) {
      _actionErrorMessage = userMessageFor(
        error,
        st,
        fallback: 'The account could not be saved. Try again.',
      );
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Suspends or restores [member]. Returns the saved account, or null with
  /// [actionErrorMessage] set.
  Future<OrganizationMember?> setMemberStatus({
    required UserAccessContext access,
    required OrganizationMember member,
    required AccountStatus status,
    String? activeBranchId,
  }) async {
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      final saved = await repository.setMemberStatus(
        access: access,
        member: member,
        status: status,
        activeBranchId: activeBranchId,
      );
      _members = [for (final m in _members) m.id == saved.id ? saved : m];
      return saved;
    } catch (e, st) {
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'The account status could not be changed. Try again.',
      );
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Sets a new password for [member]. Returns whether it succeeded.
  Future<bool> resetMemberPassword({
    required UserAccessContext access,
    required OrganizationMember member,
    required String newPassword,
    String? activeBranchId,
  }) async {
    _isSaving = true;
    _actionErrorMessage = null;
    notifyListeners();
    try {
      await repository.resetMemberPassword(
        access: access,
        member: member,
        newPassword: newPassword,
        activeBranchId: activeBranchId,
      );
      return true;
    } catch (e, st) {
      _actionErrorMessage = userMessageFor(
        e,
        st,
        fallback: 'The password could not be reset. Try again.',
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
    _debounceTimer?.cancel();
    final pending = _pendingSearch;
    if (pending != null && !pending.isCompleted) pending.complete();
    _requests.invalidate();
    _members = const [];
    _total = 0;
    _statusFilter = null;
    _roleFilter = null;
    _isLoading = false;
    _isLoadingMore = false;
    _isSaving = false;
    _errorMessage = null;
    _actionErrorMessage = null;
    _query = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
