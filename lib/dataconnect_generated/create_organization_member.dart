part of 'workaxis_connector.dart';

class CreateOrganizationMemberVariablesBuilder {
  String id;
  String orgId;
  String fullName;
  String username;
  String email;
  Optional<String> _phone = Optional.optional(nativeFromJson, nativeToJson);
  String role;
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreateOrganizationMemberVariablesBuilder phone(String? t) {
   _phone.value = t;
   return this;
  }
  CreateOrganizationMemberVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }

  CreateOrganizationMemberVariablesBuilder(this._dataConnect, {required  this.id,required  this.orgId,required  this.fullName,required  this.username,required  this.email,required  this.role,});
  Deserializer<CreateOrganizationMemberData> dataDeserializer = (dynamic json)  => CreateOrganizationMemberData.fromJson(jsonDecode(json));
  Serializer<CreateOrganizationMemberVariables> varsSerializer = (CreateOrganizationMemberVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateOrganizationMemberData, CreateOrganizationMemberVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateOrganizationMemberData, CreateOrganizationMemberVariables> ref() {
    CreateOrganizationMemberVariables vars= CreateOrganizationMemberVariables(id: id,orgId: orgId,fullName: fullName,username: username,email: email,phone: _phone,role: role,status: _status,);
    return _dataConnect.mutation("CreateOrganizationMember", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateOrganizationMemberOrganizationMemberInsert {
  final String id;
  CreateOrganizationMemberOrganizationMemberInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateOrganizationMemberOrganizationMemberInsert otherTyped = other as CreateOrganizationMemberOrganizationMemberInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateOrganizationMemberOrganizationMemberInsert({
    required this.id,
  });
}

@immutable
class CreateOrganizationMemberData {
  final CreateOrganizationMemberOrganizationMemberInsert organizationMember_insert;
  CreateOrganizationMemberData.fromJson(dynamic json):
  
  organizationMember_insert = CreateOrganizationMemberOrganizationMemberInsert.fromJson(json['organizationMember_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateOrganizationMemberData otherTyped = other as CreateOrganizationMemberData;
    return organizationMember_insert == otherTyped.organizationMember_insert;
    
  }
  @override
  int get hashCode => organizationMember_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['organizationMember_insert'] = organizationMember_insert.toJson();
    return json;
  }

  CreateOrganizationMemberData({
    required this.organizationMember_insert,
  });
}

@immutable
class CreateOrganizationMemberVariables {
  final String id;
  final String orgId;
  final String fullName;
  final String username;
  final String email;
  late final Optional<String>phone;
  final String role;
  late final Optional<String>status;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateOrganizationMemberVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  orgId = nativeFromJson<String>(json['orgId']),
  fullName = nativeFromJson<String>(json['fullName']),
  username = nativeFromJson<String>(json['username']),
  email = nativeFromJson<String>(json['email']),
  role = nativeFromJson<String>(json['role']) {
  
  
  
  
  
  
  
    phone = Optional.optional(nativeFromJson, nativeToJson);
    phone.value = json['phone'] == null ? null : nativeFromJson<String>(json['phone']);
  
  
  
    status = Optional.optional(nativeFromJson, nativeToJson);
    status.value = json['status'] == null ? null : nativeFromJson<String>(json['status']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateOrganizationMemberVariables otherTyped = other as CreateOrganizationMemberVariables;
    return id == otherTyped.id && 
    orgId == otherTyped.orgId && 
    fullName == otherTyped.fullName && 
    username == otherTyped.username && 
    email == otherTyped.email && 
    phone == otherTyped.phone && 
    role == otherTyped.role && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, orgId.hashCode, fullName.hashCode, username.hashCode, email.hashCode, phone.hashCode, role.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['orgId'] = nativeToJson<String>(orgId);
    json['fullName'] = nativeToJson<String>(fullName);
    json['username'] = nativeToJson<String>(username);
    json['email'] = nativeToJson<String>(email);
    if(phone.state == OptionalState.set) {
      json['phone'] = phone.toJson();
    }
    json['role'] = nativeToJson<String>(role);
    if(status.state == OptionalState.set) {
      json['status'] = status.toJson();
    }
    return json;
  }

  CreateOrganizationMemberVariables({
    required this.id,
    required this.orgId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
  });
}

