part of 'workaxis_connector.dart';

class GetCommercialAgreementByOrgVariablesBuilder {
  String orgId;

  final FirebaseDataConnect _dataConnect;
  GetCommercialAgreementByOrgVariablesBuilder(
    this._dataConnect, {
    required this.orgId,
  });
  Deserializer<GetCommercialAgreementByOrgData> dataDeserializer = (
    dynamic json,
  ) => GetCommercialAgreementByOrgData.fromJson(jsonDecode(json));
  Serializer<GetCommercialAgreementByOrgVariables> varsSerializer = (
    GetCommercialAgreementByOrgVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<
    QueryResult<
      GetCommercialAgreementByOrgData,
      GetCommercialAgreementByOrgVariables
    >
  >
  execute() {
    return ref().execute();
  }

  QueryRef<
    GetCommercialAgreementByOrgData,
    GetCommercialAgreementByOrgVariables
  >
  ref() {
    GetCommercialAgreementByOrgVariables vars =
        GetCommercialAgreementByOrgVariables(orgId: orgId);
    return _dataConnect.query(
      "GetCommercialAgreementByOrg",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetCommercialAgreementByOrgCommercialAgreements {
  final String id;
  final String agreementReference;
  final String planName;
  final String planTier;
  final double negotiatedPrice;
  final double annualMaintenancePrice;
  final int maxStores;
  final int maxUsers;
  final DateTime startDate;
  final DateTime expiryDate;
  final String status;
  GetCommercialAgreementByOrgCommercialAgreements.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      agreementReference = nativeFromJson<String>(json['agreementReference']),
      planName = nativeFromJson<String>(json['planName']),
      planTier = nativeFromJson<String>(json['planTier']),
      negotiatedPrice = nativeFromJson<double>(json['negotiatedPrice']),
      annualMaintenancePrice = nativeFromJson<double>(
        json['annualMaintenancePrice'],
      ),
      maxStores = nativeFromJson<int>(json['maxStores']),
      maxUsers = nativeFromJson<int>(json['maxUsers']),
      startDate = nativeFromJson<DateTime>(json['startDate']),
      expiryDate = nativeFromJson<DateTime>(json['expiryDate']),
      status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetCommercialAgreementByOrgCommercialAgreements otherTyped =
        other as GetCommercialAgreementByOrgCommercialAgreements;
    return id == otherTyped.id &&
        agreementReference == otherTyped.agreementReference &&
        planName == otherTyped.planName &&
        planTier == otherTyped.planTier &&
        negotiatedPrice == otherTyped.negotiatedPrice &&
        annualMaintenancePrice == otherTyped.annualMaintenancePrice &&
        maxStores == otherTyped.maxStores &&
        maxUsers == otherTyped.maxUsers &&
        startDate == otherTyped.startDate &&
        expiryDate == otherTyped.expiryDate &&
        status == otherTyped.status;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    agreementReference.hashCode,
    planName.hashCode,
    planTier.hashCode,
    negotiatedPrice.hashCode,
    annualMaintenancePrice.hashCode,
    maxStores.hashCode,
    maxUsers.hashCode,
    startDate.hashCode,
    expiryDate.hashCode,
    status.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['agreementReference'] = nativeToJson<String>(agreementReference);
    json['planName'] = nativeToJson<String>(planName);
    json['planTier'] = nativeToJson<String>(planTier);
    json['negotiatedPrice'] = nativeToJson<double>(negotiatedPrice);
    json['annualMaintenancePrice'] = nativeToJson<double>(
      annualMaintenancePrice,
    );
    json['maxStores'] = nativeToJson<int>(maxStores);
    json['maxUsers'] = nativeToJson<int>(maxUsers);
    json['startDate'] = nativeToJson<DateTime>(startDate);
    json['expiryDate'] = nativeToJson<DateTime>(expiryDate);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  GetCommercialAgreementByOrgCommercialAgreements({
    required this.id,
    required this.agreementReference,
    required this.planName,
    required this.planTier,
    required this.negotiatedPrice,
    required this.annualMaintenancePrice,
    required this.maxStores,
    required this.maxUsers,
    required this.startDate,
    required this.expiryDate,
    required this.status,
  });
}

@immutable
class GetCommercialAgreementByOrgData {
  final List<GetCommercialAgreementByOrgCommercialAgreements>
  commercialAgreements;
  GetCommercialAgreementByOrgData.fromJson(dynamic json)
    : commercialAgreements = (json['commercialAgreements'] as List<dynamic>)
          .map(
            (e) => GetCommercialAgreementByOrgCommercialAgreements.fromJson(e),
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

    final GetCommercialAgreementByOrgData otherTyped =
        other as GetCommercialAgreementByOrgData;
    return commercialAgreements == otherTyped.commercialAgreements;
  }

  @override
  int get hashCode => commercialAgreements.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['commercialAgreements'] = commercialAgreements
        .map((e) => e.toJson())
        .toList();
    return json;
  }

  GetCommercialAgreementByOrgData({required this.commercialAgreements});
}

@immutable
class GetCommercialAgreementByOrgVariables {
  final String orgId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetCommercialAgreementByOrgVariables.fromJson(Map<String, dynamic> json)
    : orgId = nativeFromJson<String>(json['orgId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetCommercialAgreementByOrgVariables otherTyped =
        other as GetCommercialAgreementByOrgVariables;
    return orgId == otherTyped.orgId;
  }

  @override
  int get hashCode => orgId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = nativeToJson<String>(orgId);
    return json;
  }

  GetCommercialAgreementByOrgVariables({required this.orgId});
}
