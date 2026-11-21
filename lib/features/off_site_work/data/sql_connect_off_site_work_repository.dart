import 'package:workaxis/core/errors/backend_error_mapper.dart';
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employee_home/domain/services/attendance_location_provider.dart';
import 'package:workaxis/features/off_site_work/data/off_site_work_remote_data_source.dart';
import 'package:workaxis/features/off_site_work/domain/models/off_site_work_assignment.dart';
import 'package:workaxis/features/off_site_work/domain/repositories/off_site_work_repository.dart';

class SqlConnectOffSiteWorkRepository implements OffSiteWorkRepository {
  SqlConnectOffSiteWorkRepository({
    required this.remote,
    required this.attachments,
    required this.locationProvider,
  });

  final OffSiteWorkRemoteDataSource remote;
  final ScopedAttachmentStorage attachments;
  final AttendanceLocationProvider locationProvider;

  @override
  Future<List<OffSiteWorkAssignment>> getAssignments({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    try {
      final assignments = <OffSiteWorkAssignment>[];
      var offset = 0;
      while (assignments.length < 1000) {
        final page = await remote.list(
          limit: 100,
          offset: offset,
          activeBranchId: access.user.role == UserRole.branchManager
              ? activeBranchId
              : null,
        );
        assignments.addAll(page.assignments);
        if (assignments.length >= page.total || page.assignments.isEmpty) break;
        offset += page.assignments.length;
      }
      return assignments;
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<OffSiteWorkAssignment> getAssignment({
    required UserAccessContext access,
    required String assignmentId,
    String? activeBranchId,
  }) async {
    try {
      return await remote.get(
        assignmentId: assignmentId,
        activeBranchId: access.user.role == UserRole.branchManager
            ? activeBranchId
            : null,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<OffSiteWorkAssignment> createAssignment({
    required UserAccessContext access,
    String? activeBranchId,
    required OffSiteWorkAssignmentDraft draft,
  }) async {
    try {
      return await remote.create(
        draft: draft,
        activeBranchId: access.user.role == UserRole.branchManager
            ? activeBranchId
            : null,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }

  @override
  Future<void> deleteAssignment({
    required UserAccessContext access,
    required String assignmentId,
    String? activeBranchId,
  }) async {
    try {
      await remote.delete(
        assignmentId: assignmentId,
        activeBranchId: access.user.role == UserRole.branchManager
            ? activeBranchId
            : null,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
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
    try {
      final managerBranch = access.user.role == UserRole.branchManager
          ? activeBranchId
          : null;
      final assignment = await remote.get(
        assignmentId: assignmentId,
        activeBranchId: managerBranch,
      );
      if ((access.user.role != UserRole.employee &&
              access.user.role != UserRole.branchManager) ||
          assignment.employeeUid != access.user.id) {
        throw ValidationException(
          'Only the assigned person can update this assignment.',
        );
      }
      if (milestone == OffSiteWorkMilestone.unableToComplete &&
          (note == null || note.trim().isEmpty)) {
        throw ValidationException('Add a reason before continuing.');
      }
      if (milestone == OffSiteWorkMilestone.completion &&
          (assignment.requiredEvidenceDescription?.trim().isNotEmpty ??
              false) &&
          (note == null || note.trim().isEmpty) &&
          evidenceLocalPaths.isEmpty) {
        throw ValidationException(
          'Add the requested evidence as a note or photo before completing.',
        );
      }
      if (evidenceLocalPaths.length > 5) {
        throw ValidationException('Attach no more than 5 photos.');
      }

      // A single fix is read only after the employee presses the milestone
      // action. There is no position stream or background tracking here.
      final fix = await locationProvider.currentLocation();
      final references = <String>[];
      for (final localPath in evidenceLocalPaths) {
        references.add(
          await attachments.uploadScoped(
            localPath: localPath,
            organizationId: assignment.organizationId,
            kind: AttachmentKind.offSiteWorkEvidence,
            pathSegments: [
              assignment.branchId,
              assignment.employeeUid,
              assignment.id,
            ],
          ),
        );
      }
      return await remote.recordMilestone(
        assignmentId: assignmentId,
        milestone: milestone,
        location: OffSiteWorkLocation(
          latitude: fix.latitude,
          longitude: fix.longitude,
          accuracyMeters: fix.accuracyMeters,
        ),
        activeBranchId: managerBranch,
        note: note,
        evidenceReferences: references,
      );
    } catch (e, st) {
      throw mapBackendError(e, st);
    }
  }
}
