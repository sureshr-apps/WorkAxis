part of 'workaxis_connector.dart';

class GetBranchByIdVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetBranchByIdVariablesBuilder(this._dataConnect, {required this.id});
  Deserializer<GetBranchByIdData> dataDeserializer = (dynamic json) =>
      GetBranchByIdData.fromJson(jsonDecode(json));
  Serializer<GetBranchByIdVariables> varsSerializer = (
    GetBranchByIdVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBranchByIdData, GetBranchByIdVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetBranchByIdData, GetBranchByIdVariables> ref() {
    GetBranchByIdVariables vars = GetBranchByIdVariables(id: id);
    return _dataConnect.query(
      "GetBranchById",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBranchByIdBranch {
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
  final GetBranchByIdBranchOrganization organization;
  GetBranchByIdBranch.fromJson(dynamic json)
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
      organization = GetBranchByIdBranchOrganization.fromJson(
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

    final GetBranchByIdBranch otherTyped = other as GetBranchByIdBranch;
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

  GetBranchByIdBranch({
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
class GetBranchByIdBranchOrganization {
  final String id;
  GetBranchByIdBranchOrganization.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBranchByIdBranchOrganization otherTyped =
        other as GetBranchByIdBranchOrganization;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetBranchByIdBranchOrganization({required this.id});
}

@immutable
class GetBranchByIdData {
  final GetBranchByIdBranch? branch;
  GetBranchByIdData.fromJson(dynamic json)
    : branch = json['branch'] == null
          ? null
          : GetBranchByIdBranch.fromJson(json['branch']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBranchByIdData otherTyped = other as GetBranchByIdData;
    return branch == otherTyped.branch;
  }

  @override
  int get hashCode => branch.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (branch != null) {
      json['branch'] = branch!.toJson();
    }
    return json;
  }

  GetBranchByIdData({this.branch});
}

@immutable
class GetBranchByIdVariables {
  final String id;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBranchByIdVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBranchByIdVariables otherTyped = other as GetBranchByIdVariables;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetBranchByIdVariables({required this.id});
}
