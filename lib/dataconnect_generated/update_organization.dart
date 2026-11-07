part of 'workaxis_connector.dart';

class UpdateOrganizationVariablesBuilder {
  String id;
  Optional<String> _name = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _category = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _country = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _currency = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _logoUrl = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _taxIdentification = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<String> _description = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<String> _contactName = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<String> _contactEmail = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<String> _contactPhone = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<String> _address = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  UpdateOrganizationVariablesBuilder name(String? t) {
    _name.value = t;
    return this;
  }

  UpdateOrganizationVariablesBuilder status(String? t) {
    _status.value = t;
    return this;
  }

  UpdateOrganizationVariablesBuilder category(String? t) {
    _category.value = t;
    return this;
  }

  UpdateOrganizationVariablesBuilder country(String? t) {
    _country.value = t;
    return this;
  }

  UpdateOrganizationVariablesBuilder currency(String? t) {
    _currency.value = t;
    return this;
  }

  UpdateOrganizationVariablesBuilder logoUrl(String? t) {
    _logoUrl.value = t;
    return this;
  }

  UpdateOrganizationVariablesBuilder taxIdentification(String? t) {
    _taxIdentification.value = t;
    return this;
  }

  UpdateOrganizationVariablesBuilder description(String? t) {
    _description.value = t;
    return this;
  }

  UpdateOrganizationVariablesBuilder contactName(String? t) {
    _contactName.value = t;
    return this;
  }

  UpdateOrganizationVariablesBuilder contactEmail(String? t) {
    _contactEmail.value = t;
    return this;
  }

  UpdateOrganizationVariablesBuilder contactPhone(String? t) {
    _contactPhone.value = t;
    return this;
  }

  UpdateOrganizationVariablesBuilder address(String? t) {
    _address.value = t;
    return this;
  }

