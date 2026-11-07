part of 'workaxis_connector.dart';

class ListMembersByOrgPagedVariablesBuilder {
  String orgId;
  int limit;
  int offset;
  Optional<String> _nameContains = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _role = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  ListMembersByOrgPagedVariablesBuilder nameContains(String? t) {
    _nameContains.value = t;
    return this;
  }

  ListMembersByOrgPagedVariablesBuilder status(String? t) {
    _status.value = t;
    return this;
  }

  ListMembersByOrgPagedVariablesBuilder role(String? t) {
    _role.value = t;
    return this;
  }

  ListMembersByOrgPagedVariablesBuilder(
    this._dataConnect, {
    required this.orgId,
    required this.limit,
    required this.offset,
  });
  Deserializer<ListMembersByOrgPagedData> dataDeserializer = (dynamic json) =>
      ListMembersByOrgPagedData.fromJson(jsonDecode(json));
  Serializer<ListMembersByOrgPagedVariables> varsSerializer = (
    ListMembersByOrgPagedVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<QueryResult<ListMembersByOrgPagedData, ListMembersByOrgPagedVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<ListMembersByOrgPagedData, ListMembersByOrgPagedVariables> ref() {
    ListMembersByOrgPagedVariables vars = ListMembersByOrgPagedVariables(
      orgId: orgId,
      limit: limit,
      offset: offset,
      nameContains: _nameContains,
      status: _status,
      role: _role,
    );
    return _dataConnect.query(
      "ListMembersByOrgPaged",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class ListMembersByOrgPagedOrganizationMembers {
  final String id;
  final String? authUid;
  final String fullName;
  final String username;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final List<
    ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMember
  >
  userBranchAssignments_on_member;
  ListMembersByOrgPagedOrganizationMembers.fromJson(dynamic json)
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
      userBranchAssignments_on_member =
          (json['userBranchAssignments_on_member'] as List<dynamic>)
              .map(
                (e) =>
                    ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMember.fromJson(
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

    final ListMembersByOrgPagedOrganizationMembers otherTyped =
        other as ListMembersByOrgPagedOrganizationMembers;
    return id == otherTyped.id &&
        authUid == otherTyped.authUid &&
        fullName == otherTyped.fullName &&
        username == otherTyped.username &&
        email == otherTyped.email &&
        phone == otherTyped.phone &&
        role == otherTyped.role &&
        status == otherTyped.status &&
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
    json['userBranchAssignments_on_member'] = userBranchAssignments_on_member
        .map((e) => e.toJson())
        .toList();
    return json;
  }

  ListMembersByOrgPagedOrganizationMembers({
    required this.id,
    this.authUid,
    required this.fullName,
    required this.username,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    required this.userBranchAssignments_on_member,
  });
}

@immutable
class ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMember {
  final ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMemberBranch
  branch;
  ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMember.fromJson(
    dynamic json,
  ) : branch =
          ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMemberBranch.fromJson(
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

    final ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMember
    otherTyped =
        other
            as ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMember;
    return branch == otherTyped.branch;
  }

  @override
  int get hashCode => branch.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branch'] = branch.toJson();
    return json;
  }

  ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMember({
    required this.branch,
  });
}

@immutable
class ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMemberBranch {
  final String id;
  ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMemberBranch.fromJson(
    dynamic json,
  ) : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMemberBranch
    otherTyped =
        other
            as ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMemberBranch;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ListMembersByOrgPagedOrganizationMembersUserBranchAssignmentsOnMemberBranch({
    required this.id,
  });
}

@immutable
class ListMembersByOrgPagedTotal {
  final int count_;
  ListMembersByOrgPagedTotal.fromJson(dynamic json)
    : count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMembersByOrgPagedTotal otherTyped =
        other as ListMembersByOrgPagedTotal;
    return count_ == otherTyped.count_;
  }

  @override
  int get hashCode => count_.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  ListMembersByOrgPagedTotal({required this.count_});
}

@immutable
class ListMembersByOrgPagedData {
  final List<ListMembersByOrgPagedOrganizationMembers> organizationMembers;
  final List<ListMembersByOrgPagedTotal> total;
  ListMembersByOrgPagedData.fromJson(dynamic json)
    : organizationMembers = (json['organizationMembers'] as List<dynamic>)
          .map((e) => ListMembersByOrgPagedOrganizationMembers.fromJson(e))
          .toList(),
      total = (json['total'] as List<dynamic>)
          .map((e) => ListMembersByOrgPagedTotal.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMembersByOrgPagedData otherTyped =
        other as ListMembersByOrgPagedData;
    return organizationMembers == otherTyped.organizationMembers &&
        total == otherTyped.total;
  }

  @override
  int get hashCode =>
      Object.hashAll([organizationMembers.hashCode, total.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['organizationMembers'] = organizationMembers
        .map((e) => e.toJson())
        .toList();
    json['total'] = total.map((e) => e.toJson()).toList();
    return json;
  }

  ListMembersByOrgPagedData({
    required this.organizationMembers,
    required this.total,
  });
}

@immutable
class ListMembersByOrgPagedVariables {
  final String orgId;
  final int limit;
  final int offset;
  late final Optional<String> nameContains;
  late final Optional<String> status;
  late final Optional<String> role;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  ListMembersByOrgPagedVariables.fromJson(Map<String, dynamic> json)
    : orgId = nativeFromJson<String>(json['orgId']),
      limit = nativeFromJson<int>(json['limit']),
      offset = nativeFromJson<int>(json['offset']) {
    nameContains = Optional.optional(nativeFromJson, nativeToJson);
    nameContains.value = json['nameContains'] == null
        ? null
        : nativeFromJson<String>(json['nameContains']);

    status = Optional.optional(nativeFromJson, nativeToJson);
    status.value = json['status'] == null
        ? null
        : nativeFromJson<String>(json['status']);

    role = Optional.optional(nativeFromJson, nativeToJson);
    role.value = json['role'] == null
        ? null
        : nativeFromJson<String>(json['role']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMembersByOrgPagedVariables otherTyped =
        other as ListMembersByOrgPagedVariables;
    return orgId == otherTyped.orgId &&
        limit == otherTyped.limit &&
        offset == otherTyped.offset &&
        nameContains == otherTyped.nameContains &&
        status == otherTyped.status &&
        role == otherTyped.role;
  }

  @override
  int get hashCode => Object.hashAll([
    orgId.hashCode,
    limit.hashCode,
    offset.hashCode,
    nameContains.hashCode,
    status.hashCode,
    role.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = nativeToJson<String>(orgId);
    json['limit'] = nativeToJson<int>(limit);
    json['offset'] = nativeToJson<int>(offset);
    if (nameContains.state == OptionalState.set) {
      json['nameContains'] = nameContains.toJson();
    }
    if (status.state == OptionalState.set) {
      json['status'] = status.toJson();
    }
    if (role.state == OptionalState.set) {
      json['role'] = role.toJson();
    }
    return json;
  }

  ListMembersByOrgPagedVariables({
    required this.orgId,
    required this.limit,
    required this.offset,
    required this.nameContains,
    required this.status,
    required this.role,
  });
}
