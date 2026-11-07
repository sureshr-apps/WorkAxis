import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/data/mock_auth_data_source.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';

/// In-memory fixtures for Platform Administrator management.
class MockPlatformUsersDataSource {
  MockPlatformUsersDataSource({
    DateTime? now,
    MockAuthDataSource? authDataSource,
  }) : _now = now ?? DateTime.now(),
       _authDataSource = authDataSource ?? MockAuthDataSource() {
    _administrators.addAll(_defaultAdministrators(_now));
  }

  final DateTime _now;
  final MockAuthDataSource _authDataSource;
  final List<PlatformAdministrator> _administrators = [];
  int _nextId = 1;

  List<PlatformAdministrator> getAdministrators({
    String? query,
    AccountStatus? status,
  }) {
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    return _administrators
        .where((administrator) {
          if (status != null && administrator.status != status) return false;
          if (normalizedQuery.isEmpty) return true;
          return administrator.fullName.toLowerCase().contains(
                normalizedQuery,
              ) ||
              administrator.username.toLowerCase().contains(normalizedQuery) ||
              administrator.email.toLowerCase().contains(normalizedQuery) ||
              (administrator.phone?.toLowerCase().contains(normalizedQuery) ??
                  false);
        })
        .toList(growable: false);
  }

  int count({AccountStatus? status}) =>
      _administrators.where((a) => status == null || a.status == status).length;

  PlatformAdministrator? getById(String id) {
    for (final administrator in _administrators) {
      if (administrator.id == id) return administrator;
    }
    return null;
  }

  PlatformAdministrator create(PlatformAdministrator administrator) {
    _ensureUniqueIdentifiers(administrator);
    final id = 'platform-admin-${_nextId++}';
    final created = PlatformAdministrator(
      id: id,
      authUid: id,
      fullName: administrator.fullName.trim(),
      username: administrator.username.trim(),
      email: administrator.email.trim().toLowerCase(),
      phone: _normalizePhone(administrator.phone),
      status: AccountStatus.active,
      createdAt: _now,
      lastActiveAt: null,
    );
    _administrators.insert(0, created);
    return created;
  }

  PlatformAdministrator update(PlatformAdministrator updated) {
    final index = _administrators.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      throw ValidationException('Administrator not found.');
    }
    final current = _administrators[index];
    // The username is the login handle and cannot change after creation.
    _ensureUniqueIdentifiers(
      updated.copyWith(username: current.username),
      exceptId: updated.id,
    );
    final saved = updated.copyWith(
      fullName: updated.fullName.trim(),
      username: current.username,
      email: updated.email.trim().toLowerCase(),
      phone: _normalizePhone(updated.phone),
      status: current.status,
      createdAt: current.createdAt,
      lastActiveAt: current.lastActiveAt,
    );
    _administrators[index] = saved;
    return saved;
  }

  PlatformAdministrator updateStatus(String id, AccountStatus status) {
    final index = _administrators.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw ValidationException('Administrator not found.');
    }
    final updated = _administrators[index].copyWith(status: status);
    _administrators[index] = updated;
    return updated;
  }

  void _ensureUniqueIdentifiers(
    PlatformAdministrator candidate, {
    String? exceptId,
  }) {
    final duplicatePlatformUser = _administrators.any((item) {
      if (item.id == exceptId) return false;
      return item.username.toLowerCase() == candidate.username.toLowerCase() ||
          (candidate.email.isNotEmpty &&
              item.email.toLowerCase() == candidate.email.toLowerCase()) ||
          (candidate.phone?.trim().isNotEmpty ?? false) &&
              item.phone?.trim() == candidate.phone?.trim();
    });
    final candidateIdentifiers = [
      candidate.username.trim(),
      candidate.email.trim(),
      if (candidate.phone?.trim().isNotEmpty ?? false) candidate.phone!.trim(),
    ];
    final duplicateExistingAccount = candidateIdentifiers.any(
      (identifier) => _authDataSource.findByIdentifier(identifier) != null,
    );
    if (duplicatePlatformUser || duplicateExistingAccount) {
      throw ValidationException(
        'That username, email, or phone number is already used by another user.',
      );
    }
  }

  String? _normalizePhone(String? phone) {
    final normalized = phone?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  List<PlatformAdministrator> _defaultAdministrators(DateTime now) => [
    PlatformAdministrator(
      id: 'pa-david-warner',
      fullName: 'David Warner',
      username: 'dwarner',
      email: 'd.warner@workaxis.example',
      phone: '+1 (202) 555-0148',
      status: AccountStatus.active,
      createdAt: DateTime(2025, 7, 14),
      lastActiveAt: now.subtract(const Duration(minutes: 14)),
    ),
    PlatformAdministrator(
      id: 'pa-elena-lindqvist',
      fullName: 'Elena Lindqvist',
      username: 'elindqvist',
      email: 'e.lindqvist@workaxis.example',
      phone: '+1 (202) 555-0182',
      status: AccountStatus.active,
      createdAt: DateTime(2025, 8, 9),
      lastActiveAt: now.subtract(const Duration(hours: 3)),
    ),
    PlatformAdministrator(
      id: 'pa-marcus-sterling',
      fullName: 'Marcus Sterling',
      username: 'msterling',
      email: 'm.sterling@workaxis.example',
      phone: '+1 (202) 555-0193',
      status: AccountStatus.active,
      createdAt: DateTime(2025, 9, 21),
      lastActiveAt: now.subtract(const Duration(days: 1)),
    ),
    PlatformAdministrator(
      id: 'pa-devendra-patel',
      fullName: 'Devendra Patel',
      username: 'dpatel',
      email: 'd.patel@workaxis.example',
      phone: '+1 (202) 555-0116',
      status: AccountStatus.suspended,
      createdAt: DateTime(2025, 11, 4),
      lastActiveAt: now.subtract(const Duration(days: 18)),
    ),
  ];
}
