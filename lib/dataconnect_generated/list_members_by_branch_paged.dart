part of 'workaxis_connector.dart';

class ListMembersByBranchPagedVariablesBuilder {
  String branchId;
  int limit;
  int offset;
  Optional<String> _nameContains = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  ListMembersByBranchPagedVariablesBuilder nameContains(String? t) {
    _nameContains.value = t;
    return this;
  }

  ListMembersByBranchPagedVariablesBuilder status(String? t) {
    _status.value = t;
    return this;
  }

  ListMembersByBranchPagedVariablesBuilder(
    this._dataConnect, {
    required this.branchId,
    required this.limit,
    required this.offset,
  });
  Deserializer<ListMembersByBranchPagedData> dataDeserializer = (
    dynamic json,
  ) => ListMembersByBranchPagedData.fromJson(jsonDecode(json));
  Serializer<ListMembersByBranchPagedVariables> varsSerializer = (
    ListMembersByBranchPagedVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<
    QueryResult<ListMembersByBranchPagedData, ListMembersByBranchPagedVariables>
  >
  execute() {
    return ref().execute();
  }

  QueryRef<ListMembersByBranchPagedData, ListMembersByBranchPagedVariables>
  ref() {
    ListMembersByBranchPagedVariables vars = ListMembersByBranchPagedVariables(
      branchId: branchId,
      limit: limit,
      offset: offset,
      nameContains: _nameContains,
      status: _status,
    );
    return _dataConnect.query(
      "ListMembersByBranchPaged",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class ListMembersByBranchPagedUserBranchAssignments {
  final ListMembersByBranchPagedUserBranchAssignmentsMember member;
  ListMembersByBranchPagedUserBranchAssignments.fromJson(dynamic json)
    : member = ListMembersByBranchPagedUserBranchAssignmentsMember.fromJson(
        json['member'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMembersByBranchPagedUserBranchAssignments otherTyped =
        other as ListMembersByBranchPagedUserBranchAssignments;
    return member == otherTyped.member;
  }

  @override
  int get hashCode => member.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['member'] = member.toJson();
    return json;
  }

  ListMembersByBranchPagedUserBranchAssignments({required this.member});
}

@immutable
class ListMembersByBranchPagedUserBranchAssignmentsMember {
  final String id;
  final String? authUid;
  final String fullName;
  final String username;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final List<
    ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMember
  >
  userBranchAssignments_on_member;
  ListMembersByBranchPagedUserBranchAssignmentsMember.fromJson(dynamic json)
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
                    ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMember.fromJson(
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

    final ListMembersByBranchPagedUserBranchAssignmentsMember otherTyped =
        other as ListMembersByBranchPagedUserBranchAssignmentsMember;
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

  ListMembersByBranchPagedUserBranchAssignmentsMember({
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
class ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMember {
  final ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMemberBranch
  branch;
  ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMember.fromJson(
    dynamic json,
  ) : branch =
          ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMemberBranch.fromJson(
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

    final ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMember
    otherTyped =
        other
            as ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMember;
    return branch == otherTyped.branch;
  }

  @override
  int get hashCode => branch.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branch'] = branch.toJson();
    return json;
  }

  ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMember({
    required this.branch,
  });
}

@immutable
class ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMemberBranch {
  final String id;
  ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMemberBranch.fromJson(
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

    final ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMemberBranch
    otherTyped =
        other
            as ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMemberBranch;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ListMembersByBranchPagedUserBranchAssignmentsMemberUserBranchAssignmentsOnMemberBranch({
    required this.id,
  });
}

@immutable
class ListMembersByBranchPagedTotal {
  final int count_;
  ListMembersByBranchPagedTotal.fromJson(dynamic json)
    : count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMembersByBranchPagedTotal otherTyped =
        other as ListMembersByBranchPagedTotal;
    return count_ == otherTyped.count_;
  }

  @override
  int get hashCode => count_.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  ListMembersByBranchPagedTotal({required this.count_});
}

@immutable
class ListMembersByBranchPagedData {
  final List<ListMembersByBranchPagedUserBranchAssignments>
  userBranchAssignments;
  final List<ListMembersByBranchPagedTotal> total;
  ListMembersByBranchPagedData.fromJson(dynamic json)
    : userBranchAssignments = (json['userBranchAssignments'] as List<dynamic>)
          .map((e) => ListMembersByBranchPagedUserBranchAssignments.fromJson(e))
          .toList(),
      total = (json['total'] as List<dynamic>)
          .map((e) => ListMembersByBranchPagedTotal.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMembersByBranchPagedData otherTyped =
        other as ListMembersByBranchPagedData;
    return userBranchAssignments == otherTyped.userBranchAssignments &&
        total == otherTyped.total;
  }

  @override
  int get hashCode =>
      Object.hashAll([userBranchAssignments.hashCode, total.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userBranchAssignments'] = userBranchAssignments
        .map((e) => e.toJson())
        .toList();
    json['total'] = total.map((e) => e.toJson()).toList();
    return json;
  }

  ListMembersByBranchPagedData({
    required this.userBranchAssignments,
    required this.total,
  });
}

@immutable
class ListMembersByBranchPagedVariables {
  final String branchId;
  final int limit;
  final int offset;
  late final Optional<String> nameContains;
  late final Optional<String> status;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  ListMembersByBranchPagedVariables.fromJson(Map<String, dynamic> json)
    : branchId = nativeFromJson<String>(json['branchId']),
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
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMembersByBranchPagedVariables otherTyped =
        other as ListMembersByBranchPagedVariables;
    return branchId == otherTyped.branchId &&
        limit == otherTyped.limit &&
        offset == otherTyped.offset &&
        nameContains == otherTyped.nameContains &&
        status == otherTyped.status;
  }

  @override
  int get hashCode => Object.hashAll([
    branchId.hashCode,
    limit.hashCode,
    offset.hashCode,
    nameContains.hashCode,
    status.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branchId'] = nativeToJson<String>(branchId);
    json['limit'] = nativeToJson<int>(limit);
    json['offset'] = nativeToJson<int>(offset);
    if (nameContains.state == OptionalState.set) {
      json['nameContains'] = nameContains.toJson();
    }
    if (status.state == OptionalState.set) {
      json['status'] = status.toJson();
    }
    return json;
  }

  ListMembersByBranchPagedVariables({
    required this.branchId,
    required this.limit,
    required this.offset,
    required this.nameContains,
    required this.status,
  });
}
