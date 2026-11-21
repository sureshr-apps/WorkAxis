enum OffSiteWorkStatus {
  assigned,
  inProgress,
  arrived,
  completed,
  unableToComplete,
  returned;

  String get wireValue => switch (this) {
    OffSiteWorkStatus.assigned => 'assigned',
    OffSiteWorkStatus.inProgress => 'in_progress',
    OffSiteWorkStatus.arrived => 'arrived',
    OffSiteWorkStatus.completed => 'completed',
    OffSiteWorkStatus.unableToComplete => 'unable_to_complete',
    OffSiteWorkStatus.returned => 'returned',
  };

  String get label => switch (this) {
    OffSiteWorkStatus.assigned => 'Assigned',
    OffSiteWorkStatus.inProgress => 'In progress',
    OffSiteWorkStatus.arrived => 'Arrived',
    OffSiteWorkStatus.completed => 'Completed',
    OffSiteWorkStatus.unableToComplete => 'Unable to complete',
    OffSiteWorkStatus.returned => 'Returned to branch',
  };

  static OffSiteWorkStatus parse(String value) => values.firstWhere(
    (status) => status.wireValue == value,
    orElse: () => throw FormatException('Unknown off-site work status: $value'),
  );
}

enum OffSiteWorkEventType {
  assigned,
  started,
  arrived,
  completed,
  unableToComplete,
  returnedToBranch;

  String get wireValue => switch (this) {
    OffSiteWorkEventType.assigned => 'assigned',
    OffSiteWorkEventType.started => 'started',
    OffSiteWorkEventType.arrived => 'arrived',
    OffSiteWorkEventType.completed => 'completed',
    OffSiteWorkEventType.unableToComplete => 'unable_to_complete',
    OffSiteWorkEventType.returnedToBranch => 'returned_to_branch',
  };

  String get label => switch (this) {
    OffSiteWorkEventType.assigned => 'Assigned',
    OffSiteWorkEventType.started => 'Started assignment',
    OffSiteWorkEventType.arrived => 'Arrived at destination',
    OffSiteWorkEventType.completed => 'Completed',
    OffSiteWorkEventType.unableToComplete => 'Unable to complete',
    OffSiteWorkEventType.returnedToBranch => 'Returned to branch',
  };

  static OffSiteWorkEventType parse(String value) => values.firstWhere(
    (event) => event.wireValue == value,
    orElse: () => throw FormatException('Unknown off-site work event: $value'),
  );
}

enum OffSiteWorkMilestone {
  start,
  arrival,
  completion,
  unableToComplete,
  returnToBranch;

  String get wireValue => switch (this) {
    OffSiteWorkMilestone.start => 'started',
    OffSiteWorkMilestone.arrival => 'arrived',
    OffSiteWorkMilestone.completion => 'completed',
    OffSiteWorkMilestone.unableToComplete => 'unable_to_complete',
    OffSiteWorkMilestone.returnToBranch => 'returned_to_branch',
  };
}

class OffSiteWorkLocation {
  const OffSiteWorkLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    this.occurredAt,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime? occurredAt;
}

class OffSiteWorkEvent {
  const OffSiteWorkEvent({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.actorName,
    required this.occurredAt,
    this.location,
    this.note,
    this.evidenceReferences = const [],
  });

  final String id;
  final OffSiteWorkEventType type;
  final String actorUid;
  final String actorName;
  final DateTime occurredAt;
  final OffSiteWorkLocation? location;
  final String? note;
  final List<String> evidenceReferences;
}

class OffSiteWorkAssignment {
  const OffSiteWorkAssignment({
    required this.id,
    required this.organizationId,
    required this.branchId,
    required this.branchName,
    required this.employeeMemberId,
    required this.employeeUid,
    required this.employeeName,
    required this.assignedByUid,
    required this.assignedByName,
    required this.title,
    required this.destination,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.instructions,
    this.destinationLatitude,
    this.destinationLongitude,
    this.dueAt,
    this.reference,
    this.requiredEvidenceDescription,
    this.latestLocation,
    this.events = const [],
  });

  final String id;
  final String organizationId;
  final String branchId;
  final String branchName;
  final String employeeMemberId;
  final String employeeUid;
  final String employeeName;
  final String assignedByUid;
  final String assignedByName;
  final String title;
  final String? instructions;
  final String destination;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final DateTime? dueAt;
  final String? reference;
  final String? requiredEvidenceDescription;
  final OffSiteWorkStatus status;
  final OffSiteWorkLocation? latestLocation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OffSiteWorkEvent> events;

  OffSiteWorkAssignment copyWith({
    OffSiteWorkStatus? status,
    OffSiteWorkLocation? latestLocation,
    List<OffSiteWorkEvent>? events,
  }) => OffSiteWorkAssignment(
    id: id,
    organizationId: organizationId,
    branchId: branchId,
    branchName: branchName,
    employeeMemberId: employeeMemberId,
    employeeUid: employeeUid,
    employeeName: employeeName,
    assignedByUid: assignedByUid,
    assignedByName: assignedByName,
    title: title,
    instructions: instructions,
    destination: destination,
    destinationLatitude: destinationLatitude,
    destinationLongitude: destinationLongitude,
    dueAt: dueAt,
    reference: reference,
    requiredEvidenceDescription: requiredEvidenceDescription,
    status: status ?? this.status,
    latestLocation: latestLocation ?? this.latestLocation,
    createdAt: createdAt,
    updatedAt: updatedAt,
    events: events ?? this.events,
  );
}

class OffSiteWorkAssignmentDraft {
  const OffSiteWorkAssignmentDraft({
    required this.branchId,
    required this.employeeMemberId,
    required this.title,
    required this.destination,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.instructions,
    this.dueAt,
    this.reference,
    this.requiredEvidenceDescription,
  });

  final String branchId;
  final String employeeMemberId;
  final String title;
  final String destination;
  final double destinationLatitude;
  final double destinationLongitude;
  final String? instructions;
  final DateTime? dueAt;
  final String? reference;
  final String? requiredEvidenceDescription;
}
