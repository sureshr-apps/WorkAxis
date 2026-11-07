part of 'workaxis_connector.dart';

class CreateOrganizationVariablesBuilder {
  Optional<String> _id = Optional.optional(nativeFromJson, nativeToJson);
  String name;
  String code;
  Optional<String> _category = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _country = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _currency = Optional.optional(nativeFromJson, nativeToJson);
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
  CreateOrganizationVariablesBuilder id(String? t) {
    _id.value = t;
    return this;
  }

  CreateOrganizationVariablesBuilder category(String? t) {
    _category.value = t;
    return this;
  }

  CreateOrganizationVariablesBuilder country(String? t) {
    _country.value = t;
    return this;
  }

  CreateOrganizationVariablesBuilder status(String? t) {
    _status.value = t;
    return this;
  }

  CreateOrganizationVariablesBuilder currency(String? t) {
    _currency.value = t;
    return this;
  }

  CreateOrganizationVariablesBuilder taxIdentification(String? t) {
    _taxIdentification.value = t;
    return this;
  }

  CreateOrganizationVariablesBuilder description(String? t) {
    _description.value = t;
    return this;
  }

  CreateOrganizationVariablesBuilder contactName(String? t) {
    _contactName.value = t;
    return this;
  }

  CreateOrganizationVariablesBuilder contactEmail(String? t) {
    _contactEmail.value = t;
    return this;
  }

  CreateOrganizationVariablesBuilder contactPhone(String? t) {
    _contactPhone.value = t;
    return this;
  }

  CreateOrganizationVariablesBuilder address(String? t) {
    _address.value = t;
    return this;
  }

  CreateOrganizationVariablesBuilder(
    this._dataConnect, {
    required this.name,
    required this.code,
  });
  Deserializer<CreateOrganizationData> dataDeserializer = (dynamic json) =>
      CreateOrganizationData.fromJson(jsonDecode(json));
  Serializer<CreateOrganizationVariables> varsSerializer = (
    CreateOrganizationVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateOrganizationData, CreateOrganizationVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<CreateOrganizationData, CreateOrganizationVariables> ref() {
    CreateOrganizationVariables vars = CreateOrganizationVariables(
      id: _id,
      name: name,
      code: code,
      category: _category,
      country: _country,
      status: _status,
      currency: _currency,
      taxIdentification: _taxIdentification,
      description: _description,
      contactName: _contactName,
      contactEmail: _contactEmail,
      contactPhone: _contactPhone,
      address: _address,
    );
    return _dataConnect.mutation(
      "CreateOrganization",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreateOrganizationOrganizationInsert {
  final String id;
  CreateOrganizationOrganizationInsert.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateOrganizationOrganizationInsert otherTyped =
        other as CreateOrganizationOrganizationInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateOrganizationOrganizationInsert({required this.id});
}

@immutable
class CreateOrganizationData {
  final CreateOrganizationOrganizationInsert organization_insert;
  CreateOrganizationData.fromJson(dynamic json)
    : organization_insert = CreateOrganizationOrganizationInsert.fromJson(
        json['organization_insert'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateOrganizationData otherTyped = other as CreateOrganizationData;
    return organization_insert == otherTyped.organization_insert;
  }

  @override
  int get hashCode => organization_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['organization_insert'] = organization_insert.toJson();
    return json;
  }

  CreateOrganizationData({required this.organization_insert});
}

@immutable
class CreateOrganizationVariables {
  late final Optional<String> id;
  final String name;
  final String code;
  late final Optional<String> category;
  late final Optional<String> country;
  late final Optional<String> status;
  late final Optional<String> currency;
  late final Optional<String> taxIdentification;
  late final Optional<String> description;
  late final Optional<String> contactName;
  late final Optional<String> contactEmail;
  late final Optional<String> contactPhone;
  late final Optional<String> address;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreateOrganizationVariables.fromJson(Map<String, dynamic> json)
    : name = nativeFromJson<String>(json['name']),
      code = nativeFromJson<String>(json['code']) {
    id = Optional.optional(nativeFromJson, nativeToJson);
    id.value = json['id'] == null ? null : nativeFromJson<String>(json['id']);

    category = Optional.optional(nativeFromJson, nativeToJson);
    category.value = json['category'] == null
        ? null
        : nativeFromJson<String>(json['category']);

    country = Optional.optional(nativeFromJson, nativeToJson);
    country.value = json['country'] == null
        ? null
        : nativeFromJson<String>(json['country']);

    status = Optional.optional(nativeFromJson, nativeToJson);
    status.value = json['status'] == null
        ? null
        : nativeFromJson<String>(json['status']);

    currency = Optional.optional(nativeFromJson, nativeToJson);
    currency.value = json['currency'] == null
        ? null
        : nativeFromJson<String>(json['currency']);

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

    final CreateOrganizationVariables otherTyped =
        other as CreateOrganizationVariables;
    return id == otherTyped.id &&
        name == otherTyped.name &&
        code == otherTyped.code &&
        category == otherTyped.category &&
        country == otherTyped.country &&
        status == otherTyped.status &&
        currency == otherTyped.currency &&
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
    code.hashCode,
    category.hashCode,
    country.hashCode,
    status.hashCode,
    currency.hashCode,
    taxIdentification.hashCode,
    description.hashCode,
    contactName.hashCode,
    contactEmail.hashCode,
    contactPhone.hashCode,
    address.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (id.state == OptionalState.set) {
      json['id'] = id.toJson();
    }
    json['name'] = nativeToJson<String>(name);
    json['code'] = nativeToJson<String>(code);
    if (category.state == OptionalState.set) {
      json['category'] = category.toJson();
    }
    if (country.state == OptionalState.set) {
      json['country'] = country.toJson();
    }
    if (status.state == OptionalState.set) {
      json['status'] = status.toJson();
    }
    if (currency.state == OptionalState.set) {
      json['currency'] = currency.toJson();
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

  CreateOrganizationVariables({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.country,
    required this.status,
    required this.currency,
    required this.taxIdentification,
    required this.description,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.address,
  });
}
