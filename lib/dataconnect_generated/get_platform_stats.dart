part of 'workaxis_connector.dart';

class GetPlatformStatsVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  GetPlatformStatsVariablesBuilder(this._dataConnect);
  Deserializer<GetPlatformStatsData> dataDeserializer = (dynamic json) =>
      GetPlatformStatsData.fromJson(jsonDecode(json));

  Future<QueryResult<GetPlatformStatsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetPlatformStatsData, void> ref() {
    return _dataConnect.query(
      "GetPlatformStats",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class GetPlatformStatsOrganizationsByStatus {
  final String status;
  final int count_;
  GetPlatformStatsOrganizationsByStatus.fromJson(dynamic json)
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

    final GetPlatformStatsOrganizationsByStatus otherTyped =
        other as GetPlatformStatsOrganizationsByStatus;
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

  GetPlatformStatsOrganizationsByStatus({
    required this.status,
    required this.count_,
  });
}

@immutable
class GetPlatformStatsPlatformAdminCount {
  final int count_;
  GetPlatformStatsPlatformAdminCount.fromJson(dynamic json)
    : count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetPlatformStatsPlatformAdminCount otherTyped =
        other as GetPlatformStatsPlatformAdminCount;
    return count_ == otherTyped.count_;
  }

  @override
  int get hashCode => count_.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  GetPlatformStatsPlatformAdminCount({required this.count_});
}

@immutable
class GetPlatformStatsData {
  final List<GetPlatformStatsOrganizationsByStatus> organizationsByStatus;
  final List<GetPlatformStatsPlatformAdminCount> platformAdminCount;
  GetPlatformStatsData.fromJson(dynamic json)
    : organizationsByStatus = (json['organizationsByStatus'] as List<dynamic>)
          .map((e) => GetPlatformStatsOrganizationsByStatus.fromJson(e))
          .toList(),
      platformAdminCount = (json['platformAdminCount'] as List<dynamic>)
          .map((e) => GetPlatformStatsPlatformAdminCount.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetPlatformStatsData otherTyped = other as GetPlatformStatsData;
    return organizationsByStatus == otherTyped.organizationsByStatus &&
        platformAdminCount == otherTyped.platformAdminCount;
  }

  @override
  int get hashCode => Object.hashAll([
    organizationsByStatus.hashCode,
    platformAdminCount.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['organizationsByStatus'] = organizationsByStatus
        .map((e) => e.toJson())
        .toList();
    json['platformAdminCount'] = platformAdminCount
        .map((e) => e.toJson())
        .toList();
    return json;
  }

  GetPlatformStatsData({
    required this.organizationsByStatus,
    required this.platformAdminCount,
  });
}
