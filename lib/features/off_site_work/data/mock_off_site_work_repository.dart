import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/ids/request_ids.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employee_home/domain/services/attendance_location_provider.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/domain/repositories/organization_members_repository.dart';
import 'package:workaxis/features/off_site_work/domain/models/off_site_work_assignment.dart';
import 'package:workaxis/features/off_site_work/domain/repositories/off_site_work_repository.dart';

class MockOffSiteWorkRepository implements OffSiteWorkRepository {
  MockOffSiteWorkRepository({
    required this.members,
    required this.attachments,
    required this.locationProvider,
    Now? now,
  }) : _now = now ?? systemNow;

  final OrganizationMembersRepository members;
  final AttachmentStorage attachments;
  final AttendanceLocationProvider locationProvider;
  final Now _now;
  final Map<String, OffSiteWorkAssignment> _assignments = {};

  @override
  Future<List<OffSiteWorkAssignment>> getAssignments({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    final organizationId = _requireOrganization(access);
    final items = _assignments.values.where((assignment) {
      if (assignment.organizationId != organizationId) return false;
      return switch (access.user.role) {
        UserRole.employee => assignment.employeeUid == access.user.id,
        UserRole.orgAdmin => true,
        UserRole.branchManager =>
          activeBranchId != null &&
              _managedBranch(access, activeBranchId) &&
              assignment.branchId == activeBranchId,
        _ => false,
      };
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<OffSiteWorkAssignment> getAssignment({
    required UserAccessContext access,
    required String assignmentId,
    String? activeBranchId,
  }) async {
    final assignment = _assignments[assignmentId];
    if (assignment == null ||
        assignment.organizationId != _requireOrganization(access)) {
      throw const NotFoundException('Assignment not found');
    }
    final allowed = switch (access.user.role) {
      UserRole.employee => assignment.employeeUid == access.user.id,
      UserRole.orgAdmin => _managedBranch(access, assignment.branchId),
      UserRole.branchManager =>
        activeBranchId == assignment.branchId &&
            _managedBranch(access, assignment.branchId),
      _ => false,
    };
    if (!allowed) throw const NotFoundException('Assignment not found');
    return assignment;
  }

  @override
  Future<OffSiteWorkAssignment> createAssignment({
    required UserAccessContext access,
    String? activeBranchId,
    required OffSiteWorkAssignmentDraft draft,
  }) async {
    if (access.user.role != UserRole.orgAdmin &&
        access.user.role != UserRole.branchManager) {
      throw const AccessDeniedException(
        'Only managers can assign off-site work.',
      );
    }
    if (access.user.role == UserRole.branchManager &&
        activeBranchId != draft.branchId) {
      throw const AccessDeniedException('Use your active branch.');
    }
    if (!_managedBranch(access, draft.branchId)) {
      throw const AccessDeniedException('Branch not found or access denied.');
    }
    final organizationId = _requireOrganization(access);
    final employees = await _allEmployees(
      access,
      activeBranchId: access.user.role == UserRole.branchManager
          ? activeBranchId
          : null,
    );
    final employee = employees.where((member) {
      return member.id == draft.employeeMemberId &&
          member.branchIds.contains(draft.branchId) &&
          member.status == AccountStatus.active;
    }).firstOrNull;
    if (employee == null || employee.authUid == null) {
      throw ValidationException('Choose an active employee at this branch.');
    }
    final branch = access.assignedBranches
        .where((candidate) => candidate.id == draft.branchId)
        .firstOrNull;
    if (branch == null || !branch.isActive) {
      throw ValidationException('Choose an active branch.');
    }
    final now = _now();
    final assignmentId = RequestIds.uuidV4();
    final assigned = OffSiteWorkEvent(
      id: RequestIds.uuidV4(),
      type: OffSiteWorkEventType.assigned,
      actorUid: access.user.id,
      actorName: access.user.name,
      occurredAt: now,
    );
    final assignment = OffSiteWorkAssignment(
      id: assignmentId,
      organizationId: organizationId,
      branchId: branch.id,
      branchName: branch.name,
      employeeMemberId: employee.id,
      employeeUid: employee.authUid!,
      employeeName: employee.fullName,
      assignedByUid: access.user.id,
      assignedByName: access.user.name,
      title: draft.title.trim(),
      instructions: _optional(draft.instructions),
      destination: draft.destination.trim(),
      dueAt: draft.dueAt,
      reference: _optional(draft.reference),
      requiredEvidenceDescription: _optional(draft.requiredEvidenceDescription),
      status: OffSiteWorkStatus.assigned,
      createdAt: now,
      updatedAt: now,
      events: [assigned],
    );
    _assignments[assignment.id] = assignment;
    return assignment;
  }

  @override
  Future<OffSiteWorkAssignment> recordMilestone({
    required UserAccessContext access,
    String? activeBranchId,
    required String assignmentId,
    required OffSiteWorkMilestone milestone,
    String? note,
    List<String> evidenceLocalPaths = const [],
  }) async {
    final assignment = await getAssignment(
      access: access,
      assignmentId: assignmentId,
      activeBranchId: activeBranchId,
    );
    if (access.user.role != UserRole.employee) {
      throw const AccessDeniedException(
        'Only the assigned employee can update this assignment.',
      );
    }
    if (milestone == OffSiteWorkMilestone.unableToComplete &&
        (note == null || note.trim().isEmpty)) {
      throw ValidationException('Add a reason before continuing.');
    }
    if (milestone == OffSiteWorkMilestone.completion &&
        (assignment.requiredEvidenceDescription?.trim().isNotEmpty ?? false) &&
        (note == null || note.trim().isEmpty) &&
        evidenceLocalPaths.isEmpty) {
      throw ValidationException(
        'Add the requested evidence as a note or photo before completing.',
      );
    }
    if (evidenceLocalPaths.length > 5) {
      throw ValidationException('Attach no more than 5 photos.');
    }
    final location = await locationProvider.currentLocation();
    final references = <String>[];
    final attachmentStorage = attachments;
    for (final path in evidenceLocalPaths) {
      if (attachmentStorage is ScopedAttachmentStorage) {
        references.add(
          await attachmentStorage.uploadScoped(
            localPath: path,
            organizationId: assignment.organizationId,
            kind: AttachmentKind.offSiteWorkEvidence,
            pathSegments: [
              assignment.branchId,
              assignment.employeeUid,
              assignment.id,
            ],
          ),
        );
      } else {
        references.add(
          await attachmentStorage.upload(
            localPath: path,
            organizationId: assignment.organizationId,
            kind: AttachmentKind.offSiteWorkEvidence,
          ),
        );
      }
    }
    final transition = _nextStatus(assignment.status, milestone);
    final now = _now();
    final event = OffSiteWorkEvent(
      id: RequestIds.uuidV4(),
      type: OffSiteWorkEventType.parse(milestone.wireValue),
      actorUid: access.user.id,
      actorName: access.user.name,
      occurredAt: now,
      location: OffSiteWorkLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        accuracyMeters: location.accuracyMeters,
        occurredAt: now,
      ),
      note: _optional(note),
      evidenceReferences: references,
    );
    final updated = assignment.copyWith(
      status: transition,
      latestLocation: event.location,
      events: [...assignment.events, event],
    );
    _assignments[assignmentId] = updated;
    return updated;
  }

  Future<List<OrganizationMember>> _allEmployees(
    UserAccessContext access, {
    String? activeBranchId,
  }) async {
    final result = <OrganizationMember>[];
    var offset = 0;
    while (result.length < 1000) {
      final page = await members.getMembersPage(
        access: access,
        activeBranchId: activeBranchId,
        role: UserRole.employee,
        status: AccountStatus.active,
        offset: offset,
        limit: 100,
      );
      result.addAll(page.items);
      if (!page.hasMore) break;
      offset = page.nextOffset;
    }
    return result;
  }

  String _requireOrganization(UserAccessContext access) {
    final id = access.organization?.id ?? access.user.organizationId;
    if (id == null || id.isEmpty || !access.user.role.isCustomerLevel) {
      throw const AccessDeniedException('Organization context is required.');
    }
    return id;
  }

  bool _managedBranch(UserAccessContext access, String branchId) {
    final branch = access.activeAssignedBranches
        .where((candidate) => candidate.id == branchId)
        .firstOrNull;
    return branch != null &&
        (access.user.role == UserRole.orgAdmin ||
            (access.user.role == UserRole.branchManager &&
                access.assignedBranches.any(
                  (candidate) => candidate.id == branchId,
                )));
  }

  OffSiteWorkStatus _nextStatus(
    OffSiteWorkStatus current,
    OffSiteWorkMilestone milestone,
  ) {
    final next = switch ((current, milestone)) {
      (OffSiteWorkStatus.assigned, OffSiteWorkMilestone.start) =>
        OffSiteWorkStatus.inProgress,
      (OffSiteWorkStatus.inProgress, OffSiteWorkMilestone.arrival) =>
        OffSiteWorkStatus.arrived,
      (OffSiteWorkStatus.arrived, OffSiteWorkMilestone.completion) =>
        OffSiteWorkStatus.completed,
      (OffSiteWorkStatus.arrived, OffSiteWorkMilestone.unableToComplete) =>
        OffSiteWorkStatus.unableToComplete,
      (OffSiteWorkStatus.completed, OffSiteWorkMilestone.returnToBranch) ||
      (
        OffSiteWorkStatus.unableToComplete,
        OffSiteWorkMilestone.returnToBranch,
      ) => OffSiteWorkStatus.returned,
      _ => null,
    };
    if (next == null) {
      throw ValidationException(
        'This milestone is not available for the current assignment.',
      );
    }
    return next;
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
