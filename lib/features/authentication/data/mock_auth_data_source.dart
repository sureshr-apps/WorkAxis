import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/app_user.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Internal record holding mock credentials alongside user identity.
class MockAccountRecord {
  const MockAccountRecord({required this.user, required this.password});

  final AppUser user;
  final String password;
}

/// In-memory mock data source for representative users across all supported roles.
class MockAuthDataSource {
  MockAuthDataSource() {
    _initRecords();
  }

  final Map<String, MockAccountRecord> _recordsByUserId = {};

  void _initRecords() {
    final records = <MockAccountRecord>[
      // Platform Owner
      const MockAccountRecord(
        user: AppUser(
          id: 'user-po-01',
          name: 'Alex Rivera',
          username: 'owner',
          email: 'owner@workaxis.io',
          phone: '+15550001',
          role: UserRole.platformOwner,
        ),
        password: 'Password123!',
      ),

      // Platform Administrator
      const MockAccountRecord(
        user: AppUser(
          id: 'user-pa-01',
          name: 'Jordan Vance',
          username: 'platformadmin',
          email: 'admin@platform.workaxis.io',
          phone: '+15550002',
          role: UserRole.platformAdmin,
        ),
        password: 'Password123!',
      ),

      // Organization Admin (Apex Logistics & Freight)
      const MockAccountRecord(
        user: AppUser(
          id: 'user-oa-01',
          name: 'Marcus Sterling',
          username: 'orgadmin',
          email: 'admin@acme.com',
          phone: '+15550003',
          role: UserRole.orgAdmin,
          organizationId: 'org-acme',
        ),
        password: 'Password123!',
      ),

      // Branch Manager with MULTIPLE assigned branches
      const MockAccountRecord(
        user: AppUser(
          id: 'user-bm-multi-01',
          name: 'Marcus Chen',
          username: 'manager_multi',
          email: 'manager.multi@acme.com',
          phone: '+15550004',
          role: UserRole.branchManager,
          organizationId: 'org-acme',
        ),
        password: 'Password123!',
      ),

      // Branch Manager with SINGLE assigned branch
      const MockAccountRecord(
        user: AppUser(
          id: 'user-bm-single-01',
          name: 'Sophia Patel',
          username: 'manager_single',
          email: 'manager.single@acme.com',
          phone: '+15550005',
          role: UserRole.branchManager,
          organizationId: 'org-acme',
        ),
        password: 'Password123!',
      ),

      // Frontline Employee
      const MockAccountRecord(
        user: AppUser(
          id: 'user-emp-01',
          name: 'Sarah Connor',
          username: 'employee',
          email: 'sarah.chen@acme.com',
          phone: '+15550006',
          role: UserRole.employee,
          organizationId: 'org-acme',
        ),
        password: 'Password123!',
      ),

      // Disabled / Inactive Account for error verification
      const MockAccountRecord(
        user: AppUser(
          id: 'user-disabled-01',
          name: 'Deactivated User',
          username: 'disabled_user',
          email: 'disabled@acme.com',
          phone: '+15550007',
          role: UserRole.employee,
          organizationId: 'org-acme',
          status: AccountStatus.disabled,
        ),
        password: 'Password123!',
      ),
    ];

    for (final record in records) {
      _recordsByUserId[record.user.id] = record;
    }
  }

  /// Resolves an account record by checking username, email, or phone.
  MockAccountRecord? findByIdentifier(String rawIdentifier) {
    final cleanIdentifier = rawIdentifier.trim().toLowerCase();
    final normalized = switch (cleanIdentifier) {
      'platformowner' || 'platform_owner' => 'owner',
      'manager' => 'manager_multi',
      _ => cleanIdentifier,
    };
    for (final record in _recordsByUserId.values) {
      final user = record.user;
      if (user.username.toLowerCase() == normalized ||
          user.username.toLowerCase() == cleanIdentifier) {
        return record;
      }
      if (user.email != null && user.email!.toLowerCase() == cleanIdentifier) {
        return record;
      }
      if (user.phone != null && user.phone!.trim() == rawIdentifier.trim()) {
        return record;
      }
    }
    return null;
  }

  AppUser? findById(String id) => _recordsByUserId[id]?.user;
}
