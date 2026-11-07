part of 'workaxis_connector.dart';

class UpdateCommercialAgreementVariablesBuilder {
  String id;
  Optional<String> _planName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _planTier = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _negotiatedPrice = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<double> _annualMaintenancePrice = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<int> _maxStores = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _maxUsers = Optional.optional(nativeFromJson, nativeToJson);
  Optional<DateTime> _startDate = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<DateTime> _expiryDate = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  UpdateCommercialAgreementVariablesBuilder planName(String? t) {
    _planName.value = t;
    return this;
  }

  UpdateCommercialAgreementVariablesBuilder planTier(String? t) {
    _planTier.value = t;
    return this;
  }

  UpdateCommercialAgreementVariablesBuilder negotiatedPrice(double? t) {
    _negotiatedPrice.value = t;
    return this;
  }

  UpdateCommercialAgreementVariablesBuilder annualMaintenancePrice(double? t) {
    _annualMaintenancePrice.value = t;
    return this;
  }

  UpdateCommercialAgreementVariablesBuilder maxStores(int? t) {
    _maxStores.value = t;
    return this;
  }

  UpdateCommercialAgreementVariablesBuilder maxUsers(int? t) {
    _maxUsers.value = t;
    return this;
  }

  UpdateCommercialAgreementVariablesBuilder startDate(DateTime? t) {
    _startDate.value = t;
    return this;
  }

  UpdateCommercialAgreementVariablesBuilder expiryDate(DateTime? t) {
    _expiryDate.value = t;
    return this;
  }

  UpdateCommercialAgreementVariablesBuilder status(String? t) {
    _status.value = t;
    return this;
  }

  UpdateCommercialAgreementVariablesBuilder(
    this._dataConnect, {
    required this.id,
  });
  Deserializer<UpdateCommercialAgreementData> dataDeserializer = (
    dynamic json,
  ) => UpdateCommercialAgreementData.fromJson(jsonDecode(json));
  Serializer<UpdateCommercialAgreementVariables> varsSerializer = (
    UpdateCommercialAgreementVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      UpdateCommercialAgreementData,
      UpdateCommercialAgreementVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<UpdateCommercialAgreementData, UpdateCommercialAgreementVariables>
  ref() {
    UpdateCommercialAgreementVariables vars =
        UpdateCommercialAgreementVariables(
          id: id,
          planName: _planName,
          planTier: _planTier,
          negotiatedPrice: _negotiatedPrice,
          annualMaintenancePrice: _annualMaintenancePrice,
          maxStores: _maxStores,
          maxUsers: _maxUsers,
          startDate: _startDate,
          expiryDate: _expiryDate,
          status: _status,
        );
    return _dataConnect.mutation(
      "UpdateCommercialAgreement",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class UpdateCommercialAgreementCommercialAgreementUpdate {
  final String id;
  UpdateCommercialAgreementCommercialAgreementUpdate.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCommercialAgreementCommercialAgreementUpdate otherTyped =
        other as UpdateCommercialAgreementCommercialAgreementUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateCommercialAgreementCommercialAgreementUpdate({required this.id});
}

@immutable
class UpdateCommercialAgreementData {
  final UpdateCommercialAgreementCommercialAgreementUpdate?
  commercialAgreement_update;
  UpdateCommercialAgreementData.fromJson(dynamic json)
    : commercialAgreement_update = json['commercialAgreement_update'] == null
          ? null
          : UpdateCommercialAgreementCommercialAgreementUpdate.fromJson(
              json['commercialAgreement_update'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateCommercialAgreementData otherTyped =
        other as UpdateCommercialAgreementData;
    return commercialAgreement_update == otherTyped.commercialAgreement_update;
  }

  @override
  int get hashCode => commercialAgreement_update.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (commercialAgreement_update != null) {
      json['commercialAgreement_update'] = commercialAgreement_update!.toJson();
    }
    return json;
  }

  UpdateCommercialAgreementData({this.commercialAgreement_update});
}

@immutable
class UpdateCommercialAgreementVariables {
  final String id;
  late final Optional<String> planName;
  late final Optional<String> planTier;
  late final Optional<double> negotiatedPrice;
  late final Optional<double> annualMaintenancePrice;
  late final Optional<int> maxStores;
  late final Optional<int> maxUsers;
  late final Optional<DateTime> startDate;
  late final Optional<DateTime> expiryDate;
  late final Optional<String> status;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  UpdateCommercialAgreementVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']) {
    planName = Optional.optional(nativeFromJson, nativeToJson);
    planName.value = json['planName'] == null
        ? null
        : nativeFromJson<String>(json['planName']);

    planTier = Optional.optional(nativeFromJson, nativeToJson);
    planTier.value = json['planTier'] == null
        ? null
        : nativeFromJson<String>(json['planTier']);

    negotiatedPrice = Optional.optional(nativeFromJson, nativeToJson);
    negotiatedPrice.value = json['negotiatedPrice'] == null
        ? null
        : nativeFromJson<double>(json['negotiatedPrice']);

    annualMaintenancePrice = Optional.optional(nativeFromJson, nativeToJson);
    annualMaintenancePrice.value = json['annualMaintenancePrice'] == null
        ? null
        : nativeFromJson<double>(json['annualMaintenancePrice']);

    maxStores = Optional.optional(nativeFromJson, nativeToJson);
    maxStores.value = json['maxStores'] == null
        ? null
        : nativeFromJson<int>(json['maxStores']);

    maxUsers = Optional.optional(nativeFromJson, nativeToJson);
    maxUsers.value = json['maxUsers'] == null
        ? null
        : nativeFromJson<int>(json['maxUsers']);

    startDate = Optional.optional(nativeFromJson, nativeToJson);
    startDate.value = json['startDate'] == null
        ? null
        : nativeFromJson<DateTime>(json['startDate']);

    expiryDate = Optional.optional(nativeFromJson, nativeToJson);
    expiryDate.value = json['expiryDate'] == null
        ? null
        : nativeFromJson<DateTime>(json['expiryDate']);

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

    final UpdateCommercialAgreementVariables otherTyped =
        other as UpdateCommercialAgreementVariables;
    return id == otherTyped.id &&
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
    if (planName.state == OptionalState.set) {
      json['planName'] = planName.toJson();
    }
    if (planTier.state == OptionalState.set) {
      json['planTier'] = planTier.toJson();
    }
    if (negotiatedPrice.state == OptionalState.set) {
      json['negotiatedPrice'] = negotiatedPrice.toJson();
    }
    if (annualMaintenancePrice.state == OptionalState.set) {
      json['annualMaintenancePrice'] = annualMaintenancePrice.toJson();
    }
    if (maxStores.state == OptionalState.set) {
      json['maxStores'] = maxStores.toJson();
    }
    if (maxUsers.state == OptionalState.set) {
      json['maxUsers'] = maxUsers.toJson();
    }
    if (startDate.state == OptionalState.set) {
      json['startDate'] = startDate.toJson();
    }
    if (expiryDate.state == OptionalState.set) {
      json['expiryDate'] = expiryDate.toJson();
    }
    if (status.state == OptionalState.set) {
      json['status'] = status.toJson();
    }
    return json;
  }

  UpdateCommercialAgreementVariables({
    required this.id,
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
