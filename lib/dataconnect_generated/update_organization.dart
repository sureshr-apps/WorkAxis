part of 'workaxis_connector.dart';

class UpdateOrganizationVariablesBuilder {
  String id;
  Optional<String> _name = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _category = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _country = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpdateOrganizationVariablesBuilder name(String? t) {
   _name.value = t;
   return this;
  }
  UpdateOrganizationVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }
  UpdateOrganizationVariablesBuilder category(String? t) {
   _category.value = t;
   return this;
  }
  UpdateOrganizationVariablesBuilder country(String? t) {
   _country.value = t;
   return this;
  }

  UpdateOrganizationVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<UpdateOrganizationData> dataDeserializer = (dynamic json)  => UpdateOrganizationData.fromJson(jsonDecode(json));
  Serializer<UpdateOrganizationVariables> varsSerializer = (UpdateOrganizationVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateOrganizationData, UpdateOrganizationVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateOrganizationData, UpdateOrganizationVariables> ref() {
    UpdateOrganizationVariables vars= UpdateOrganizationVariables(id: id,name: _name,status: _status,category: _category,country: _country,);
    return _dataConnect.mutation("UpdateOrganization", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateOrganizationOrganizationUpdate {
  final String id;
  UpdateOrganizationOrganizationUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateOrganizationOrganizationUpdate otherTyped = other as UpdateOrganizationOrganizationUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateOrganizationOrganizationUpdate({
    required this.id,
  });
}

@immutable
class UpdateOrganizationData {
  final UpdateOrganizationOrganizationUpdate? organization_update;
  UpdateOrganizationData.fromJson(dynamic json):
  
  organization_update = json['organization_update'] == null ? null : UpdateOrganizationOrganizationUpdate.fromJson(json['organization_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateOrganizationData otherTyped = other as UpdateOrganizationData;
    return organization_update == otherTyped.organization_update;
    
  }
  @override
  int get hashCode => organization_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (organization_update != null) {
      json['organization_update'] = organization_update!.toJson();
    }
    return json;
  }

  UpdateOrganizationData({
    this.organization_update,
  });
}

@immutable
class UpdateOrganizationVariables {
  final String id;
  late final Optional<String>name;
  late final Optional<String>status;
  late final Optional<String>category;
  late final Optional<String>country;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateOrganizationVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']) {
  
  
  
    name = Optional.optional(nativeFromJson, nativeToJson);
    name.value = json['name'] == null ? null : nativeFromJson<String>(json['name']);
  
  
    status = Optional.optional(nativeFromJson, nativeToJson);
    status.value = json['status'] == null ? null : nativeFromJson<String>(json['status']);
  
  
    category = Optional.optional(nativeFromJson, nativeToJson);
    category.value = json['category'] == null ? null : nativeFromJson<String>(json['category']);
  
  
    country = Optional.optional(nativeFromJson, nativeToJson);
    country.value = json['country'] == null ? null : nativeFromJson<String>(json['country']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateOrganizationVariables otherTyped = other as UpdateOrganizationVariables;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    status == otherTyped.status && 
    category == otherTyped.category && 
    country == otherTyped.country;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, status.hashCode, category.hashCode, country.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if(name.state == OptionalState.set) {
      json['name'] = name.toJson();
    }
    if(status.state == OptionalState.set) {
      json['status'] = status.toJson();
    }
    if(category.state == OptionalState.set) {
      json['category'] = category.toJson();
    }
    if(country.state == OptionalState.set) {
      json['country'] = country.toJson();
    }
    return json;
  }

  UpdateOrganizationVariables({
    required this.id,
    required this.name,
    required this.status,
    required this.category,
    required this.country,
  });
}

