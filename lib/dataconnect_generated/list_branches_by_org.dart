part of 'workaxis_connector.dart';

class ListBranchesByOrgVariablesBuilder {
  String orgId;

  final FirebaseDataConnect _dataConnect;
  ListBranchesByOrgVariablesBuilder(this._dataConnect, {required this.orgId});
  Deserializer<ListBranchesByOrgData> dataDeserializer = (dynamic json) =>
      ListBranchesByOrgData.fromJson(jsonDecode(json));
  Serializer<ListBranchesByOrgVariables> varsSerializer = (
    ListBranchesByOrgVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<QueryResult<ListBranchesByOrgData, ListBranchesByOrgVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<ListBranchesByOrgData, ListBranchesByOrgVariables> ref() {
    ListBranchesByOrgVariables vars = ListBranchesByOrgVariables(orgId: orgId);
    return _dataConnect.query(
      "ListBranchesByOrg",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class ListBranchesByOrgBranches {
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
  ListBranchesByOrgBranches.fromJson(dynamic json)
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
          : nativeFromJson<bool>(json['kioskEnabled']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListBranchesByOrgBranches otherTyped =
        other as ListBranchesByOrgBranches;
    return id == otherTyped.id &&
        name == otherTyped.name &&
        code == otherTyped.code &&
        location == otherTyped.location &&
        status == otherTyped.status &&
        isMainBranch == otherTyped.isMainBranch &&
        geofenceRadiusMeters == otherTyped.geofenceRadiusMeters &&
        latitude == otherTyped.latitude &&
        longitude == otherTyped.longitude &&
        kioskEnabled == otherTyped.kioskEnabled;
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
    return json;
  }

  ListBranchesByOrgBranches({
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
  });
}

@immutable
class ListBranchesByOrgData {
  final List<ListBranchesByOrgBranches> branches;
  ListBranchesByOrgData.fromJson(dynamic json)
    : branches = (json['branches'] as List<dynamic>)
          .map((e) => ListBranchesByOrgBranches.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListBranchesByOrgData otherTyped = other as ListBranchesByOrgData;
    return branches == otherTyped.branches;
  }

  @override
  int get hashCode => branches.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branches'] = branches.map((e) => e.toJson()).toList();
    return json;
  }

  ListBranchesByOrgData({required this.branches});
}

@immutable
class ListBranchesByOrgVariables {
  final String orgId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  ListBranchesByOrgVariables.fromJson(Map<String, dynamic> json)
    : orgId = nativeFromJson<String>(json['orgId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListBranchesByOrgVariables otherTyped =
        other as ListBranchesByOrgVariables;
    return orgId == otherTyped.orgId;
  }

  @override
  int get hashCode => orgId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = nativeToJson<String>(orgId);
    return json;
  }

  ListBranchesByOrgVariables({required this.orgId});
}
