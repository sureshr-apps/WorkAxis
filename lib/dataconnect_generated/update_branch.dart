part of 'workaxis_connector.dart';

class UpdateBranchVariablesBuilder {
  String id;
  Optional<String> _name = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _code = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _location = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);
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
  UpdateBranchVariablesBuilder name(String? t) {
    _name.value = t;
    return this;
  }

  UpdateBranchVariablesBuilder code(String? t) {
    _code.value = t;
    return this;
  }

  UpdateBranchVariablesBuilder location(String? t) {
    _location.value = t;
    return this;
  }

  UpdateBranchVariablesBuilder status(String? t) {
    _status.value = t;
    return this;
  }

  UpdateBranchVariablesBuilder isMainBranch(bool? t) {
    _isMainBranch.value = t;
    return this;
  }

  UpdateBranchVariablesBuilder geofenceRadiusMeters(int? t) {
    _geofenceRadiusMeters.value = t;
    return this;
  }

  UpdateBranchVariablesBuilder latitude(double? t) {
    _latitude.value = t;
    return this;
  }

  UpdateBranchVariablesBuilder longitude(double? t) {
    _longitude.value = t;
    return this;
  }

  UpdateBranchVariablesBuilder kioskEnabled(bool? t) {
    _kioskEnabled.value = t;
    return this;
  }

  UpdateBranchVariablesBuilder(this._dataConnect, {required this.id});
  Deserializer<UpdateBranchData> dataDeserializer = (dynamic json) =>
      UpdateBranchData.fromJson(jsonDecode(json));
  Serializer<UpdateBranchVariables> varsSerializer = (
    UpdateBranchVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateBranchData, UpdateBranchVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateBranchData, UpdateBranchVariables> ref() {
    UpdateBranchVariables vars = UpdateBranchVariables(
      id: id,
      name: _name,
      code: _code,
      location: _location,
      status: _status,
      isMainBranch: _isMainBranch,
      geofenceRadiusMeters: _geofenceRadiusMeters,
      latitude: _latitude,
      longitude: _longitude,
      kioskEnabled: _kioskEnabled,
    );
    return _dataConnect.mutation(
      "UpdateBranch",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class UpdateBranchBranchUpdate {
  final String id;
  UpdateBranchBranchUpdate.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateBranchBranchUpdate otherTyped =
        other as UpdateBranchBranchUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateBranchBranchUpdate({required this.id});
}

@immutable
class UpdateBranchData {
  final UpdateBranchBranchUpdate? branch_update;
  UpdateBranchData.fromJson(dynamic json)
    : branch_update = json['branch_update'] == null
          ? null
          : UpdateBranchBranchUpdate.fromJson(json['branch_update']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateBranchData otherTyped = other as UpdateBranchData;
    return branch_update == otherTyped.branch_update;
  }

  @override
  int get hashCode => branch_update.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (branch_update != null) {
      json['branch_update'] = branch_update!.toJson();
    }
    return json;
  }

  UpdateBranchData({this.branch_update});
}

@immutable
class UpdateBranchVariables {
  final String id;
  late final Optional<String> name;
  late final Optional<String> code;
  late final Optional<String> location;
  late final Optional<String> status;
  late final Optional<bool> isMainBranch;
  late final Optional<int> geofenceRadiusMeters;
  late final Optional<double> latitude;
  late final Optional<double> longitude;
  late final Optional<bool> kioskEnabled;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  UpdateBranchVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']) {
    name = Optional.optional(nativeFromJson, nativeToJson);
    name.value = json['name'] == null
        ? null
        : nativeFromJson<String>(json['name']);

    code = Optional.optional(nativeFromJson, nativeToJson);
    code.value = json['code'] == null
        ? null
        : nativeFromJson<String>(json['code']);

    location = Optional.optional(nativeFromJson, nativeToJson);
    location.value = json['location'] == null
        ? null
        : nativeFromJson<String>(json['location']);

    status = Optional.optional(nativeFromJson, nativeToJson);
    status.value = json['status'] == null
        ? null
        : nativeFromJson<String>(json['status']);

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

    final UpdateBranchVariables otherTyped = other as UpdateBranchVariables;
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
    if (name.state == OptionalState.set) {
      json['name'] = name.toJson();
    }
    if (code.state == OptionalState.set) {
      json['code'] = code.toJson();
    }
    if (location.state == OptionalState.set) {
      json['location'] = location.toJson();
    }
    if (status.state == OptionalState.set) {
      json['status'] = status.toJson();
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

  UpdateBranchVariables({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.status,
    required this.isMainBranch,
    required this.geofenceRadiusMeters,
    required this.latitude,
    required this.longitude,
    required this.kioskEnabled,
  });
}
