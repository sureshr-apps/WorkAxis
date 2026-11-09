import 'package:workaxis/core/backend/callable_functions.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/data/organization_members_remote_data_source.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/platform_users/data/platform_users_remote_data_source.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';

/// One recorded callable invocation.
class CallableCall {
  const CallableCall(this.name, this.payload);

  final String name;
  final Map<String, dynamic> payload;
}

/// In-memory stand-in for the identity backend (SQL members plus the account
/// callables). It never authorizes: authorization is the server's job and the
/// client policies are what these tests exercise.
///
/// It does enforce what the real database/functions do for uniqueness and
/// idempotency, so repositories can be tested end to end without Firebase.
class FakeIdentityServer implements CallableFunctions {
  FakeIdentityServer(Iterable<OrganizationMember> seed) {
    for (final member in seed) {
      _rows[member.id] = member;
      _nextNumber++;
    }
  }

  final Map<String, OrganizationMember> _rows = {};
  final Map<String, Map<String, dynamic>> _provisioned = {};
  final Map<String, DateTime> _createdAt = {};
  final List<CallableCall> calls = [];
  int _nextNumber = 1;

  /// When set, the next callable invocation throws this error once.
  Object? failNextCallWith;

  OrganizationMember? byId(String id) => _rows[id];
  List<OrganizationMember> get all => _rows.values.toList(growable: false);
  Iterable<CallableCall> callsTo(String name) =>
      calls.where((c) => c.name == name);

  void applyBranchAssignments(Map<String, List<String>> changes) {
    for (final entry in changes.entries) {
      _rows[entry.key] = _rows[entry.key]!.copyWith(branchIds: entry.value);
    }
  }

  @override
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> payload = const {},
  ]) async {
    calls.add(CallableCall(name, Map.of(payload)));
    final failure = failNextCallWith;
    if (failure != null) {
      failNextCallWith = null;
      throw failure;
    }
    switch (name) {
      case 'provisionUser':
        return _provision(payload);
      case 'updateUserAccount':
        return _update(payload);
      case 'setUserStatus':
        return _setStatus(payload);
      case 'resetUserPassword':
        return {'uid': payload['targetUid']};
      default:
        throw DatabaseException('Unknown callable $name');
    }
  }

  Map<String, dynamic> _provision(Map<String, dynamic> p) {
    final requestId = p['requestId'] as String;
    final replay = _provisioned[requestId];
    if (replay != null) return replay;

    final username = (p['username'] as String).toLowerCase();
    final email = (p['email'] as String?)?.toLowerCase();
    final phone = p['phone'] as String?;
    _assertUnique(username: username, email: email, phone: phone);

    final id = 'srv-member-${_nextNumber++}';
    final uid = 'srv-uid-$id';
    final role = UserRole.values.byName(p['role'] as String);
    final loginEmail = email ?? '$username@login.workaxis.invalid';
    _rows[id] = OrganizationMember(
      id: id,
      authUid: uid,
      organizationId: (p['organizationId'] as String?) ?? '',
      fullName: p['fullName'] as String,
      username: username,
      email: loginEmail,
      phone: phone,
      role: role,
      branchIds: List<String>.from(p['branchIds'] as List? ?? const []),
      status: AccountStatus.active,
    );
    _createdAt[id] = DateTime.utc(
      2026,
      1,
      1,
    ).add(Duration(minutes: _nextNumber));
    final response = {
      'uid': uid,
      'memberId': id,
      'username': username,
      'loginEmail': loginEmail,
    };
    _provisioned[requestId] = response;
    return response;
  }

  Map<String, dynamic> _update(Map<String, dynamic> p) {
    final existing = _byUid(p['targetUid'] as String);
    final email = p.containsKey('email') && p['email'] == null
        ? ''
        : p['email'] as String?;
    final phone = p['phone'] as String?;
    _assertUnique(
      username: null,
      email: email?.toLowerCase(),
      phone: phone,
      exceptId: existing.id,
    );
    _rows[existing.id] = existing.copyWith(
      fullName: p['fullName'] as String?,
      email: email?.toLowerCase(),
      phone: phone,
      clearPhone: p.containsKey('phone') && p['phone'] == null,
      role: p['role'] == null
          ? null
          : UserRole.values.byName(p['role'] as String),
      branchIds: p['branchIds'] == null
          ? null
          : List<String>.from(p['branchIds'] as List),
    );
    return {'uid': existing.authUid};
  }

  Map<String, dynamic> _setStatus(Map<String, dynamic> p) {
    final existing = _byUid(p['targetUid'] as String);
    final status = p['status'] == 'active'
        ? AccountStatus.active
        : AccountStatus.suspended;
    _rows[existing.id] = existing.copyWith(status: status);
    return {'uid': existing.authUid, 'status': p['status']};
  }

  OrganizationMember _byUid(String uid) {
    final match = _rows.values.where((m) => m.authUid == uid).firstOrNull;
    if (match == null) throw const NotFoundException('No such account');
    return match;
  }

  void _assertUnique({
    String? username,
    String? email,
    String? phone,
    String? exceptId,
  }) {
    for (final m in _rows.values) {
      if (m.id == exceptId) continue;
      if ((username != null && m.username == username) ||
          (email != null && email.isNotEmpty && m.email == email) ||
          (phone != null && phone.isNotEmpty && m.phone == phone)) {
        throw const DatabaseException(
          'already-exists',
          userMessage: 'That username, email or phone is already in use.',
        );
      }
    }
  }

  DateTime createdAtOf(String id) => _createdAt[id] ?? DateTime.utc(2025, 1, 1);
}

