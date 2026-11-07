part of 'workaxis_connector.dart';

class AddBranchVariablesBuilder {
  String orgId;
  String name;
  String code;
  Optional<String> _location = Optional.optional(nativeFromJson, nativeToJson);
  Optional<bool> _isMainBranch = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<int> _geofenceRadiusMeters = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<double> _latitude = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _longitude = Optional.optional(nativeFromJson, nativeToJson);
  Optional<bool> _kioskEnabled = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );

  final FirebaseDataConnect _dataConnect;
  AddBranchVariablesBuilder location(String? t) {
    _location.value = t;
    return this;
  }

  AddBranchVariablesBuilder isMainBranch(bool? t) {
    _isMainBranch.value = t;
    return this;
  }

  AddBranchVariablesBuilder geofenceRadiusMeters(int? t) {
    _geofenceRadiusMeters.value = t;
    return this;
  }

  AddBranchVariablesBuilder latitude(double? t) {
    _latitude.value = t;
    return this;
  }

  AddBranchVariablesBuilder longitude(double? t) {
    _longitude.value = t;
    return this;
  }

  AddBranchVariablesBuilder kioskEnabled(bool? t) {
    _kioskEnabled.value = t;
    return this;
  }

  AddBranchVariablesBuilder(
    this._dataConnect, {
    required this.orgId,
    required this.name,
    required this.code,
  });
  Deserializer<AddBranchData> dataDeserializer = (dynamic json) =>
      AddBranchData.fromJson(jsonDecode(json));
  Serializer<AddBranchVariables> varsSerializer = (AddBranchVariables vars) =>
      jsonEncode(vars.toJson());
  Future<OperationResult<AddBranchData, AddBranchVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AddBranchData, AddBranchVariables> ref() {
    AddBranchVariables vars = AddBranchVariables(
      orgId: orgId,
      name: name,
      code: code,
      location: _location,
      isMainBranch: _isMainBranch,
      geofenceRadiusMeters: _geofenceRadiusMeters,
      latitude: _latitude,
      longitude: _longitude,
      kioskEnabled: _kioskEnabled,
    );
    return _dataConnect.mutation(
      "AddBranch",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class AddBranchBranchInsert {
  final String id;
  AddBranchBranchInsert.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final AddBranchBranchInsert otherTyped = other as AddBranchBranchInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AddBranchBranchInsert({required this.id});
}

@immutable
class AddBranchData {
  final AddBranchBranchInsert branch_insert;
  AddBranchData.fromJson(dynamic json)
    : branch_insert = AddBranchBranchInsert.fromJson(json['branch_insert']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final AddBranchData otherTyped = other as AddBranchData;
    return branch_insert == otherTyped.branch_insert;
  }

  @override
  int get hashCode => branch_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branch_insert'] = branch_insert.toJson();
    return json;
  }

  AddBranchData({required this.branch_insert});
}

@immutable
class AddBranchVariables {
  final String orgId;
  final String name;
  final String code;
  late final Optional<String> location;
  late final Optional<bool> isMainBranch;
  late final Optional<int> geofenceRadiusMeters;
  late final Optional<double> latitude;
  late final Optional<double> longitude;
  late final Optional<bool> kioskEnabled;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  AddBranchVariables.fromJson(Map<String, dynamic> json)
    : orgId = nativeFromJson<String>(json['orgId']),
      name = nativeFromJson<String>(json['name']),
      code = nativeFromJson<String>(json['code']) {
    location = Optional.optional(nativeFromJson, nativeToJson);
    location.value = json['location'] == null
        ? null
        : nativeFromJson<String>(json['location']);

    isMainBranch = Optional.optional(nativeFromJson, nativeToJson);
    isMainBranch.value = json['isMainBranch'] == null
        ? null
        : nativeFromJson<bool>(json['isMainBranch']);

    geofenceRadiusMeters = Optional.optional(nativeFromJson, nativeToJson);
    geofenceRadiusMeters.value = json['geofenceRadiusMeters'] == null
        ? null
        : nativeFromJson<int>(json['geofenceRadiusMeters']);

    latitude = Optional.optional(nativeFromJson, nativeToJson);
    latitude.value = json['latitude'] == null
        ? null
        : nativeFromJson<double>(json['latitude']);

    longitude = Optional.optional(nativeFromJson, nativeToJson);
    longitude.value = json['longitude'] == null
        ? null
        : nativeFromJson<double>(json['longitude']);

    kioskEnabled = Optional.optional(nativeFromJson, nativeToJson);
    kioskEnabled.value = json['kioskEnabled'] == null
        ? null
        : nativeFromJson<bool>(json['kioskEnabled']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final AddBranchVariables otherTyped = other as AddBranchVariables;
    return orgId == otherTyped.orgId &&
        name == otherTyped.name &&
        code == otherTyped.code &&
        location == otherTyped.location &&
        isMainBranch == otherTyped.isMainBranch &&
        geofenceRadiusMeters == otherTyped.geofenceRadiusMeters &&
        latitude == otherTyped.latitude &&
        longitude == otherTyped.longitude &&
        kioskEnabled == otherTyped.kioskEnabled;
  }

  @override
  int get hashCode => Object.hashAll([
    orgId.hashCode,
    name.hashCode,
    code.hashCode,
    location.hashCode,
    isMainBranch.hashCode,
    geofenceRadiusMeters.hashCode,
    latitude.hashCode,
    longitude.hashCode,
    kioskEnabled.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = nativeToJson<String>(orgId);
    json['name'] = nativeToJson<String>(name);
    json['code'] = nativeToJson<String>(code);
    if (location.state == OptionalState.set) {
      json['location'] = location.toJson();
    }
    if (isMainBranch.state == OptionalState.set) {
      json['isMainBranch'] = isMainBranch.toJson();
    }
    if (geofenceRadiusMeters.state == OptionalState.set) {
      json['geofenceRadiusMeters'] = geofenceRadiusMeters.toJson();
    }
    if (latitude.state == OptionalState.set) {
      json['latitude'] = latitude.toJson();
    }
    if (longitude.state == OptionalState.set) {
      json['longitude'] = longitude.toJson();
    }
    if (kioskEnabled.state == OptionalState.set) {
      json['kioskEnabled'] = kioskEnabled.toJson();
    }
    return json;
  }

  AddBranchVariables({
    required this.orgId,
    required this.name,
    required this.code,
    required this.location,
    required this.isMainBranch,
    required this.geofenceRadiusMeters,
    required this.latitude,
    required this.longitude,
    required this.kioskEnabled,
  });
}
