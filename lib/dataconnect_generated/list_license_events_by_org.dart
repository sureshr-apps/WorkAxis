part of 'workaxis_connector.dart';

class ListLicenseEventsByOrgVariablesBuilder {
  String orgId;

  final FirebaseDataConnect _dataConnect;
  ListLicenseEventsByOrgVariablesBuilder(
    this._dataConnect, {
    required this.orgId,
  });
  Deserializer<ListLicenseEventsByOrgData> dataDeserializer = (dynamic json) =>
      ListLicenseEventsByOrgData.fromJson(jsonDecode(json));
  Serializer<ListLicenseEventsByOrgVariables> varsSerializer = (
    ListLicenseEventsByOrgVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<
    QueryResult<ListLicenseEventsByOrgData, ListLicenseEventsByOrgVariables>
  >
  execute() {
    return ref().execute();
  }

  QueryRef<ListLicenseEventsByOrgData, ListLicenseEventsByOrgVariables> ref() {
    ListLicenseEventsByOrgVariables vars = ListLicenseEventsByOrgVariables(
      orgId: orgId,
    );
    return _dataConnect.query(
      "ListLicenseEventsByOrg",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class ListLicenseEventsByOrgLicenseEvents {
  final String id;
  final String eventType;
  final String planName;
  final String planTier;
  final String validityPeriod;
  final int storesCount;
  final int usersCount;
  final double oneTimePrice;
  final double annualMaintenancePrice;
  final Timestamp createdAt;
  ListLicenseEventsByOrgLicenseEvents.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      eventType = nativeFromJson<String>(json['eventType']),
      planName = nativeFromJson<String>(json['planName']),
      planTier = nativeFromJson<String>(json['planTier']),
      validityPeriod = nativeFromJson<String>(json['validityPeriod']),
      storesCount = nativeFromJson<int>(json['storesCount']),
      usersCount = nativeFromJson<int>(json['usersCount']),
      oneTimePrice = nativeFromJson<double>(json['oneTimePrice']),
      annualMaintenancePrice = nativeFromJson<double>(
        json['annualMaintenancePrice'],
      ),
      createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListLicenseEventsByOrgLicenseEvents otherTyped =
        other as ListLicenseEventsByOrgLicenseEvents;
    return id == otherTyped.id &&
        eventType == otherTyped.eventType &&
        planName == otherTyped.planName &&
        planTier == otherTyped.planTier &&
        validityPeriod == otherTyped.validityPeriod &&
        storesCount == otherTyped.storesCount &&
        usersCount == otherTyped.usersCount &&
        oneTimePrice == otherTyped.oneTimePrice &&
        annualMaintenancePrice == otherTyped.annualMaintenancePrice &&
        createdAt == otherTyped.createdAt;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    eventType.hashCode,
    planName.hashCode,
    planTier.hashCode,
    validityPeriod.hashCode,
    storesCount.hashCode,
    usersCount.hashCode,
    oneTimePrice.hashCode,
    annualMaintenancePrice.hashCode,
    createdAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['eventType'] = nativeToJson<String>(eventType);
    json['planName'] = nativeToJson<String>(planName);
    json['planTier'] = nativeToJson<String>(planTier);
    json['validityPeriod'] = nativeToJson<String>(validityPeriod);
    json['storesCount'] = nativeToJson<int>(storesCount);
    json['usersCount'] = nativeToJson<int>(usersCount);
    json['oneTimePrice'] = nativeToJson<double>(oneTimePrice);
    json['annualMaintenancePrice'] = nativeToJson<double>(
      annualMaintenancePrice,
    );
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  ListLicenseEventsByOrgLicenseEvents({
    required this.id,
    required this.eventType,
    required this.planName,
    required this.planTier,
    required this.validityPeriod,
    required this.storesCount,
    required this.usersCount,
    required this.oneTimePrice,
    required this.annualMaintenancePrice,
    required this.createdAt,
  });
}

@immutable
class ListLicenseEventsByOrgData {
  final List<ListLicenseEventsByOrgLicenseEvents> licenseEvents;
  ListLicenseEventsByOrgData.fromJson(dynamic json)
    : licenseEvents = (json['licenseEvents'] as List<dynamic>)
          .map((e) => ListLicenseEventsByOrgLicenseEvents.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListLicenseEventsByOrgData otherTyped =
        other as ListLicenseEventsByOrgData;
    return licenseEvents == otherTyped.licenseEvents;
  }

  @override
  int get hashCode => licenseEvents.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['licenseEvents'] = licenseEvents.map((e) => e.toJson()).toList();
    return json;
  }

  ListLicenseEventsByOrgData({required this.licenseEvents});
}

@immutable
class ListLicenseEventsByOrgVariables {
  final String orgId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  ListLicenseEventsByOrgVariables.fromJson(Map<String, dynamic> json)
    : orgId = nativeFromJson<String>(json['orgId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListLicenseEventsByOrgVariables otherTyped =
        other as ListLicenseEventsByOrgVariables;
    return orgId == otherTyped.orgId;
  }

  @override
  int get hashCode => orgId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = nativeToJson<String>(orgId);
    return json;
  }

  ListLicenseEventsByOrgVariables({required this.orgId});
}