/// [OrganizationMembersRemoteDataSource] over a [FakeIdentityServer].
class FakeMembersDataSource implements OrganizationMembersRemoteDataSource {
  FakeMembersDataSource(this.server);

  final FakeIdentityServer server;
  Object? failWith;

  void _maybeFail() {
    final f = failWith;
    if (f != null) throw f;
  }

  @override
  Future<PageResult<OrganizationMember>> listByOrganization({
    required String organizationId,
    required int limit,
    required int offset,
    String? nameContains,
    AccountStatus? status,
    UserRole? role,
  }) async {
    _maybeFail();
    final rows = server.all.where((m) {
      if (m.organizationId != organizationId) return false;
      if (status != null && m.status != status) return false;
      if (role != null && m.role != role) return false;
      return _nameMatches(m, nameContains);
    }).toList()..sort((a, b) => a.fullName.compareTo(b.fullName));
    return _page(rows, limit, offset);
  }

  @override
  Future<PageResult<OrganizationMember>> listByBranch({
    required String organizationId,
    required String branchId,
    required int limit,
    required int offset,
    String? nameContains,
    AccountStatus? status,
  }) async {
    _maybeFail();
    final rows = server.all.where((m) {
      if (m.organizationId != organizationId) return false;
      if (!m.branchIds.contains(branchId)) return false;
      if (status != null && m.status != status) return false;
      return _nameMatches(m, nameContains);
    }).toList()..sort((a, b) => a.fullName.compareTo(b.fullName));
    return _page(rows, limit, offset);
  }

  @override
  Future<OrganizationMember?> getById(String memberId) async {
    _maybeFail();
    return server.byId(memberId);
  }

  bool _nameMatches(OrganizationMember m, String? q) =>
      q == null ||
      q.isEmpty ||
      m.fullName.toLowerCase().contains(q.toLowerCase());

  PageResult<OrganizationMember> _page(
    List<OrganizationMember> rows,
    int limit,
    int offset,
  ) {
    final start = offset.clamp(0, rows.length);
    final end = (offset + limit).clamp(0, rows.length);
    return PageResult(
      items: rows
          .sublist(start, end)
          .map(_hideSynthetic)
          .toList(growable: false),
      total: rows.length,
      offset: start,
    );
  }

  OrganizationMember _hideSynthetic(OrganizationMember m) =>
      m.copyWith(email: LoginEmail.displayable(m.email));
}

/// [PlatformUsersRemoteDataSource] over a [FakeIdentityServer].
class FakePlatformUsersDataSource implements PlatformUsersRemoteDataSource {
  FakePlatformUsersDataSource(this.server);

  final FakeIdentityServer server;

  Iterable<OrganizationMember> _admins({
    String? nameContains,
    AccountStatus? status,
  }) => server.all.where(
    (m) =>
        m.role == UserRole.platformAdmin &&
        (status == null || m.status == status) &&
        (nameContains == null ||
            nameContains.isEmpty ||
            m.fullName.toLowerCase().contains(nameContains.toLowerCase())),
  );

  PlatformAdministrator _map(OrganizationMember m) => PlatformAdministrator(
    id: m.id,
    authUid: m.authUid,
    fullName: m.fullName,
    username: m.username,
    email: LoginEmail.displayable(m.email),
    phone: m.phone,
    status: m.status,
    createdAt: server.createdAtOf(m.id),
  );

  @override
  Future<PageResult<PlatformAdministrator>> listPage({
    required int limit,
    required int offset,
    String? nameContains,
    AccountStatus? status,
  }) async {
    final rows = _admins(nameContains: nameContains, status: status).toList()
      ..sort(
        (a, b) => server.createdAtOf(b.id).compareTo(server.createdAtOf(a.id)),
      );
    final start = offset.clamp(0, rows.length);
    final end = (offset + limit).clamp(0, rows.length);
    return PageResult(
      items: rows.sublist(start, end).map(_map).toList(growable: false),
      total: rows.length,
      offset: start,
    );
  }

  @override
  Future<int> count({AccountStatus? status}) async =>
      _admins(status: status).length;

  @override
  Future<PlatformAdministrator?> getById(String id) async {
    final m = server.byId(id);
    if (m == null || m.role != UserRole.platformAdmin) return null;
    return _map(m);
  }
}
