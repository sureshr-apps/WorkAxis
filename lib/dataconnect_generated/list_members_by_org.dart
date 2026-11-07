part of 'workaxis_connector.dart';

class ListMembersByOrgVariablesBuilder {
  String orgId;

  final FirebaseDataConnect _dataConnect;
  ListMembersByOrgVariablesBuilder(this._dataConnect, {required  this.orgId,});
  Deserializer<ListMembersByOrgData> dataDeserializer = (dynamic json)  => ListMembersByOrgData.fromJson(jsonDecode(json));
  Serializer<ListMembersByOrgVariables> varsSerializer = (ListMembersByOrgVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListMembersByOrgData, ListMembersByOrgVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListMembersByOrgData, ListMembersByOrgVariables> ref() {
    ListMembersByOrgVariables vars= ListMembersByOrgVariables(orgId: orgId,);
    return _dataConnect.query("ListMembersByOrg", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListMembersByOrgOrganizationMembers {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? phone;
  final String role;
  final String status;
  ListMembersByOrgOrganizationMembers.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  fullName = nativeFromJson<String>(json['fullName']),
  username = nativeFromJson<String>(json['username']),
  email = nativeFromJson<String>(json['email']),
  phone = json['phone'] == null ? null : nativeFromJson<String>(json['phone']),
  role = nativeFromJson<String>(json['role']),
  status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMembersByOrgOrganizationMembers otherTyped = other as ListMembersByOrgOrganizationMembers;
    return id == otherTyped.id && 
    fullName == otherTyped.fullName && 
    username == otherTyped.username && 
    email == otherTyped.email && 
    phone == otherTyped.phone && 
    role == otherTyped.role && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, fullName.hashCode, username.hashCode, email.hashCode, phone.hashCode, role.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['fullName'] = nativeToJson<String>(fullName);
    json['username'] = nativeToJson<String>(username);
    json['email'] = nativeToJson<String>(email);
    if (phone != null) {
      json['phone'] = nativeToJson<String?>(phone);
    }
    json['role'] = nativeToJson<String>(role);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  ListMembersByOrgOrganizationMembers({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
  });
}

@immutable
class ListMembersByOrgData {
  final List<ListMembersByOrgOrganizationMembers> organizationMembers;
  ListMembersByOrgData.fromJson(dynamic json):
  
  organizationMembers = (json['organizationMembers'] as List<dynamic>)
        .map((e) => ListMembersByOrgOrganizationMembers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMembersByOrgData otherTyped = other as ListMembersByOrgData;
    return organizationMembers == otherTyped.organizationMembers;
    
  }
  @override
  int get hashCode => organizationMembers.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['organizationMembers'] = organizationMembers.map((e) => e.toJson()).toList();
    return json;
  }

  ListMembersByOrgData({
    required this.organizationMembers,
  });
}

@immutable
class ListMembersByOrgVariables {
  final String orgId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListMembersByOrgVariables.fromJson(Map<String, dynamic> json):
  
  orgId = nativeFromJson<String>(json['orgId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMembersByOrgVariables otherTyped = other as ListMembersByOrgVariables;
    return orgId == otherTyped.orgId;
    
  }
  @override
  int get hashCode => orgId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = nativeToJson<String>(orgId);
    return json;
  }

  ListMembersByOrgVariables({
    required this.orgId,
  });
}

