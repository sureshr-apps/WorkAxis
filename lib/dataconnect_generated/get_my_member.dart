part of 'workaxis_connector.dart';

class GetMyMemberVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  GetMyMemberVariablesBuilder(this._dataConnect);
  Deserializer<GetMyMemberData> dataDeserializer = (dynamic json) =>
      GetMyMemberData.fromJson(jsonDecode(json));

  Future<QueryResult<GetMyMemberData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyMemberData, void> ref() {
    return _dataConnect.query(
      "GetMyMember",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class GetMyMemberOrganizationMembers {
  final String id;
  final String? authUid;
  final String fullName;
  final String username;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final GetMyMemberOrganizationMembersOrganization? organization;
  GetMyMemberOrganizationMembers.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      authUid = json['authUid'] == null
          ? null
          : nativeFromJson<String>(json['authUid']),
      fullName = nativeFromJson<String>(json['fullName']),
      username = nativeFromJson<String>(json['username']),
      email = nativeFromJson<String>(json['email']),
      phone = json['phone'] == null
          ? null
          : nativeFromJson<String>(json['phone']),
      role = nativeFromJson<String>(json['role']),
      status = nativeFromJson<String>(json['status']),
      organization = json['organization'] == null
          ? null
          : GetMyMemberOrganizationMembersOrganization.fromJson(
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

    final GetMyMemberOrganizationMembers otherTyped =
        other as GetMyMemberOrganizationMembers;
    return id == otherTyped.id &&
        authUid == otherTyped.authUid &&
        fullName == otherTyped.fullName &&
        username == otherTyped.username &&
        email == otherTyped.email &&
        phone == otherTyped.phone &&
        role == otherTyped.role &&
        status == otherTyped.status &&
        organization == otherTyped.organization;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    authUid.hashCode,
    fullName.hashCode,
    username.hashCode,
    email.hashCode,
    phone.hashCode,
    role.hashCode,
    status.hashCode,
    organization.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (authUid != null) {
      json['authUid'] = nativeToJson<String?>(authUid);
    }
    json['fullName'] = nativeToJson<String>(fullName);
    json['username'] = nativeToJson<String>(username);
    json['email'] = nativeToJson<String>(email);
    if (phone != null) {
      json['phone'] = nativeToJson<String?>(phone);
    }
    json['role'] = nativeToJson<String>(role);
    json['status'] = nativeToJson<String>(status);
    if (organization != null) {
      json['organization'] = organization!.toJson();
    }
    return json;
  }

  GetMyMemberOrganizationMembers({
    required this.id,
    this.authUid,
    required this.fullName,
    required this.username,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.organization,
  });
}

@immutable
class GetMyMemberOrganizationMembersOrganization {
  final String id;
  final String name;
  final String code;
  final String status;
  GetMyMemberOrganizationMembersOrganization.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      name = nativeFromJson<String>(json['name']),
      code = nativeFromJson<String>(json['code']),
      status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyMemberOrganizationMembersOrganization otherTyped =
        other as GetMyMemberOrganizationMembersOrganization;
    return id == otherTyped.id &&
        name == otherTyped.name &&
        code == otherTyped.code &&
        status == otherTyped.status;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    name.hashCode,
    code.hashCode,
    status.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['code'] = nativeToJson<String>(code);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  GetMyMemberOrganizationMembersOrganization({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
  });
}

@immutable
class GetMyMemberData {
  final List<GetMyMemberOrganizationMembers> organizationMembers;
  GetMyMemberData.fromJson(dynamic json)
    : organizationMembers = (json['organizationMembers'] as List<dynamic>)
          .map((e) => GetMyMemberOrganizationMembers.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyMemberData otherTyped = other as GetMyMemberData;
    return organizationMembers == otherTyped.organizationMembers;
  }

  @override
  int get hashCode => organizationMembers.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['organizationMembers'] = organizationMembers
        .map((e) => e.toJson())
        .toList();
    return json;
  }

  GetMyMemberData({required this.organizationMembers});
}
