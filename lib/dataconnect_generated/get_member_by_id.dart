part of 'workaxis_connector.dart';

class GetMemberByIdVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetMemberByIdVariablesBuilder(this._dataConnect, {required this.id});
  Deserializer<GetMemberByIdData> dataDeserializer = (dynamic json) =>
      GetMemberByIdData.fromJson(jsonDecode(json));
  Serializer<GetMemberByIdVariables> varsSerializer = (
    GetMemberByIdVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<QueryResult<GetMemberByIdData, GetMemberByIdVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetMemberByIdData, GetMemberByIdVariables> ref() {
    GetMemberByIdVariables vars = GetMemberByIdVariables(id: id);
    return _dataConnect.query(
      "GetMemberById",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetMemberByIdOrganizationMember {
  final String id;
  final String? authUid;
  final String fullName;
  final String username;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final Timestamp createdAt;
  final GetMemberByIdOrganizationMemberOrganization? organization;
  final List<GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMember>
  userBranchAssignments_on_member;
  GetMemberByIdOrganizationMember.fromJson(dynamic json)
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
      createdAt = Timestamp.fromJson(json['createdAt']),
      organization = json['organization'] == null
          ? null
          : GetMemberByIdOrganizationMemberOrganization.fromJson(
              json['organization'],
            ),
      userBranchAssignments_on_member =
          (json['userBranchAssignments_on_member'] as List<dynamic>)
              .map(
                (e) =>
                    GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMember.fromJson(
                      e,
                    ),
              )
              .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMemberByIdOrganizationMember otherTyped =
        other as GetMemberByIdOrganizationMember;
    return id == otherTyped.id &&
        authUid == otherTyped.authUid &&
        fullName == otherTyped.fullName &&
        username == otherTyped.username &&
        email == otherTyped.email &&
        phone == otherTyped.phone &&
        role == otherTyped.role &&
        status == otherTyped.status &&
        createdAt == otherTyped.createdAt &&
        organization == otherTyped.organization &&
        userBranchAssignments_on_member ==
            otherTyped.userBranchAssignments_on_member;
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
    createdAt.hashCode,
    organization.hashCode,
    userBranchAssignments_on_member.hashCode,
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
    json['createdAt'] = createdAt.toJson();
    if (organization != null) {
      json['organization'] = organization!.toJson();
    }
    json['userBranchAssignments_on_member'] = userBranchAssignments_on_member
        .map((e) => e.toJson())
        .toList();
    return json;
  }

  GetMemberByIdOrganizationMember({
    required this.id,
    this.authUid,
    required this.fullName,
    required this.username,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
    this.organization,
    required this.userBranchAssignments_on_member,
  });
}

@immutable
class GetMemberByIdOrganizationMemberOrganization {
  final String id;
  GetMemberByIdOrganizationMemberOrganization.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMemberByIdOrganizationMemberOrganization otherTyped =
        other as GetMemberByIdOrganizationMemberOrganization;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetMemberByIdOrganizationMemberOrganization({required this.id});
}

@immutable
class GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMember {
  final GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMemberBranch
  branch;
  GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMember.fromJson(
    dynamic json,
  ) : branch =
          GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMemberBranch.fromJson(
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

    final GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMember
    otherTyped =
        other as GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMember;
    return branch == otherTyped.branch;
  }

  @override
  int get hashCode => branch.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branch'] = branch.toJson();
    return json;
  }

  GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMember({
    required this.branch,
  });
}

@immutable
class GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMemberBranch {
  final String id;
  final String name;
  GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMemberBranch.fromJson(
    dynamic json,
  ) : id = nativeFromJson<String>(json['id']),
      name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMemberBranch
    otherTyped =
        other
            as GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMemberBranch;
    return id == otherTyped.id && name == otherTyped.name;
  }

  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  GetMemberByIdOrganizationMemberUserBranchAssignmentsOnMemberBranch({
    required this.id,
    required this.name,
  });
}

@immutable
class GetMemberByIdData {
  final GetMemberByIdOrganizationMember? organizationMember;
  GetMemberByIdData.fromJson(dynamic json)
    : organizationMember = json['organizationMember'] == null
          ? null
          : GetMemberByIdOrganizationMember.fromJson(
              json['organizationMember'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMemberByIdData otherTyped = other as GetMemberByIdData;
    return organizationMember == otherTyped.organizationMember;
  }

  @override
  int get hashCode => organizationMember.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (organizationMember != null) {
      json['organizationMember'] = organizationMember!.toJson();
    }
    return json;
  }

  GetMemberByIdData({this.organizationMember});
}

@immutable
class GetMemberByIdVariables {
  final String id;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetMemberByIdVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMemberByIdVariables otherTyped = other as GetMemberByIdVariables;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetMemberByIdVariables({required this.id});
}
