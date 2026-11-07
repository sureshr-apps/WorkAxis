part of 'workaxis_connector.dart';

class ListOrganizationsVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  ListOrganizationsVariablesBuilder(this._dataConnect);
  Deserializer<ListOrganizationsData> dataDeserializer = (dynamic json) =>
      ListOrganizationsData.fromJson(jsonDecode(json));

  Future<QueryResult<ListOrganizationsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListOrganizationsData, void> ref() {
    return _dataConnect.query(
      "ListOrganizations",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class ListOrganizationsOrganizations {
  final String id;
  final String name;
  final String code;
  final String? category;
  final String? country;
  final String status;
  final String? currency;
  final Timestamp createdAt;
  ListOrganizationsOrganizations.fromJson(dynamic json)
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
      createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListOrganizationsOrganizations otherTyped =
        other as ListOrganizationsOrganizations;
    return id == otherTyped.id &&
        name == otherTyped.name &&
        code == otherTyped.code &&
        category == otherTyped.category &&
        country == otherTyped.country &&
        status == otherTyped.status &&
        currency == otherTyped.currency &&
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
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  ListOrganizationsOrganizations({
    required this.id,
    required this.name,
    required this.code,
    this.category,
    this.country,
    required this.status,
    this.currency,
    required this.createdAt,
  });
}

@immutable
class ListOrganizationsData {
  final List<ListOrganizationsOrganizations> organizations;
  ListOrganizationsData.fromJson(dynamic json)
    : organizations = (json['organizations'] as List<dynamic>)
          .map((e) => ListOrganizationsOrganizations.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListOrganizationsData otherTyped = other as ListOrganizationsData;
    return organizations == otherTyped.organizations;
  }

  @override
  int get hashCode => organizations.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['organizations'] = organizations.map((e) => e.toJson()).toList();
    return json;
  }

  ListOrganizationsData({required this.organizations});
}
