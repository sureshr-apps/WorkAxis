import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/off_site_work/domain/models/off_site_work_assignment.dart';

abstract interface class OffSiteWorkRepository {
  Future<List<OffSiteWorkAssignment>> getAssignments({
    required UserAccessContext access,
    String? activeBranchId,
  });

  Future<OffSiteWorkAssignment> getAssignment({
    required UserAccessContext access,
    required String assignmentId,
    String? activeBranchId,
  });

  Future<OffSiteWorkAssignment> createAssignment({
    required UserAccessContext access,
    String? activeBranchId,
    required OffSiteWorkAssignmentDraft draft,
  });

  /// Captures one current GPS fix and records a single milestone. It never
  /// watches location updates or changes attendance state.
  Future<OffSiteWorkAssignment> recordMilestone({
    required UserAccessContext access,
    String? activeBranchId,
    required String assignmentId,
    required OffSiteWorkMilestone milestone,
    String? note,
    List<String> evidenceLocalPaths = const [],
  });
}
