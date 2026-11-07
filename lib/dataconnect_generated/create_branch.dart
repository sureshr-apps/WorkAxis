part of 'workaxis_connector.dart';

class CreateBranchVariablesBuilder {
  String id;
  String orgId;
  String name;
  String code;
  Optional<String> _location = Optional.optional(nativeFromJson, nativeToJson);
  Optional<bool> _isMainBranch = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _geofenceRadiusMeters = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _latitude = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _longitude = Optional.optional(nativeFromJson, nativeToJson);
  Optional<bool> _kioskEnabled = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreateBranchVariablesBuilder location(String? t) {
   _location.value = t;
   return this;
  }
  CreateBranchVariablesBuilder isMainBranch(bool? t) {
   _isMainBranch.value = t;
   return this;
  }
  CreateBranchVariablesBuilder geofenceRadiusMeters(int? t) {
   _geofenceRadiusMeters.value = t;
   return this;
  }
  CreateBranchVariablesBuilder latitude(double? t) {
   _latitude.value = t;
   return this;
  }
  CreateBranchVariablesBuilder longitude(double? t) {
   _longitude.value = t;
   return this;
  }
  CreateBranchVariablesBuilder kioskEnabled(bool? t) {
   _kioskEnabled.value = t;
   return this;
  }

  CreateBranchVariablesBuilder(this._dataConnect, {required  this.id,required  this.orgId,required  this.name,required  this.code,});
  Deserializer<CreateBranchData> dataDeserializer = (dynamic json)  => CreateBranchData.fromJson(jsonDecode(json));
  Serializer<CreateBranchVariables> varsSerializer = (CreateBranchVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateBranchData, CreateBranchVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateBranchData, CreateBranchVariables> ref() {
    CreateBranchVariables vars= CreateBranchVariables(id: id,orgId: orgId,name: name,code: code,location: _location,isMainBranch: _isMainBranch,geofenceRadiusMeters: _geofenceRadiusMeters,latitude: _latitude,longitude: _longitude,kioskEnabled: _kioskEnabled,);
    return _dataConnect.mutation("CreateBranch", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateBranchBranchInsert {
  final String id;
  CreateBranchBranchInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBranchBranchInsert otherTyped = other as CreateBranchBranchInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateBranchBranchInsert({
    required this.id,
  });
}

@immutable
class CreateBranchData {
  final CreateBranchBranchInsert branch_insert;
  CreateBranchData.fromJson(dynamic json):
  
  branch_insert = CreateBranchBranchInsert.fromJson(json['branch_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBranchData otherTyped = other as CreateBranchData;
    return branch_insert == otherTyped.branch_insert;
    
  }
  @override
  int get hashCode => branch_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branch_insert'] = branch_insert.toJson();
    return json;
  }

  CreateBranchData({
    required this.branch_insert,
  });
}

@immutable
class CreateBranchVariables {
  final String id;
  final String orgId;
  final String name;
  final String code;
  late final Optional<String>location;
  late final Optional<bool>isMainBranch;
  late final Optional<int>geofenceRadiusMeters;
  late final Optional<double>latitude;
  late final Optional<double>longitude;
  late final Optional<bool>kioskEnabled;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateBranchVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  orgId = nativeFromJson<String>(json['orgId']),
  name = nativeFromJson<String>(json['name']),
  code = nativeFromJson<String>(json['code']) {
  
  
  
  
  
  
    location = Optional.optional(nativeFromJson, nativeToJson);
    location.value = json['location'] == null ? null : nativeFromJson<String>(json['location']);
  
  
    isMainBranch = Optional.optional(nativeFromJson, nativeToJson);
    isMainBranch.value = json['isMainBranch'] == null ? null : nativeFromJson<bool>(json['isMainBranch']);
  
  
    geofenceRadiusMeters = Optional.optional(nativeFromJson, nativeToJson);
    geofenceRadiusMeters.value = json['geofenceRadiusMeters'] == null ? null : nativeFromJson<int>(json['geofenceRadiusMeters']);
  
  
    latitude = Optional.optional(nativeFromJson, nativeToJson);
    latitude.value = json['latitude'] == null ? null : nativeFromJson<double>(json['latitude']);
  
  
    longitude = Optional.optional(nativeFromJson, nativeToJson);
    longitude.value = json['longitude'] == null ? null : nativeFromJson<double>(json['longitude']);
  
  
    kioskEnabled = Optional.optional(nativeFromJson, nativeToJson);
    kioskEnabled.value = json['kioskEnabled'] == null ? null : nativeFromJson<bool>(json['kioskEnabled']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateBranchVariables otherTyped = other as CreateBranchVariables;
    return id == otherTyped.id && 
    orgId == otherTyped.orgId && 
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
  int get hashCode => Object.hashAll([id.hashCode, orgId.hashCode, name.hashCode, code.hashCode, location.hashCode, isMainBranch.hashCode, geofenceRadiusMeters.hashCode, latitude.hashCode, longitude.hashCode, kioskEnabled.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['orgId'] = nativeToJson<String>(orgId);
    json['name'] = nativeToJson<String>(name);
    json['code'] = nativeToJson<String>(code);
    if(location.state == OptionalState.set) {
      json['location'] = location.toJson();
    }
    if(isMainBranch.state == OptionalState.set) {
      json['isMainBranch'] = isMainBranch.toJson();
    }
    if(geofenceRadiusMeters.state == OptionalState.set) {
      json['geofenceRadiusMeters'] = geofenceRadiusMeters.toJson();
    }
    if(latitude.state == OptionalState.set) {
      json['latitude'] = latitude.toJson();
    }
    if(longitude.state == OptionalState.set) {
      json['longitude'] = longitude.toJson();
    }
    if(kioskEnabled.state == OptionalState.set) {
      json['kioskEnabled'] = kioskEnabled.toJson();
    }
    return json;
  }

  CreateBranchVariables({
    required this.id,
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

