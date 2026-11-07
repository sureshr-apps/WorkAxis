part of 'workaxis_connector.dart';

class ListMyBranchAssignmentsVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  ListMyBranchAssignmentsVariablesBuilder(this._dataConnect);
  Deserializer<ListMyBranchAssignmentsData> dataDeserializer = (dynamic json) =>
      ListMyBranchAssignmentsData.fromJson(jsonDecode(json));

  Future<QueryResult<ListMyBranchAssignmentsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListMyBranchAssignmentsData, void> ref() {
    return _dataConnect.query(
      "ListMyBranchAssignments",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class ListMyBranchAssignmentsUserBranchAssignments {
  final String id;
  final ListMyBranchAssignmentsUserBranchAssignmentsBranch branch;
  ListMyBranchAssignmentsUserBranchAssignments.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      branch = ListMyBranchAssignmentsUserBranchAssignmentsBranch.fromJson(
        json['branch'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyBranchAssignmentsUserBranchAssignments otherTyped =
        other as ListMyBranchAssignmentsUserBranchAssignments;
    return id == otherTyped.id && branch == otherTyped.branch;
  }

  @override
  int get hashCode => Object.hashAll([id.hashCode, branch.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['branch'] = branch.toJson();
    return json;
  }

  ListMyBranchAssignmentsUserBranchAssignments({
    required this.id,
    required this.branch,
  });
}

@immutable
class ListMyBranchAssignmentsUserBranchAssignmentsBranch {
  final String id;
  final String name;
  final String code;
  final String? location;
  final String status;
  final bool isMainBranch;
  final int? geofenceRadiusMeters;
  final double? latitude;
  final double? longitude;
  final bool? kioskEnabled;
  final ListMyBranchAssignmentsUserBranchAssignmentsBranchOrganization
  organization;
  ListMyBranchAssignmentsUserBranchAssignmentsBranch.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      name = nativeFromJson<String>(json['name']),
      code = nativeFromJson<String>(json['code']),
      location = json['location'] == null
          ? null
          : nativeFromJson<String>(json['location']),
      status = nativeFromJson<String>(json['status']),
      isMainBranch = nativeFromJson<bool>(json['isMainBranch']),
      geofenceRadiusMeters = json['geofenceRadiusMeters'] == null
          ? null
          : nativeFromJson<int>(json['geofenceRadiusMeters']),
      latitude = json['latitude'] == null
          ? null
          : nativeFromJson<double>(json['latitude']),
      longitude = json['longitude'] == null
          ? null
          : nativeFromJson<double>(json['longitude']),
      kioskEnabled = json['kioskEnabled'] == null
          ? null
          : nativeFromJson<bool>(json['kioskEnabled']),
      organization =
          ListMyBranchAssignmentsUserBranchAssignmentsBranchOrganization.fromJson(
            json['organization'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyBranchAssignmentsUserBranchAssignmentsBranch otherTyped =
        other as ListMyBranchAssignmentsUserBranchAssignmentsBranch;
    return id == otherTyped.id &&
        name == otherTyped.name &&
        code == otherTyped.code &&
        location == otherTyped.location &&
        status == otherTyped.status &&
        isMainBranch == otherTyped.isMainBranch &&
        geofenceRadiusMeters == otherTyped.geofenceRadiusMeters &&
        latitude == otherTyped.latitude &&
        longitude == otherTyped.longitude &&
        kioskEnabled == otherTyped.kioskEnabled &&
        organization == otherTyped.organization;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    name.hashCode,
    code.hashCode,
    location.hashCode,
    status.hashCode,
    isMainBranch.hashCode,
    geofenceRadiusMeters.hashCode,
    latitude.hashCode,
    longitude.hashCode,
    kioskEnabled.hashCode,
    organization.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['code'] = nativeToJson<String>(code);
    if (location != null) {
      json['location'] = nativeToJson<String?>(location);
    }
    json['status'] = nativeToJson<String>(status);
    json['isMainBranch'] = nativeToJson<bool>(isMainBranch);
    if (geofenceRadiusMeters != null) {
      json['geofenceRadiusMeters'] = nativeToJson<int?>(geofenceRadiusMeters);
    }
    if (latitude != null) {
      json['latitude'] = nativeToJson<double?>(latitude);
    }
    if (longitude != null) {
      json['longitude'] = nativeToJson<double?>(longitude);
    }
    if (kioskEnabled != null) {
      json['kioskEnabled'] = nativeToJson<bool?>(kioskEnabled);
    }
    json['organization'] = organization.toJson();
    return json;
  }

  ListMyBranchAssignmentsUserBranchAssignmentsBranch({
    required this.id,
    required this.name,
    required this.code,
    this.location,
    required this.status,
    required this.isMainBranch,
    this.geofenceRadiusMeters,
    this.latitude,
    this.longitude,
    this.kioskEnabled,
    required this.organization,
  });
}

@immutable
class ListMyBranchAssignmentsUserBranchAssignmentsBranchOrganization {
  final String id;
  ListMyBranchAssignmentsUserBranchAssignmentsBranchOrganization.fromJson(
    dynamic json,
  ) : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyBranchAssignmentsUserBranchAssignmentsBranchOrganization
    otherTyped =
        other as ListMyBranchAssignmentsUserBranchAssignmentsBranchOrganization;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ListMyBranchAssignmentsUserBranchAssignmentsBranchOrganization({
    required this.id,
  });
}

@immutable
class ListMyBranchAssignmentsData {
  final List<ListMyBranchAssignmentsUserBranchAssignments>
  userBranchAssignments;
  ListMyBranchAssignmentsData.fromJson(dynamic json)
    : userBranchAssignments = (json['userBranchAssignments'] as List<dynamic>)
          .map((e) => ListMyBranchAssignmentsUserBranchAssignments.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyBranchAssignmentsData otherTyped =
        other as ListMyBranchAssignmentsData;
    return userBranchAssignments == otherTyped.userBranchAssignments;
  }

  @override
  int get hashCode => userBranchAssignments.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userBranchAssignments'] = userBranchAssignments
        .map((e) => e.toJson())
        .toList();
    return json;
  }

  ListMyBranchAssignmentsData({required this.userBranchAssignments});
}
