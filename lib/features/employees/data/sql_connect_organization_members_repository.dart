import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/core/backend/account_callables.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/ids/request_ids.dart';
import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';
import 'package:workaxis/core/storage/attachment_uploader.dart';
import 'package:workaxis/core/validation/contact_validators.dart';
import 'package:workaxis/core/validation/login_email.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/data/organization_members_remote_data_source.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/policies/organization_member_policy.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';

/// Production [OrganizationMembersRepository].
///
/// Reads come from the data gateway (server-side filters and pagination); every
/// identity write goes through the account callables. Nothing is written to
/// SQL, Auth or Firestore directly from the client.
class SqlConnectOrganizationMembersRepository
    implements OrganizationMembersRepository {
  SqlConnectOrganizationMembersRepository({
    required this.dataSource,
    required this.accounts,
    this.firestore,
    this.attachments,
  });

  final OrganizationMembersRemoteDataSource dataSource;
  final AccountCallables accounts;
  final FirebaseFirestore? firestore;

  /// Uploads picked photos before a save. Null skips uploading (unit tests).
  final AttachmentUploader? attachments;

  /// Idempotency keys for in-flight creates, so retrying the same draft
  /// reuses the `requestId` (server ledger replays instead of duplicating).
  final Map<String, String> _pendingRequestIds = {};

  @override
  Future<PageResult<OrganizationMember>> getMembersPage({
    required UserAccessContext access,
    String? activeBranchId,
    String? query,
    AccountStatus? status,
    UserRole? role,
    int offset = 0,
    int limit = defaultPageSize,
  }) async {
    try {
      OrganizationMemberPolicy.assertCanViewMembers(access);
      final orgId = OrganizationMemberPolicy.requireOrganizationId(access);
      final branchId = OrganizationMemberPolicy.effectiveBranchId(
        access,
        activeBranchId,
      );
      final name = query?.trim();
      // Branch managers list employees only; they never see managers.
      final scopedRole = access.user.role == UserRole.branchManager
          ? UserRole.employee
          : role;
      final PageResult<OrganizationMember> page;
      if (branchId == null) {
        page = await dataSource.listByOrganization(
          organizationId: orgId,
          limit: limit,
          offset: offset,
          nameContains: name,
          status: status,
          role: scopedRole,
        );
      } else {
        page = await dataSource.listByBranch(
          organizationId: orgId,
          branchId: branchId,
          limit: limit,
          offset: offset,
          nameContains: name,
          status: status,
          role: scopedRole,
        );
      }
      final enriched = await _enrichWithProfiles(
        access,
        page.items,
        activeBranchId: branchId,
      );
      return PageResult(
        items: enriched,
        total: page.total,
        offset: page.offset,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<OrganizationMember?> getMember({
    required UserAccessContext access,
    required String memberId,
    String? activeBranchId,
  }) async {
    try {
      OrganizationMemberPolicy.assertCanViewMembers(access);
      final orgId = OrganizationMemberPolicy.requireOrganizationId(access);
      final member = await dataSource.getById(memberId);
      if (member == null || member.organizationId != orgId) return null;
      if (access.user.role == UserRole.branchManager) {
        final branch = OrganizationMemberPolicy.effectiveBranchId(
          access,
          activeBranchId,
        );
        if (!OrganizationMemberPolicy.isVisibleToBranchManager(
          member,
          branch,
        )) {
          return null;
        }
      }
      return await _enrichSingle(
        access,
        member,
        activeBranchId: activeBranchId,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<OrganizationMember> saveMember({
    required UserAccessContext access,
    required OrganizationMember member,
    required String initialPassword,
    String? activeBranchId,
  }) async {
    try {
      final withStoredPhotos = await _withStoredPhotos(access, member);
      return member.id.isEmpty
          ? await _create(
              access,
              withStoredPhotos,
              initialPassword,
              activeBranchId,
            )
          : await _update(access, withStoredPhotos, activeBranchId);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  /// Replaces freshly picked local image paths with stored references so a
  /// device path is never persisted as if it were a shareable URL.
  Future<OrganizationMember> _withStoredPhotos(
    UserAccessContext access,
    OrganizationMember member,
  ) async {
    final uploader = attachments;
    if (uploader == null) return member;
    final orgId = OrganizationMemberPolicy.requireOrganizationId(access);
    final profile = await uploader.ensureStored(
      member.profilePhotoUrl,
      organizationId: orgId,
      kind: AttachmentKind.profilePhoto,
    );
    final aadhaar = await uploader.ensureStored(
      member.aadhaarPhotoUrl,
      organizationId: orgId,
      kind: AttachmentKind.aadhaarDocument,
    );
    return member.copyWith(profilePhotoUrl: profile, aadhaarPhotoUrl: aadhaar);
  }

  @override
  Future<OrganizationMember> setMemberStatus({
    required UserAccessContext access,
    required OrganizationMember member,
    required AccountStatus status,
    String? activeBranchId,
  }) async {
    try {
      final existing = await _loadExisting(
        access,
        member.id,
        activeBranchId: activeBranchId,
      );
      OrganizationMemberPolicy.assertCanChangeStatus(
        access: access,
        existing: existing,
        activeBranchId: activeBranchId,
      );
      await accounts.setStatus(
        targetUid: _requireUid(existing),
        status: status,
      );
      return await _reload(access, existing.id, activeBranchId: activeBranchId);
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<void> deleteMember({
    required UserAccessContext access,
    required OrganizationMember member,
    String? activeBranchId,
  }) async {
    try {
      final existing = await _loadExisting(
        access,
        member.id,
        activeBranchId: activeBranchId,
      );
      OrganizationMemberPolicy.assertCanDelete(
        access: access,
        existing: existing,
        activeBranchId: activeBranchId,
      );
      final uid = _requireUid(existing);
      if (existing.role == UserRole.orgAdmin) {
        await accounts.deleteOrganizationAdmin(targetUid: uid);
      } else {
        await accounts.deleteOrganizationMember(targetUid: uid);
      }
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<void> resetMemberPassword({
    required UserAccessContext access,
    required OrganizationMember member,
    required String newPassword,
    String? activeBranchId,
  }) async {
    try {
      final passwordError = ContactValidators.password(newPassword);
      if (passwordError != null) throw ValidationException(passwordError);
      final existing = await _loadExisting(
        access,
        member.id,
        activeBranchId: activeBranchId,
      );
      OrganizationMemberPolicy.assertCanResetPassword(
        access: access,
        existing: existing,
        activeBranchId: activeBranchId,
      );
      await accounts.resetPassword(
        targetUid: _requireUid(existing),
        newPassword: newPassword,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  Future<OrganizationMember> _create(
    UserAccessContext access,
    OrganizationMember draft,
    String password,
    String? activeBranchId,
  ) async {
    final prepared = OrganizationMemberPolicy.prepareCreate(
      access: access,
      draft: draft,
      initialPassword: password,
      activeBranchId: activeBranchId,
    );
    final key = '${prepared.organizationId}|${prepared.username}';
    final requestId = _pendingRequestIds.putIfAbsent(key, RequestIds.uuidV4);
    final result = await accounts.provision(
      requestId: requestId,
      fullName: prepared.fullName,
      username: prepared.username,
      email: prepared.email,
      phone: prepared.phone,
      password: password,
      role: prepared.role,
      organizationId: prepared.organizationId,
      branchIds: prepared.branchIds,
      dailyWorkHours: prepared.dailyWorkHours,
      shiftHours: prepared.shiftHours,
      weeklyDayOff: prepared.weeklyDayOff,
      employeeCode: prepared.employeeCode,
      aadhaarNumber: prepared.aadhaarNumber,
      aadhaarPhotoUrl: prepared.aadhaarPhotoUrl,
      dateOfBirth: prepared.dateOfBirth,
      gender: prepared.gender,
      address: prepared.address,
      profilePhotoUrl: prepared.profilePhotoUrl,
      designation: prepared.designation,
      joiningDate: prepared.joiningDate,
      relievingDate: prepared.relievingDate,
      salary: prepared.salary,
      assetDetails: prepared.assetDetails,
    );
    _pendingRequestIds.remove(key);
    return prepared.copyWith(
      id: result.memberId,
      authUid: result.uid,
      email: LoginEmail.displayable(result.loginEmail),
      employeeCode: result.employeeCode ?? prepared.employeeCode,
      status: AccountStatus.active,
    );
  }

  Future<OrganizationMember> _update(
    UserAccessContext access,
    OrganizationMember draft,
    String? activeBranchId,
  ) async {
    final existing = await _loadExisting(
      access,
      draft.id,
      activeBranchId: activeBranchId,
    );
    final next = OrganizationMemberPolicy.prepareUpdate(
      access: access,
      existing: existing,
      draft: draft,
      activeBranchId: activeBranchId,
    );
    final uid = _requireUid(existing);

    final sameBranches =
        {...existing.branchIds}.difference({...next.branchIds}).isEmpty &&
        {...next.branchIds}.difference({...existing.branchIds}).isEmpty;
    final hadPhone = (existing.phone ?? '').isNotEmpty;
    final nextPhone = next.phone ?? '';
    await accounts.update(
      targetUid: uid,
      fullName: next.fullName,
      email: next.email != existing.email ? next.email : null,
      clearEmail: next.email.trim().isEmpty && next.email != existing.email,
      phone: nextPhone.isNotEmpty && nextPhone != existing.phone
          ? nextPhone
          : null,
      clearPhone: hadPhone && nextPhone.isEmpty,
      role: next.role != existing.role ? next.role : null,
      branchIds: sameBranches ? null : next.branchIds,
      employeeCode: next.employeeCode != existing.employeeCode
          ? next.employeeCode
          : null,
      aadhaarNumber: next.aadhaarNumber != existing.aadhaarNumber
          ? next.aadhaarNumber
          : null,
      aadhaarPhotoUrl: next.aadhaarPhotoUrl != existing.aadhaarPhotoUrl
          ? next.aadhaarPhotoUrl
          : null,
      dateOfBirth: next.dateOfBirth != existing.dateOfBirth
          ? next.dateOfBirth
          : null,
      gender: next.gender != existing.gender ? next.gender : null,
      address: next.address != existing.address ? next.address : null,
      profilePhotoUrl: next.profilePhotoUrl != existing.profilePhotoUrl
          ? next.profilePhotoUrl
          : null,
      designation: next.designation != existing.designation
          ? next.designation
          : null,
      joiningDate: next.joiningDate != existing.joiningDate
          ? next.joiningDate
          : null,
      relievingDate: next.relievingDate != existing.relievingDate
          ? next.relievingDate
          : null,
      clear: _clearedFields(existing, next),
      assetDetails: next.assetDetails != existing.assetDetails
          ? next.assetDetails
          : null,
    );
    if (draft.status != existing.status) {
      OrganizationMemberPolicy.assertCanChangeStatus(
        access: access,
        existing: existing,
        activeBranchId: activeBranchId,
      );
      await accounts.setStatus(targetUid: uid, status: draft.status);
    }
    return _reload(access, existing.id, activeBranchId: activeBranchId);
  }

  /// Optional fields the user emptied. A clear is sent only when the stored
  /// value was known and non-empty: values the caller could not read (such as
  /// private data outside a Branch Manager's branch) load as null, so they stay
  /// omitted instead of being wiped.
  Set<ClearableProfileField> _clearedFields(
    OrganizationMember existing,
    OrganizationMember next,
  ) {
    bool had(String? v) => v != null && v.isNotEmpty;
    return {
      if (had(existing.aadhaarNumber) && next.aadhaarNumber == null)
        ClearableProfileField.aadhaarNumber,
      if (had(existing.aadhaarPhotoUrl) && next.aadhaarPhotoUrl == null)
        ClearableProfileField.aadhaarPhotoUrl,
      if (existing.dateOfBirth != null && next.dateOfBirth == null)
        ClearableProfileField.dateOfBirth,
      if (had(existing.gender) && next.gender == null)
        ClearableProfileField.gender,
      if (had(existing.address) && next.address == null)
        ClearableProfileField.address,
      if (had(existing.profilePhotoUrl) && next.profilePhotoUrl == null)
        ClearableProfileField.profilePhotoUrl,
      if (had(existing.designation) && next.designation == null)
        ClearableProfileField.designation,
      if (existing.joiningDate != null && next.joiningDate == null)
        ClearableProfileField.joiningDate,
      if (existing.relievingDate != null && next.relievingDate == null)
        ClearableProfileField.relievingDate,
      if (existing.salary != null && next.salary == null)
        ClearableProfileField.salary,
      if (had(existing.assetDetails) && next.assetDetails == null)
        ClearableProfileField.assetDetails,
    };
  }

  Future<OrganizationMember> _loadExisting(
    UserAccessContext access,
    String memberId, {
    String? activeBranchId,
  }) async {
    final orgId = OrganizationMemberPolicy.requireOrganizationId(access);
    final existing = await dataSource.getById(memberId);
    if (existing == null || existing.organizationId != orgId) {
      throw const NotFoundException('Member not found in caller organization');
    }
    return _enrichSingle(access, existing, activeBranchId: activeBranchId);
  }

  Future<OrganizationMember> _reload(
    UserAccessContext access,
    String id, {
    String? activeBranchId,
  }) async {
    final saved = await dataSource.getById(id);
    if (saved == null) throw const NotFoundException('Member not found');
    return await _enrichSingle(access, saved, activeBranchId: activeBranchId);
  }

  Future<List<OrganizationMember>> _enrichWithProfiles(
    UserAccessContext access,
    List<OrganizationMember> members, {
    String? activeBranchId,
  }) async {
    final db = firestore;
    if (db == null || members.isEmpty) return members;
    return Future.wait(
      members.map((member) {
        final uid = member.authUid;
        if (uid == null || uid.isEmpty) return Future.value(member);
        return _enrichOne(
          db,
          member,
          uid,
          canReadPrivate: _canReadPrivate(
            access,
            member,
            activeBranchId: activeBranchId,
          ),
        );
      }),
    );
  }

  Future<OrganizationMember> _enrichSingle(
    UserAccessContext access,
    OrganizationMember member, {
    String? activeBranchId,
  }) async {
    final db = firestore;
    final uid = member.authUid;
    if (db == null || uid == null || uid.isEmpty) return member;
    return _enrichOne(
      db,
      member,
      uid,
      canReadPrivate: _canReadPrivate(
        access,
        member,
        activeBranchId: activeBranchId,
      ),
    );
  }

  bool _canReadPrivate(
    UserAccessContext access,
    OrganizationMember member, {
    String? activeBranchId,
  }) {
    if (member.organizationId != access.organization?.id) return false;
    if (access.user.role == UserRole.orgAdmin ||
        member.authUid == access.user.id ||
        member.id == access.user.id) {
      return true;
    }
    if (access.user.role != UserRole.branchManager ||
        member.role != UserRole.employee ||
        activeBranchId == null ||
        !member.branchIds.contains(activeBranchId)) {
      return false;
    }
    return access.assignedBranches.any(
      (branch) => branch.id == activeBranchId && branch.isActive,
    );
  }

  Future<OrganizationMember> _enrichOne(
    FirebaseFirestore db,
    OrganizationMember member,
    String uid, {
    required bool canReadPrivate,
  }) async {
    final profileFuture = db.collection('users').doc(uid).get();
    final privateFuture = canReadPrivate
        ? _readPrivate(db, uid)
        : Future<Map<String, dynamic>?>.value(null);
    final profile = await profileFuture;
    final private = await privateFuture;
    var enriched = member;
    final data = profile.data();
    if (profile.exists && data != null) {
      enriched = _applyProfileData(enriched, data);
    }
    return private == null ? enriched : _applyPrivateData(enriched, private);
  }

  /// Sensitive HR data (salary, Aadhaar). The employee, their Org Admin, and
  /// the active Branch Manager for an assigned employee branch may read it.
  Future<Map<String, dynamic>?> _readPrivate(
    FirebaseFirestore db,
    String uid,
  ) async {
    final snap = await db.collection('employee_private').doc(uid).get();
    return snap.exists ? snap.data() : null;
  }

  OrganizationMember _applyPrivateData(
    OrganizationMember member,
    Map<String, dynamic> data,
  ) {
    return member.copyWith(
      aadhaarNumber: data['aadhaarNumber'] as String?,
      aadhaarPhotoUrl: data['aadhaarPhotoUrl'] as String?,
    );
  }

  OrganizationMember _applyProfileData(
    OrganizationMember member,
    Map<String, dynamic> data,
  ) {
    DateTime? parseDate(dynamic val) {
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
      if (val is Timestamp) return val.toDate();
      return null;
    }

    return member.copyWith(
      dateOfBirth: parseDate(data['dateOfBirth']),
      gender: data['gender'] as String?,
      address: data['address'] as String?,
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      designation: data['designation'] as String?,
      joiningDate: parseDate(data['joiningDate']),
      relievingDate: parseDate(data['relievingDate']),
      assetDetails: data['assetDetails'] as String?,
    );
  }

  String _requireUid(OrganizationMember member) {
    final uid = member.authUid;
    if (uid == null || uid.isEmpty) {
      throw ValidationException(
        'This account has no sign-in identity yet and cannot be changed here.',
      );
    }
    return uid;
  }
}
