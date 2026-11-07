part of 'workaxis_connector.dart';

class GetBranchStatsVariablesBuilder {
  String branchId;
  Optional<Timestamp> _from = Optional.optional(
    (json) => json['from'] = Timestamp.fromJson(json['from']),
    defaultSerializer,
  );
  Optional<Timestamp> _to = Optional.optional(
    (json) => json['to'] = Timestamp.fromJson(json['to']),
    defaultSerializer,
  );

  final FirebaseDataConnect _dataConnect;
  GetBranchStatsVariablesBuilder from(Timestamp? t) {
    _from.value = t;
    return this;
  }

  GetBranchStatsVariablesBuilder to(Timestamp? t) {
    _to.value = t;
    return this;
  }

  GetBranchStatsVariablesBuilder(this._dataConnect, {required this.branchId});
  Deserializer<GetBranchStatsData> dataDeserializer = (dynamic json) =>
      GetBranchStatsData.fromJson(jsonDecode(json));
  Serializer<GetBranchStatsVariables> varsSerializer = (
    GetBranchStatsVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<QueryResult<GetBranchStatsData, GetBranchStatsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetBranchStatsData, GetBranchStatsVariables> ref() {
    GetBranchStatsVariables vars = GetBranchStatsVariables(
      branchId: branchId,
      from: _from,
      to: _to,
    );
    return _dataConnect.query(
      "GetBranchStats",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetBranchStatsMemberCount {
  final int count_;
  GetBranchStatsMemberCount.fromJson(dynamic json)
    : count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBranchStatsMemberCount otherTyped =
        other as GetBranchStatsMemberCount;
    return count_ == otherTyped.count_;
  }

  @override
  int get hashCode => count_.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  GetBranchStatsMemberCount({required this.count_});
}

@immutable
class GetBranchStatsReturnsByStatus {
  final String status;
  final int count_;
  GetBranchStatsReturnsByStatus.fromJson(dynamic json)
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

    final GetBranchStatsReturnsByStatus otherTyped =
        other as GetBranchStatsReturnsByStatus;
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

  GetBranchStatsReturnsByStatus({required this.status, required this.count_});
}

@immutable
class GetBranchStatsReturnsByReason {
  final String returnReason;
  final int count_;
  GetBranchStatsReturnsByReason.fromJson(dynamic json)
    : returnReason = nativeFromJson<String>(json['returnReason']),
      count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBranchStatsReturnsByReason otherTyped =
        other as GetBranchStatsReturnsByReason;
    return returnReason == otherTyped.returnReason &&
        count_ == otherTyped.count_;
  }

  @override
  int get hashCode => Object.hashAll([returnReason.hashCode, count_.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['returnReason'] = nativeToJson<String>(returnReason);
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  GetBranchStatsReturnsByReason({
    required this.returnReason,
    required this.count_,
  });
}

@immutable
class GetBranchStatsData {
  final List<GetBranchStatsMemberCount> memberCount;
  final List<GetBranchStatsReturnsByStatus> returnsByStatus;
  final List<GetBranchStatsReturnsByReason> returnsByReason;
  GetBranchStatsData.fromJson(dynamic json)
    : memberCount = (json['memberCount'] as List<dynamic>)
          .map((e) => GetBranchStatsMemberCount.fromJson(e))
          .toList(),
      returnsByStatus = (json['returnsByStatus'] as List<dynamic>)
          .map((e) => GetBranchStatsReturnsByStatus.fromJson(e))
          .toList(),
      returnsByReason = (json['returnsByReason'] as List<dynamic>)
          .map((e) => GetBranchStatsReturnsByReason.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBranchStatsData otherTyped = other as GetBranchStatsData;
    return memberCount == otherTyped.memberCount &&
        returnsByStatus == otherTyped.returnsByStatus &&
        returnsByReason == otherTyped.returnsByReason;
  }

  @override
  int get hashCode => Object.hashAll([
    memberCount.hashCode,
    returnsByStatus.hashCode,
    returnsByReason.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['memberCount'] = memberCount.map((e) => e.toJson()).toList();
    json['returnsByStatus'] = returnsByStatus.map((e) => e.toJson()).toList();
    json['returnsByReason'] = returnsByReason.map((e) => e.toJson()).toList();
    return json;
  }

  GetBranchStatsData({
    required this.memberCount,
    required this.returnsByStatus,
    required this.returnsByReason,
  });
}

@immutable
class GetBranchStatsVariables {
  final String branchId;
  late final Optional<Timestamp> from;
  late final Optional<Timestamp> to;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetBranchStatsVariables.fromJson(Map<String, dynamic> json)
    : branchId = nativeFromJson<String>(json['branchId']) {
    from = Optional.optional(
      (json) => json['from'] = Timestamp.fromJson(json['from']),
      defaultSerializer,
    );
    from.value = json['from'] == null ? null : Timestamp.fromJson(json['from']);

    to = Optional.optional(
      (json) => json['to'] = Timestamp.fromJson(json['to']),
      defaultSerializer,
    );
    to.value = json['to'] == null ? null : Timestamp.fromJson(json['to']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetBranchStatsVariables otherTyped = other as GetBranchStatsVariables;
    return branchId == otherTyped.branchId &&
        from == otherTyped.from &&
        to == otherTyped.to;
  }

  @override
  int get hashCode =>
      Object.hashAll([branchId.hashCode, from.hashCode, to.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branchId'] = nativeToJson<String>(branchId);
    if (from.state == OptionalState.set) {
      json['from'] = from.toJson();
    }
    if (to.state == OptionalState.set) {
      json['to'] = to.toJson();
    }
    return json;
  }

  GetBranchStatsVariables({
    required this.branchId,
    required this.from,
    required this.to,
  });
}
