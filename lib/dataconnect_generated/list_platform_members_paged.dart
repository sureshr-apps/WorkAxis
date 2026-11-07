part of 'workaxis_connector.dart';

class ListPlatformMembersPagedVariablesBuilder {
  int limit;
  int offset;
  Optional<String> _nameContains = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  ListPlatformMembersPagedVariablesBuilder nameContains(String? t) {
    _nameContains.value = t;
    return this;
  }

  ListPlatformMembersPagedVariablesBuilder status(String? t) {
    _status.value = t;
    return this;
  }

  ListPlatformMembersPagedVariablesBuilder(
    this._dataConnect, {
    required this.limit,
    required this.offset,
  });
  Deserializer<ListPlatformMembersPagedData> dataDeserializer = (
    dynamic json,
  ) => ListPlatformMembersPagedData.fromJson(jsonDecode(json));
  Serializer<ListPlatformMembersPagedVariables> varsSerializer = (
    ListPlatformMembersPagedVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<
    QueryResult<ListPlatformMembersPagedData, ListPlatformMembersPagedVariables>
  >
  execute() {
    return ref().execute();
  }

  QueryRef<ListPlatformMembersPagedData, ListPlatformMembersPagedVariables>
  ref() {
    ListPlatformMembersPagedVariables vars = ListPlatformMembersPagedVariables(
      limit: limit,
      offset: offset,
      nameContains: _nameContains,
      status: _status,
    );
    return _dataConnect.query(
      "ListPlatformMembersPaged",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class ListPlatformMembersPagedOrganizationMembers {
  final String id;
  final String? authUid;
  final String fullName;
  final String username;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final Timestamp createdAt;
  ListPlatformMembersPagedOrganizationMembers.fromJson(dynamic json)
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
      createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListPlatformMembersPagedOrganizationMembers otherTyped =
        other as ListPlatformMembersPagedOrganizationMembers;
    return id == otherTyped.id &&
        authUid == otherTyped.authUid &&
        fullName == otherTyped.fullName &&
        username == otherTyped.username &&
        email == otherTyped.email &&
        phone == otherTyped.phone &&
        role == otherTyped.role &&
        status == otherTyped.status &&
        createdAt == otherTyped.createdAt;
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
    return json;
  }

  ListPlatformMembersPagedOrganizationMembers({
    required this.id,
    this.authUid,
    required this.fullName,
    required this.username,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
  });
}

@immutable
class ListPlatformMembersPagedTotal {
  final int count_;
  ListPlatformMembersPagedTotal.fromJson(dynamic json)
    : count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListPlatformMembersPagedTotal otherTyped =
        other as ListPlatformMembersPagedTotal;
    return count_ == otherTyped.count_;
  }

  @override
  int get hashCode => count_.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  ListPlatformMembersPagedTotal({required this.count_});
}

@immutable
class ListPlatformMembersPagedData {
  final List<ListPlatformMembersPagedOrganizationMembers> organizationMembers;
  final List<ListPlatformMembersPagedTotal> total;
  ListPlatformMembersPagedData.fromJson(dynamic json)
    : organizationMembers = (json['organizationMembers'] as List<dynamic>)
          .map((e) => ListPlatformMembersPagedOrganizationMembers.fromJson(e))
          .toList(),
      total = (json['total'] as List<dynamic>)
          .map((e) => ListPlatformMembersPagedTotal.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListPlatformMembersPagedData otherTyped =
        other as ListPlatformMembersPagedData;
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

  ListPlatformMembersPagedData({
    required this.organizationMembers,
    required this.total,
  });
}

@immutable
class ListPlatformMembersPagedVariables {
  final int limit;
  final int offset;
  late final Optional<String> nameContains;
  late final Optional<String> status;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  ListPlatformMembersPagedVariables.fromJson(Map<String, dynamic> json)
    : limit = nativeFromJson<int>(json['limit']),
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

    final ListPlatformMembersPagedVariables otherTyped =
        other as ListPlatformMembersPagedVariables;
    return limit == otherTyped.limit &&
        offset == otherTyped.offset &&
        nameContains == otherTyped.nameContains &&
        status == otherTyped.status;
  }

  @override
  int get hashCode => Object.hashAll([
    limit.hashCode,
    offset.hashCode,
    nameContains.hashCode,
    status.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
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

  ListPlatformMembersPagedVariables({
    required this.limit,
    required this.offset,
    required this.nameContains,
    required this.status,
  });
}