  UpdateOrganizationVariablesBuilder(this._dataConnect, {required this.id});
  Deserializer<UpdateOrganizationData> dataDeserializer = (dynamic json) =>
      UpdateOrganizationData.fromJson(jsonDecode(json));
  Serializer<UpdateOrganizationVariables> varsSerializer = (
    UpdateOrganizationVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateOrganizationData, UpdateOrganizationVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<UpdateOrganizationData, UpdateOrganizationVariables> ref() {
    UpdateOrganizationVariables vars = UpdateOrganizationVariables(
      id: id,
      name: _name,
      status: _status,
      category: _category,
      country: _country,
      currency: _currency,
      logoUrl: _logoUrl,
      taxIdentification: _taxIdentification,
      description: _description,
      contactName: _contactName,
      contactEmail: _contactEmail,
      contactPhone: _contactPhone,
      address: _address,
    );
    return _dataConnect.mutation(
      "UpdateOrganization",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class UpdateOrganizationOrganizationUpdate {
  final String id;
  UpdateOrganizationOrganizationUpdate.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateOrganizationOrganizationUpdate otherTyped =
        other as UpdateOrganizationOrganizationUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateOrganizationOrganizationUpdate({required this.id});
}

@immutable
class UpdateOrganizationData {
  final UpdateOrganizationOrganizationUpdate? organization_update;
  UpdateOrganizationData.fromJson(dynamic json)
    : organization_update = json['organization_update'] == null
          ? null
          : UpdateOrganizationOrganizationUpdate.fromJson(
              json['organization_update'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateOrganizationData otherTyped = other as UpdateOrganizationData;
    return organization_update == otherTyped.organization_update;
  }

  @override
  int get hashCode => organization_update.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (organization_update != null) {
      json['organization_update'] = organization_update!.toJson();
    }
    return json;
  }

  UpdateOrganizationData({this.organization_update});
}

@immutable
class UpdateOrganizationVariables {
  final String id;
  late final Optional<String> name;
  late final Optional<String> status;
  late final Optional<String> category;
  late final Optional<String> country;
  late final Optional<String> currency;
  late final Optional<String> logoUrl;
  late final Optional<String> taxIdentification;
  late final Optional<String> description;
  late final Optional<String> contactName;
  late final Optional<String> contactEmail;
  late final Optional<String> contactPhone;
  late final Optional<String> address;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  UpdateOrganizationVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']) {
    name = Optional.optional(nativeFromJson, nativeToJson);
    name.value = json['name'] == null
        ? null
        : nativeFromJson<String>(json['name']);

    status = Optional.optional(nativeFromJson, nativeToJson);
    status.value = json['status'] == null
        ? null
        : nativeFromJson<String>(json['status']);

    category = Optional.optional(nativeFromJson, nativeToJson);
    category.value = json['category'] == null
        ? null
        : nativeFromJson<String>(json['category']);

    country = Optional.optional(nativeFromJson, nativeToJson);
    country.value = json['country'] == null
        ? null
        : nativeFromJson<String>(json['country']);

    currency = Optional.optional(nativeFromJson, nativeToJson);
    currency.value = json['currency'] == null
        ? null
        : nativeFromJson<String>(json['currency']);

    logoUrl = Optional.optional(nativeFromJson, nativeToJson);
    logoUrl.value = json['logoUrl'] == null
        ? null
        : nativeFromJson<String>(json['logoUrl']);

    taxIdentification = Optional.optional(nativeFromJson, nativeToJson);
    taxIdentification.value = json['taxIdentification'] == null
        ? null
        : nativeFromJson<String>(json['taxIdentification']);

    description = Optional.optional(nativeFromJson, nativeToJson);
    description.value = json['description'] == null
        ? null
        : nativeFromJson<String>(json['description']);

    contactName = Optional.optional(nativeFromJson, nativeToJson);
    contactName.value = json['contactName'] == null
        ? null
        : nativeFromJson<String>(json['contactName']);

    contactEmail = Optional.optional(nativeFromJson, nativeToJson);
    contactEmail.value = json['contactEmail'] == null
        ? null
        : nativeFromJson<String>(json['contactEmail']);

    contactPhone = Optional.optional(nativeFromJson, nativeToJson);
    contactPhone.value = json['contactPhone'] == null
        ? null
        : nativeFromJson<String>(json['contactPhone']);

    address = Optional.optional(nativeFromJson, nativeToJson);
    address.value = json['address'] == null
        ? null
        : nativeFromJson<String>(json['address']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateOrganizationVariables otherTyped =
        other as UpdateOrganizationVariables;
    return id == otherTyped.id &&
        name == otherTyped.name &&
        status == otherTyped.status &&
        category == otherTyped.category &&
        country == otherTyped.country &&
        currency == otherTyped.currency &&
        logoUrl == otherTyped.logoUrl &&
        taxIdentification == otherTyped.taxIdentification &&
        description == otherTyped.description &&
        contactName == otherTyped.contactName &&
        contactEmail == otherTyped.contactEmail &&
        contactPhone == otherTyped.contactPhone &&
        address == otherTyped.address;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    name.hashCode,
    status.hashCode,
    category.hashCode,
    country.hashCode,
    currency.hashCode,
    logoUrl.hashCode,
    taxIdentification.hashCode,
    description.hashCode,
    contactName.hashCode,
    contactEmail.hashCode,
    contactPhone.hashCode,
    address.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (name.state == OptionalState.set) {
      json['name'] = name.toJson();
    }
    if (status.state == OptionalState.set) {
      json['status'] = status.toJson();
    }
    if (category.state == OptionalState.set) {
      json['category'] = category.toJson();
    }
    if (country.state == OptionalState.set) {
      json['country'] = country.toJson();
    }
    if (currency.state == OptionalState.set) {
      json['currency'] = currency.toJson();
    }
    if (logoUrl.state == OptionalState.set) {
      json['logoUrl'] = logoUrl.toJson();
    }
    if (taxIdentification.state == OptionalState.set) {
      json['taxIdentification'] = taxIdentification.toJson();
    }
    if (description.state == OptionalState.set) {
      json['description'] = description.toJson();
    }
    if (contactName.state == OptionalState.set) {
      json['contactName'] = contactName.toJson();
    }
    if (contactEmail.state == OptionalState.set) {
      json['contactEmail'] = contactEmail.toJson();
    }
    if (contactPhone.state == OptionalState.set) {
      json['contactPhone'] = contactPhone.toJson();
    }
    if (address.state == OptionalState.set) {
      json['address'] = address.toJson();
    }
    return json;
  }

  UpdateOrganizationVariables({
    required this.id,
    required this.name,
    required this.status,
    required this.category,
    required this.country,
    required this.currency,
    required this.logoUrl,
    required this.taxIdentification,
    required this.description,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.address,
  });
}
