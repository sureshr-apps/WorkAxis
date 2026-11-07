part of 'workaxis_connector.dart';

class CreateLicenseEventVariablesBuilder {
  String orgId;
  String eventType;
  String planName;
  String planTier;
  String validityPeriod;
  int storesCount;
  int usersCount;
  double oneTimePrice;
  double annualMaintenancePrice;

  final FirebaseDataConnect _dataConnect;
  CreateLicenseEventVariablesBuilder(
    this._dataConnect, {
    required this.orgId,
    required this.eventType,
    required this.planName,
    required this.planTier,
    required this.validityPeriod,
    required this.storesCount,
    required this.usersCount,
    required this.oneTimePrice,
    required this.annualMaintenancePrice,
  });
  Deserializer<CreateLicenseEventData> dataDeserializer = (dynamic json) =>
      CreateLicenseEventData.fromJson(jsonDecode(json));
  Serializer<CreateLicenseEventVariables> varsSerializer = (
    CreateLicenseEventVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateLicenseEventData, CreateLicenseEventVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<CreateLicenseEventData, CreateLicenseEventVariables> ref() {
    CreateLicenseEventVariables vars = CreateLicenseEventVariables(
      orgId: orgId,
      eventType: eventType,
      planName: planName,
      planTier: planTier,
      validityPeriod: validityPeriod,
      storesCount: storesCount,
      usersCount: usersCount,
      oneTimePrice: oneTimePrice,
      annualMaintenancePrice: annualMaintenancePrice,
    );
    return _dataConnect.mutation(
      "CreateLicenseEvent",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreateLicenseEventLicenseEventInsert {
  final String id;
  CreateLicenseEventLicenseEventInsert.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateLicenseEventLicenseEventInsert otherTyped =
        other as CreateLicenseEventLicenseEventInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateLicenseEventLicenseEventInsert({required this.id});
}

@immutable
class CreateLicenseEventData {
  final CreateLicenseEventLicenseEventInsert licenseEvent_insert;
  CreateLicenseEventData.fromJson(dynamic json)
    : licenseEvent_insert = CreateLicenseEventLicenseEventInsert.fromJson(
        json['licenseEvent_insert'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateLicenseEventData otherTyped = other as CreateLicenseEventData;
    return licenseEvent_insert == otherTyped.licenseEvent_insert;
  }

  @override
  int get hashCode => licenseEvent_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['licenseEvent_insert'] = licenseEvent_insert.toJson();
    return json;
  }

  CreateLicenseEventData({required this.licenseEvent_insert});
}

@immutable
class CreateLicenseEventVariables {
  final String orgId;
  final String eventType;
  final String planName;
  final String planTier;
  final String validityPeriod;
  final int storesCount;
  final int usersCount;
  final double oneTimePrice;
  final double annualMaintenancePrice;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreateLicenseEventVariables.fromJson(Map<String, dynamic> json)
    : orgId = nativeFromJson<String>(json['orgId']),
      eventType = nativeFromJson<String>(json['eventType']),
      planName = nativeFromJson<String>(json['planName']),
      planTier = nativeFromJson<String>(json['planTier']),
      validityPeriod = nativeFromJson<String>(json['validityPeriod']),
      storesCount = nativeFromJson<int>(json['storesCount']),
      usersCount = nativeFromJson<int>(json['usersCount']),
      oneTimePrice = nativeFromJson<double>(json['oneTimePrice']),
      annualMaintenancePrice = nativeFromJson<double>(
        json['annualMaintenancePrice'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateLicenseEventVariables otherTyped =
        other as CreateLicenseEventVariables;
    return orgId == otherTyped.orgId &&
        eventType == otherTyped.eventType &&
        planName == otherTyped.planName &&
        planTier == otherTyped.planTier &&
        validityPeriod == otherTyped.validityPeriod &&
        storesCount == otherTyped.storesCount &&
        usersCount == otherTyped.usersCount &&
        oneTimePrice == otherTyped.oneTimePrice &&
        annualMaintenancePrice == otherTyped.annualMaintenancePrice;
  }

  @override
  int get hashCode => Object.hashAll([
    orgId.hashCode,
    eventType.hashCode,
    planName.hashCode,
    planTier.hashCode,
    validityPeriod.hashCode,
    storesCount.hashCode,
    usersCount.hashCode,
    oneTimePrice.hashCode,
    annualMaintenancePrice.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = nativeToJson<String>(orgId);
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
    return json;
  }

  CreateLicenseEventVariables({
    required this.orgId,
    required this.eventType,
    required this.planName,
    required this.planTier,
    required this.validityPeriod,
    required this.storesCount,
    required this.usersCount,
    required this.oneTimePrice,
    required this.annualMaintenancePrice,
  });
}
