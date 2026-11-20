import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/backend/json_reader.dart';
import 'package:workaxis/features/off_site_work/domain/models/off_site_work_assignment.dart';

class OffSiteWorkRemoteDataSource {
  const OffSiteWorkRemoteDataSource({required this.gateway});

  final DataGateway gateway;

  Future<OffSiteWorkPage> list({
    required int limit,
    required int offset,
    String? activeBranchId,
  }) async {
    final data = await gateway.call('ListOffSiteWorkAssignments', {
      'limit': limit,
      'offset': offset,
      'activeBranchId': ?activeBranchId,
    });
    return OffSiteWorkPage(
      assignments: [
        for (final row in data.objects('offSiteWorkAssignments'))
          _assignment(row),
      ],
      total: data.countOf('total'),
    );
  }

  Future<OffSiteWorkAssignment> get({
    required String assignmentId,
    String? activeBranchId,
  }) async {
    final data = await gateway.call('GetOffSiteWorkAssignment', {
      'id': assignmentId,
      'activeBranchId': ?activeBranchId,
    });
    return _assignment(data.object('offSiteWorkAssignment'));
  }

  Future<OffSiteWorkAssignment> create({
    required OffSiteWorkAssignmentDraft draft,
    String? activeBranchId,
  }) async {
    final data = await gateway.call('CreateOffSiteWorkAssignment', {
      'branchId': draft.branchId,
      'employeeMemberId': draft.employeeMemberId,
      'title': draft.title,
      'destination': draft.destination,
      if (draft.instructions?.trim().isNotEmpty == true)
        'instructions': draft.instructions!.trim(),
      if (draft.dueAt != null) 'dueAt': draft.dueAt!.toUtc().toIso8601String(),
      if (draft.reference?.trim().isNotEmpty == true)
        'reference': draft.reference!.trim(),
      if (draft.requiredEvidenceDescription?.trim().isNotEmpty == true)
        'requiredEvidenceDescription': draft.requiredEvidenceDescription!
            .trim(),
      'activeBranchId': ?activeBranchId,
    });
    return _assignment(data.object('offSiteWorkAssignment'));
  }

  Future<OffSiteWorkAssignment> recordMilestone({
    required String assignmentId,
    required OffSiteWorkMilestone milestone,
    required OffSiteWorkLocation location,
    String? activeBranchId,
    String? note,
    List<String> evidenceReferences = const [],
  }) async {
    final data = await gateway.call('RecordOffSiteWorkMilestone', {
      'id': assignmentId,
      'eventType': milestone.wireValue,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'accuracyMeters': location.accuracyMeters,
      'activeBranchId': ?activeBranchId,
      if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
      if (evidenceReferences.isNotEmpty)
        'evidenceReferences': evidenceReferences,
    });
    return _assignment(data.object('offSiteWorkAssignment'));
  }

  OffSiteWorkAssignment _assignment(Map<String, dynamic> row) {
    final latestLocation = _location(
      latitude: row.optNumber('latestLatitude'),
      longitude: row.optNumber('latestLongitude'),
      accuracy: row.optNumber('latestAccuracyMeters'),
      occurredAt: row.optDateTime('latestMilestoneAt'),
    );
    final events = row.optObjects('events') ?? const <Map<String, dynamic>>[];
    return OffSiteWorkAssignment(
      id: row.string('id'),
      organizationId: row.string('organizationId'),
      branchId: row.string('branchId'),
      branchName: row.string('branchName'),
      employeeMemberId: row.string('employeeMemberId'),
      employeeUid: row.string('employeeUid'),
      employeeName: row.string('employeeName'),
      assignedByUid: row.string('assignedByUid'),
      assignedByName: row.string('assignedByName'),
      title: row.string('title'),
      instructions: row.optString('instructions'),
      destination: row.string('destination'),
      dueAt: row.optDateTime('dueAt'),
      reference: row.optString('reference'),
      requiredEvidenceDescription: row.optString('requiredEvidenceDescription'),
      status: OffSiteWorkStatus.parse(row.string('status')),
      latestLocation: latestLocation,
      createdAt: row.dateTime('createdAt'),
      updatedAt: row.dateTime('updatedAt'),
      events: [for (final event in events) _event(event)],
    );
  }

  OffSiteWorkEvent _event(Map<String, dynamic> row) {
    final evidence = row['evidenceReferences'];
    final references = evidence is List
        ? evidence.whereType<String>().toList(growable: false)
        : const <String>[];
    return OffSiteWorkEvent(
      id: row.string('id'),
      type: OffSiteWorkEventType.parse(row.string('eventType')),
      actorUid: row.string('actorUid'),
      actorName: row.string('actorName'),
      occurredAt: row.dateTime('occurredAt'),
      location: _location(
        latitude: row.optNumber('latitude'),
        longitude: row.optNumber('longitude'),
        accuracy: row.optNumber('accuracyMeters'),
        occurredAt: row.optDateTime('occurredAt'),
      ),
      note: row.optString('note'),
      evidenceReferences: references,
    );
  }

  OffSiteWorkLocation? _location({
    required double? latitude,
    required double? longitude,
    required double? accuracy,
    required DateTime? occurredAt,
  }) {
    if (latitude == null || longitude == null || accuracy == null) return null;
    return OffSiteWorkLocation(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracy,
      occurredAt: occurredAt,
    );
  }
}

class OffSiteWorkPage {
  const OffSiteWorkPage({required this.assignments, required this.total});

  final List<OffSiteWorkAssignment> assignments;
  final int total;
}
