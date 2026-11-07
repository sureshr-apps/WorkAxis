part of 'workaxis_connector.dart';

class CreateCommercialAgreementVariablesBuilder {
  String orgId;
  String agreementReference;
  String planName;
  String planTier;
  double negotiatedPrice;
  double annualMaintenancePrice;
  int maxStores;
  int maxUsers;
  DateTime startDate;
  DateTime expiryDate;
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  CreateCommercialAgreementVariablesBuilder status(String? t) {
    _status.value = t;
    return this;
  }

  CreateCommercialAgreementVariablesBuilder(
    this._dataConnect, {
    required this.orgId,
    required this.agreementReference,
    required this.planName,
    required this.planTier,
    required this.negotiatedPrice,
    required this.annualMaintenancePrice,
    required this.maxStores,
    required this.maxUsers,
    required this.startDate,
    required this.expiryDate,
  });
  Deserializer<CreateCommercialAgreementData> dataDeserializer = (
    dynamic json,
  ) => CreateCommercialAgreementData.fromJson(jsonDecode(json));
  Serializer<CreateCommercialAgreementVariables> varsSerializer = (
    CreateCommercialAgreementVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      CreateCommercialAgreementData,
      CreateCommercialAgreementVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<CreateCommercialAgreementData, CreateCommercialAgreementVariables>
  ref() {
    CreateCommercialAgreementVariables vars =
        CreateCommercialAgreementVariables(
          orgId: orgId,
          agreementReference: agreementReference,
          planName: planName,
          planTier: planTier,
          negotiatedPrice: negotiatedPrice,
          annualMaintenancePrice: annualMaintenancePrice,
          maxStores: maxStores,
          maxUsers: maxUsers,
          startDate: startDate,
          expiryDate: expiryDate,
          status: _status,
        );
    return _dataConnect.mutation(
      "CreateCommercialAgreement",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreateCommercialAgreementCommercialAgreementInsert {
  final String id;
  CreateCommercialAgreementCommercialAgreementInsert.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateCommercialAgreementCommercialAgreementInsert otherTyped =
        other as CreateCommercialAgreementCommercialAgreementInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateCommercialAgreementCommercialAgreementInsert({required this.id});
}

@immutable
class CreateCommercialAgreementData {
  final CreateCommercialAgreementCommercialAgreementInsert
  commercialAgreement_insert;
  CreateCommercialAgreementData.fromJson(dynamic json)
    : commercialAgreement_insert =
          CreateCommercialAgreementCommercialAgreementInsert.fromJson(
            json['commercialAgreement_insert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateCommercialAgreementData otherTyped =
        other as CreateCommercialAgreementData;
    return commercialAgreement_insert == otherTyped.commercialAgreement_insert;
  }

  @override
  int get hashCode => commercialAgreement_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['commercialAgreement_insert'] = commercialAgreement_insert.toJson();
    return json;
  }

  CreateCommercialAgreementData({required this.commercialAgreement_insert});
}

@immutable
class CreateCommercialAgreementVariables {
  final String orgId;
  final String agreementReference;
  final String planName;
  final String planTier;
  final double negotiatedPrice;
  final double annualMaintenancePrice;
  final int maxStores;
  final int maxUsers;
  final DateTime startDate;
  final DateTime expiryDate;
  late final Optional<String> status;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreateCommercialAgreementVariables.fromJson(Map<String, dynamic> json)
    : orgId = nativeFromJson<String>(json['orgId']),
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
      expiryDate = nativeFromJson<DateTime>(json['expiryDate']) {
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

    final CreateCommercialAgreementVariables otherTyped =
        other as CreateCommercialAgreementVariables;
    return orgId == otherTyped.orgId &&
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
    orgId.hashCode,
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
    json['orgId'] = nativeToJson<String>(orgId);
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
    if (status.state == OptionalState.set) {
      json['status'] = status.toJson();
    }
    return json;
  }

  CreateCommercialAgreementVariables({
    required this.orgId,
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
