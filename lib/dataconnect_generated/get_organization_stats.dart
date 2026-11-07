part of 'workaxis_connector.dart';

class GetOrganizationStatsVariablesBuilder {
  String orgId;

  final FirebaseDataConnect _dataConnect;
  GetOrganizationStatsVariablesBuilder(
    this._dataConnect, {
    required this.orgId,
  });
  Deserializer<GetOrganizationStatsData> dataDeserializer = (dynamic json) =>
      GetOrganizationStatsData.fromJson(jsonDecode(json));
  Serializer<GetOrganizationStatsVariables> varsSerializer = (
    GetOrganizationStatsVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<QueryResult<GetOrganizationStatsData, GetOrganizationStatsVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetOrganizationStatsData, GetOrganizationStatsVariables> ref() {
    GetOrganizationStatsVariables vars = GetOrganizationStatsVariables(
      orgId: orgId,
    );
    return _dataConnect.query(
      "GetOrganizationStats",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetOrganizationStatsBranchCount {
  final int count_;
  GetOrganizationStatsBranchCount.fromJson(dynamic json)
    : count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationStatsBranchCount otherTyped =
        other as GetOrganizationStatsBranchCount;
    return count_ == otherTyped.count_;
  }

  @override
  int get hashCode => count_.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  GetOrganizationStatsBranchCount({required this.count_});
}

@immutable
class GetOrganizationStatsMemberCount {
  final int count_;
  GetOrganizationStatsMemberCount.fromJson(dynamic json)
    : count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationStatsMemberCount otherTyped =
        other as GetOrganizationStatsMemberCount;
    return count_ == otherTyped.count_;
  }

  @override
  int get hashCode => count_.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  GetOrganizationStatsMemberCount({required this.count_});
}

@immutable
class GetOrganizationStatsData {
  final List<GetOrganizationStatsBranchCount> branchCount;
  final List<GetOrganizationStatsMemberCount> memberCount;
  GetOrganizationStatsData.fromJson(dynamic json)
    : branchCount = (json['branchCount'] as List<dynamic>)
          .map((e) => GetOrganizationStatsBranchCount.fromJson(e))
          .toList(),
      memberCount = (json['memberCount'] as List<dynamic>)
          .map((e) => GetOrganizationStatsMemberCount.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationStatsData otherTyped =
        other as GetOrganizationStatsData;
    return branchCount == otherTyped.branchCount &&
        memberCount == otherTyped.memberCount;
  }

  @override
  int get hashCode =>
      Object.hashAll([branchCount.hashCode, memberCount.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branchCount'] = branchCount.map((e) => e.toJson()).toList();
    json['memberCount'] = memberCount.map((e) => e.toJson()).toList();
    return json;
  }

  GetOrganizationStatsData({
    required this.branchCount,
    required this.memberCount,
  });
}

@immutable
class GetOrganizationStatsVariables {
  final String orgId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetOrganizationStatsVariables.fromJson(Map<String, dynamic> json)
    : orgId = nativeFromJson<String>(json['orgId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationStatsVariables otherTyped =
        other as GetOrganizationStatsVariables;
    return orgId == otherTyped.orgId;
  }

  @override
  int get hashCode => orgId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = nativeToJson<String>(orgId);
    return json;
  }

  GetOrganizationStatsVariables({required this.orgId});
}
