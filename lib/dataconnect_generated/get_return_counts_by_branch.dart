part of 'workaxis_connector.dart';

class GetReturnCountsByBranchVariablesBuilder {
  String orgId;
  Optional<Timestamp> _from = Optional.optional(
    (json) => json['from'] = Timestamp.fromJson(json['from']),
    defaultSerializer,
  );
  Optional<Timestamp> _to = Optional.optional(
    (json) => json['to'] = Timestamp.fromJson(json['to']),
    defaultSerializer,
  );

  final FirebaseDataConnect _dataConnect;
  GetReturnCountsByBranchVariablesBuilder from(Timestamp? t) {
    _from.value = t;
    return this;
  }

  GetReturnCountsByBranchVariablesBuilder to(Timestamp? t) {
    _to.value = t;
    return this;
  }

  GetReturnCountsByBranchVariablesBuilder(
    this._dataConnect, {
    required this.orgId,
  });
  Deserializer<GetReturnCountsByBranchData> dataDeserializer = (dynamic json) =>
      GetReturnCountsByBranchData.fromJson(jsonDecode(json));
  Serializer<GetReturnCountsByBranchVariables> varsSerializer = (
    GetReturnCountsByBranchVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<
    QueryResult<GetReturnCountsByBranchData, GetReturnCountsByBranchVariables>
  >
  execute() {
    return ref().execute();
  }

  QueryRef<GetReturnCountsByBranchData, GetReturnCountsByBranchVariables>
  ref() {
    GetReturnCountsByBranchVariables vars = GetReturnCountsByBranchVariables(
      orgId: orgId,
      from: _from,
      to: _to,
    );
    return _dataConnect.query(
      "GetReturnCountsByBranch",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetReturnCountsByBranchReturnRecords {
  final String branchId;
  final String status;
  final int count_;
  GetReturnCountsByBranchReturnRecords.fromJson(dynamic json)
    : branchId = nativeFromJson<String>(json['branchId']),
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

    final GetReturnCountsByBranchReturnRecords otherTyped =
        other as GetReturnCountsByBranchReturnRecords;
    return branchId == otherTyped.branchId &&
        status == otherTyped.status &&
        count_ == otherTyped.count_;
  }

  @override
  int get hashCode =>
      Object.hashAll([branchId.hashCode, status.hashCode, count_.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branchId'] = nativeToJson<String>(branchId);
    json['status'] = nativeToJson<String>(status);
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  GetReturnCountsByBranchReturnRecords({
    required this.branchId,
    required this.status,
    required this.count_,
  });
}

@immutable
class GetReturnCountsByBranchReturnsByReason {
  final String returnReason;
  final int count_;
  GetReturnCountsByBranchReturnsByReason.fromJson(dynamic json)
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

    final GetReturnCountsByBranchReturnsByReason otherTyped =
        other as GetReturnCountsByBranchReturnsByReason;
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

  GetReturnCountsByBranchReturnsByReason({
    required this.returnReason,
    required this.count_,
  });
}

@immutable
class GetReturnCountsByBranchData {
  final List<GetReturnCountsByBranchReturnRecords> returnRecords;
  final List<GetReturnCountsByBranchReturnsByReason> returnsByReason;
  GetReturnCountsByBranchData.fromJson(dynamic json)
    : returnRecords = (json['returnRecords'] as List<dynamic>)
          .map((e) => GetReturnCountsByBranchReturnRecords.fromJson(e))
          .toList(),
      returnsByReason = (json['returnsByReason'] as List<dynamic>)
          .map((e) => GetReturnCountsByBranchReturnsByReason.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetReturnCountsByBranchData otherTyped =
        other as GetReturnCountsByBranchData;
    return returnRecords == otherTyped.returnRecords &&
        returnsByReason == otherTyped.returnsByReason;
  }

  @override
  int get hashCode =>
      Object.hashAll([returnRecords.hashCode, returnsByReason.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['returnRecords'] = returnRecords.map((e) => e.toJson()).toList();
    json['returnsByReason'] = returnsByReason.map((e) => e.toJson()).toList();
    return json;
  }

  GetReturnCountsByBranchData({
    required this.returnRecords,
    required this.returnsByReason,
  });
}

@immutable
class GetReturnCountsByBranchVariables {
  final String orgId;
  late final Optional<Timestamp> from;
  late final Optional<Timestamp> to;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetReturnCountsByBranchVariables.fromJson(Map<String, dynamic> json)
    : orgId = nativeFromJson<String>(json['orgId']) {
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

    final GetReturnCountsByBranchVariables otherTyped =
        other as GetReturnCountsByBranchVariables;
    return orgId == otherTyped.orgId &&
        from == otherTyped.from &&
        to == otherTyped.to;
  }

  @override
  int get hashCode =>
      Object.hashAll([orgId.hashCode, from.hashCode, to.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = nativeToJson<String>(orgId);
    if (from.state == OptionalState.set) {
      json['from'] = from.toJson();
    }
    if (to.state == OptionalState.set) {
      json['to'] = to.toJson();
    }
    return json;
  }

  GetReturnCountsByBranchVariables({
    required this.orgId,
    required this.from,
    required this.to,
  });
}
