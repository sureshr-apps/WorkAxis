import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/errors/platform_users_failure.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';
import 'package:workaxis/features/platform_users/domain/repositories/platform_users_repository.dart';

/// Production implementation of [PlatformUsersRepository] using Cloud Firestore.
/// Stores platform administrators in the 'users' collection with role 'platformAdmin',
/// and maintains multi-identifier lookup in the 'user_aliases' collection.
class FirestorePlatformUsersRepository implements PlatformUsersRepository {
  FirestorePlatformUsersRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _aliasesCol =>
      _firestore.collection('user_aliases');

  @override
  Future<List<PlatformAdministrator>> getAdministrators({
    String? query,
    AccountStatus? status,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _usersCol.where('role', isEqualTo: 'platformAdmin');

      if (status != null) {
        q = q.where('status', isEqualTo: status.name);
      }

      final snapshot = await q.get();
      var admins = snapshot.docs.map((doc) => _mapDocToAdmin(doc.id, doc.data())).toList();

      if (query != null && query.trim().isNotEmpty) {
        final lower = query.trim().toLowerCase();
        admins = admins.where((a) {
          return a.fullName.toLowerCase().contains(lower) ||
              a.username.toLowerCase().contains(lower) ||
              a.email.toLowerCase().contains(lower) ||
              (a.phone != null && a.phone!.contains(lower));
        }).toList();
      }

      admins.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return admins;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to fetch platform administrators: ${e.toString()}');
    }
  }

  @override
  Future<PlatformAdministrator?> getAdministratorById(String id) async {
    try {
      final doc = await _usersCol.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return _mapDocToAdmin(doc.id, doc.data()!);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to fetch administrator by id: ${e.toString()}');
    }
  }

  @override
  Future<PlatformAdministrator> createAdministrator({
    required PlatformAdministrator administrator,
    required String initialPassword,
  }) async {
    if (administrator.fullName.trim().isEmpty) {
      throw const PlatformUsersFailure('Full name is required.');
    }
    if (administrator.username.trim().isEmpty) {
      throw const PlatformUsersFailure('Username is required.');
    }
    if (administrator.email.trim().isEmpty || !administrator.email.contains('@')) {
      throw const PlatformUsersFailure('A valid email address is required.');
    }

    try {
      final cleanUsername = administrator.username.trim().toLowerCase();
      final cleanEmail = administrator.email.trim().toLowerCase();

      // Check if username alias already exists
      final usernameAliasDoc = await _aliasesCol.doc(cleanUsername).get();
      if (usernameAliasDoc.exists) {
        throw const PlatformUsersFailure('Username is already taken.');
      }

      final docRef = _usersCol.doc(administrator.id.isNotEmpty ? administrator.id : null);
      final id = docRef.id;

      final now = DateTime.now().toUtc();
      final adminToSave = administrator.copyWith(
        createdAt: administrator.createdAt.isBefore(DateTime(2000)) ? now : administrator.createdAt,
      );

      final batch = _firestore.batch();

      batch.set(docRef, {
        'id': id,
        'role': 'platformAdmin',
        'name': adminToSave.fullName.trim(),
        'username': cleanUsername,
        'email': cleanEmail,
        'phone': adminToSave.phone?.trim(),
        'status': adminToSave.status.name,
        'createdAt': Timestamp.fromDate(adminToSave.createdAt),
        'lastActiveAt': adminToSave.lastActiveAt != null
            ? Timestamp.fromDate(adminToSave.lastActiveAt!)
            : null,
      });

      // Maintain multi-identifier username alias
      batch.set(_aliasesCol.doc(cleanUsername), {
        'uid': id,
        'email': cleanEmail,
        'type': 'username',
      });

      // Maintain phone alias if provided
      if (adminToSave.phone != null && adminToSave.phone!.trim().isNotEmpty) {
        final cleanPhone = adminToSave.phone!.trim().replaceAll(RegExp(r'\s+'), '');
        batch.set(_aliasesCol.doc(cleanPhone), {
          'uid': id,
          'email': cleanEmail,
          'type': 'phone',
        });
      }

      await batch.commit();

      return PlatformAdministrator(
        id: id,
        fullName: adminToSave.fullName.trim(),
        username: cleanUsername,
        email: cleanEmail,
        phone: adminToSave.phone?.trim(),
        status: adminToSave.status,
        createdAt: adminToSave.createdAt,
        lastActiveAt: adminToSave.lastActiveAt,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      if (e is PlatformUsersFailure) rethrow;
      throw DatabaseException('Failed to create platform administrator: ${e.toString()}');
    }
  }

  @override
  Future<PlatformAdministrator> updateAdministrator(
    PlatformAdministrator administrator,
  ) async {
    try {
      final docRef = _usersCol.doc(administrator.id);
      final existingDoc = await docRef.get();
      if (!existingDoc.exists) {
        throw NotFoundException('Administrator with ID "${administrator.id}" not found.');
      }

      await docRef.update({
        'name': administrator.fullName.trim(),
        'phone': administrator.phone?.trim(),
        'status': administrator.status.name,
      });

      return administrator;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to update platform administrator: ${e.toString()}');
    }
  }

  @override
  Future<PlatformAdministrator> updateAdministratorStatus(
    String id,
    AccountStatus status,
  ) async {
    try {
      final docRef = _usersCol.doc(id);
      final existingDoc = await docRef.get();
      if (!existingDoc.exists || existingDoc.data() == null) {
        throw NotFoundException('Administrator with ID "$id" not found.');
      }

      await docRef.update({'status': status.name});

      final admin = _mapDocToAdmin(id, existingDoc.data()!);
      return admin.copyWith(status: status);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to update administrator status: ${e.toString()}');
    }
  }

  PlatformAdministrator _mapDocToAdmin(String id, Map<String, dynamic> data) {
    final statusStr = data['status'] as String? ?? 'active';
    final status = AccountStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == statusStr.toLowerCase(),
      orElse: () => AccountStatus.active,
    );

    final createdAtRaw = data['createdAt'];
    final DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    final lastActiveRaw = data['lastActiveAt'];
    DateTime? lastActiveAt;
    if (lastActiveRaw is Timestamp) {
      lastActiveAt = lastActiveRaw.toDate();
    } else if (lastActiveRaw is String) {
      lastActiveAt = DateTime.tryParse(lastActiveRaw);
    }

    return PlatformAdministrator(
      id: id,
      fullName: data['name'] as String? ?? data['fullName'] as String? ?? 'Administrator',
      username: data['username'] as String? ?? id,
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      status: status,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt,
    );
  }
}
