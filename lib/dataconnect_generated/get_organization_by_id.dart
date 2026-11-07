part of 'workaxis_connector.dart';

class GetOrganizationByIdVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetOrganizationByIdVariablesBuilder(this._dataConnect, {required this.id});
  Deserializer<GetOrganizationByIdData> dataDeserializer = (dynamic json) =>
      GetOrganizationByIdData.fromJson(jsonDecode(json));
  Serializer<GetOrganizationByIdVariables> varsSerializer = (
    GetOrganizationByIdVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<QueryResult<GetOrganizationByIdData, GetOrganizationByIdVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<GetOrganizationByIdData, GetOrganizationByIdVariables> ref() {
    GetOrganizationByIdVariables vars = GetOrganizationByIdVariables(id: id);
    return _dataConnect.query(
      "GetOrganizationById",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetOrganizationByIdOrganization {
  final String id;
  final String name;
  final String code;
  final String? category;
  final String? country;
  final String status;
  final String? currency;
  final String? logoUrl;
  final String? taxIdentification;
  final String? description;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final Timestamp createdAt;
  GetOrganizationByIdOrganization.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      name = nativeFromJson<String>(json['name']),
      code = nativeFromJson<String>(json['code']),
      category = json['category'] == null
          ? null
          : nativeFromJson<String>(json['category']),
      country = json['country'] == null
          ? null
          : nativeFromJson<String>(json['country']),
      status = nativeFromJson<String>(json['status']),
      currency = json['currency'] == null
          ? null
          : nativeFromJson<String>(json['currency']),
      logoUrl = json['logoUrl'] == null
          ? null
          : nativeFromJson<String>(json['logoUrl']),
      taxIdentification = json['taxIdentification'] == null
          ? null
          : nativeFromJson<String>(json['taxIdentification']),
      description = json['description'] == null
          ? null
          : nativeFromJson<String>(json['description']),
      contactName = json['contactName'] == null
          ? null
          : nativeFromJson<String>(json['contactName']),
      contactEmail = json['contactEmail'] == null
          ? null
          : nativeFromJson<String>(json['contactEmail']),
      contactPhone = json['contactPhone'] == null
          ? null
          : nativeFromJson<String>(json['contactPhone']),
      address = json['address'] == null
          ? null
          : nativeFromJson<String>(json['address']),
      createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationByIdOrganization otherTyped =
        other as GetOrganizationByIdOrganization;
    return id == otherTyped.id &&
        name == otherTyped.name &&
        code == otherTyped.code &&
        category == otherTyped.category &&
        country == otherTyped.country &&
        status == otherTyped.status &&
        currency == otherTyped.currency &&
        logoUrl == otherTyped.logoUrl &&
        taxIdentification == otherTyped.taxIdentification &&
        description == otherTyped.description &&
        contactName == otherTyped.contactName &&
        contactEmail == otherTyped.contactEmail &&
        contactPhone == otherTyped.contactPhone &&
        address == otherTyped.address &&
        createdAt == otherTyped.createdAt;
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
    logoUrl.hashCode,
    taxIdentification.hashCode,
    description.hashCode,
    contactName.hashCode,
    contactEmail.hashCode,
    contactPhone.hashCode,
    address.hashCode,
    createdAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['code'] = nativeToJson<String>(code);
    if (category != null) {
      json['category'] = nativeToJson<String?>(category);
    }
    if (country != null) {
      json['country'] = nativeToJson<String?>(country);
    }
    json['status'] = nativeToJson<String>(status);
    if (currency != null) {
      json['currency'] = nativeToJson<String?>(currency);
    }
    if (logoUrl != null) {
      json['logoUrl'] = nativeToJson<String?>(logoUrl);
    }
    if (taxIdentification != null) {
      json['taxIdentification'] = nativeToJson<String?>(taxIdentification);
    }
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    if (contactName != null) {
      json['contactName'] = nativeToJson<String?>(contactName);
    }
    if (contactEmail != null) {
      json['contactEmail'] = nativeToJson<String?>(contactEmail);
    }
    if (contactPhone != null) {
      json['contactPhone'] = nativeToJson<String?>(contactPhone);
    }
    if (address != null) {
      json['address'] = nativeToJson<String?>(address);
    }
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  GetOrganizationByIdOrganization({
    required this.id,
    required this.name,
    required this.code,
    this.category,
    this.country,
    required this.status,
    this.currency,
    this.logoUrl,
    this.taxIdentification,
    this.description,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.address,
    required this.createdAt,
  });
}

@immutable
class GetOrganizationByIdData {
  final GetOrganizationByIdOrganization? organization;
  GetOrganizationByIdData.fromJson(dynamic json)
    : organization = json['organization'] == null
          ? null
          : GetOrganizationByIdOrganization.fromJson(json['organization']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationByIdData otherTyped = other as GetOrganizationByIdData;
    return organization == otherTyped.organization;
  }

  @override
  int get hashCode => organization.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (organization != null) {
      json['organization'] = organization!.toJson();
    }
    return json;
  }

  GetOrganizationByIdData({this.organization});
}

@immutable
class GetOrganizationByIdVariables {
  final String id;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetOrganizationByIdVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetOrganizationByIdVariables otherTyped =
        other as GetOrganizationByIdVariables;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetOrganizationByIdVariables({required this.id});
}
