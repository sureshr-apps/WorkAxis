part of 'workaxis_connector.dart';

class GetOrganizationDashboardCountsVariablesBuilder {
  String orgId;

  final FirebaseDataConnect _dataConnect;
  GetOrganizationDashboardCountsVariablesBuilder(
    this._dataConnect, {
    required this.orgId,
  });
  Deserializer<GetOrganizationDashboardCountsData> dataDeserializer = (
    dynamic json,
  ) => GetOrganizationDashboardCountsData.fromJson(jsonDecode(json));
  Serializer<GetOrganizationDashboardCountsVariables> varsSerializer = (
    GetOrganizationDashboardCountsVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<
    QueryResult<
      GetOrganizationDashboardCountsData,
      GetOrganizationDashboardCountsVariables
    >
  >
  execute() {
    return ref().execute();
  }

  QueryRef<
    GetOrganizationDashboardCountsData,
    GetOrganizationDashboardCountsVariables
  >
  ref() {
    GetOrganizationDashboardCountsVariables vars =
        GetOrganizationDashboardCountsVariables(orgId: orgId);
    return _dataConnect.query(
      "GetOrganizationDashboardCounts",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetOrganizationDashboardCountsBranchesByStatus {
  final String status;
  final int count_;
  GetOrganizationDashboardCountsBranchesByStatus.fromJson(dynamic json)
    : status = nativeFromJson<String>(json['status']),
      count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationDashboardCountsBranchesByStatus otherTyped =
        other as GetOrganizationDashboardCountsBranchesByStatus;
    return status == otherTyped.status && count_ == otherTyped.count_;
  }

  @override
  int get hashCode => Object.hashAll([status.hashCode, count_.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['status'] = nativeToJson<String>(status);
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  GetOrganizationDashboardCountsBranchesByStatus({
    required this.status,
    required this.count_,
  });
}

@immutable
class GetOrganizationDashboardCountsMembersByRole {
  final String role;
  final String status;
  final int count_;
  GetOrganizationDashboardCountsMembersByRole.fromJson(dynamic json)
    : role = nativeFromJson<String>(json['role']),
      status = nativeFromJson<String>(json['status']),
      count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationDashboardCountsMembersByRole otherTyped =
        other as GetOrganizationDashboardCountsMembersByRole;
    return role == otherTyped.role &&
        status == otherTyped.status &&
        count_ == otherTyped.count_;
  }

  @override
  int get hashCode =>
      Object.hashAll([role.hashCode, status.hashCode, count_.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['role'] = nativeToJson<String>(role);
    json['status'] = nativeToJson<String>(status);
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  GetOrganizationDashboardCountsMembersByRole({
    required this.role,
    required this.status,
    required this.count_,
  });
}

@immutable
class GetOrganizationDashboardCountsReturnsByStatus {
  final String status;
  final int count_;
  GetOrganizationDashboardCountsReturnsByStatus.fromJson(dynamic json)
    : status = nativeFromJson<String>(json['status']),
      count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationDashboardCountsReturnsByStatus otherTyped =
        other as GetOrganizationDashboardCountsReturnsByStatus;
    return status == otherTyped.status && count_ == otherTyped.count_;
  }

  @override
  int get hashCode => Object.hashAll([status.hashCode, count_.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['status'] = nativeToJson<String>(status);
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  GetOrganizationDashboardCountsReturnsByStatus({
    required this.status,
    required this.count_,
  });
}

@immutable
class GetOrganizationDashboardCountsData {
  final List<GetOrganizationDashboardCountsBranchesByStatus> branchesByStatus;
  final List<GetOrganizationDashboardCountsMembersByRole> membersByRole;
  final List<GetOrganizationDashboardCountsReturnsByStatus> returnsByStatus;
  GetOrganizationDashboardCountsData.fromJson(dynamic json)
    : branchesByStatus = (json['branchesByStatus'] as List<dynamic>)
          .map(
            (e) => GetOrganizationDashboardCountsBranchesByStatus.fromJson(e),
          )
          .toList(),
      membersByRole = (json['membersByRole'] as List<dynamic>)
          .map((e) => GetOrganizationDashboardCountsMembersByRole.fromJson(e))
          .toList(),
      returnsByStatus = (json['returnsByStatus'] as List<dynamic>)
          .map((e) => GetOrganizationDashboardCountsReturnsByStatus.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationDashboardCountsData otherTyped =
        other as GetOrganizationDashboardCountsData;
    return branchesByStatus == otherTyped.branchesByStatus &&
        membersByRole == otherTyped.membersByRole &&
        returnsByStatus == otherTyped.returnsByStatus;
  }

  @override
  int get hashCode => Object.hashAll([
    branchesByStatus.hashCode,
    membersByRole.hashCode,
    returnsByStatus.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branchesByStatus'] = branchesByStatus.map((e) => e.toJson()).toList();
    json['membersByRole'] = membersByRole.map((e) => e.toJson()).toList();
    json['returnsByStatus'] = returnsByStatus.map((e) => e.toJson()).toList();
    return json;
  }

  GetOrganizationDashboardCountsData({
    required this.branchesByStatus,
    required this.membersByRole,
    required this.returnsByStatus,
  });
}

@immutable
class GetOrganizationDashboardCountsVariables {
  final String orgId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetOrganizationDashboardCountsVariables.fromJson(Map<String, dynamic> json)
    : orgId = nativeFromJson<String>(json['orgId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationDashboardCountsVariables otherTyped =
        other as GetOrganizationDashboardCountsVariables;
    return orgId == otherTyped.orgId;
  }

  @override
  int get hashCode => orgId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = nativeToJson<String>(orgId);
    return json;
  }

  GetOrganizationDashboardCountsVariables({required this.orgId});
}
