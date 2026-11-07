part of 'workaxis_connector.dart';

class ListOrganizationsPagedVariablesBuilder {
  int limit;
  int offset;
  Optional<String> _nameContains = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  ListOrganizationsPagedVariablesBuilder nameContains(String? t) {
    _nameContains.value = t;
    return this;
  }

  ListOrganizationsPagedVariablesBuilder status(String? t) {
    _status.value = t;
    return this;
  }

  ListOrganizationsPagedVariablesBuilder(
    this._dataConnect, {
    required this.limit,
    required this.offset,
  });
  Deserializer<ListOrganizationsPagedData> dataDeserializer = (dynamic json) =>
      ListOrganizationsPagedData.fromJson(jsonDecode(json));
  Serializer<ListOrganizationsPagedVariables> varsSerializer = (
    ListOrganizationsPagedVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<
    QueryResult<ListOrganizationsPagedData, ListOrganizationsPagedVariables>
  >
  execute() {
    return ref().execute();
  }

  QueryRef<ListOrganizationsPagedData, ListOrganizationsPagedVariables> ref() {
    ListOrganizationsPagedVariables vars = ListOrganizationsPagedVariables(
      limit: limit,
      offset: offset,
      nameContains: _nameContains,
      status: _status,
    );
    return _dataConnect.query(
      "ListOrganizationsPaged",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class ListOrganizationsPagedOrganizations {
  final String id;
  final String name;
  final String code;
  final String? category;
  final String? country;
  final String status;
  final String? currency;
  final Timestamp createdAt;
  ListOrganizationsPagedOrganizations.fromJson(dynamic json)
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

    final ListOrganizationsPagedOrganizations otherTyped =
        other as ListOrganizationsPagedOrganizations;
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

  ListOrganizationsPagedOrganizations({
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
class ListOrganizationsPagedTotal {
  final int count_;
  ListOrganizationsPagedTotal.fromJson(dynamic json)
    : count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListOrganizationsPagedTotal otherTyped =
        other as ListOrganizationsPagedTotal;
    return count_ == otherTyped.count_;
  }

  @override
  int get hashCode => count_.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  ListOrganizationsPagedTotal({required this.count_});
}

@immutable
class ListOrganizationsPagedData {
  final List<ListOrganizationsPagedOrganizations> organizations;
  final List<ListOrganizationsPagedTotal> total;
  ListOrganizationsPagedData.fromJson(dynamic json)
    : organizations = (json['organizations'] as List<dynamic>)
          .map((e) => ListOrganizationsPagedOrganizations.fromJson(e))
          .toList(),
      total = (json['total'] as List<dynamic>)
          .map((e) => ListOrganizationsPagedTotal.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListOrganizationsPagedData otherTyped =
        other as ListOrganizationsPagedData;
    return organizations == otherTyped.organizations &&
        total == otherTyped.total;
  }

  @override
  int get hashCode => Object.hashAll([organizations.hashCode, total.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['organizations'] = organizations.map((e) => e.toJson()).toList();
    json['total'] = total.map((e) => e.toJson()).toList();
    return json;
  }

  ListOrganizationsPagedData({
    required this.organizations,
    required this.total,
  });
}

@immutable
class ListOrganizationsPagedVariables {
  final int limit;
  final int offset;
  late final Optional<String> nameContains;
  late final Optional<String> status;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  ListOrganizationsPagedVariables.fromJson(Map<String, dynamic> json)
    : limit = nativeFromJson<int>(json['limit']),
      offset = nativeFromJson<int>(json['offset']) {
    nameContains = Optional.optional(nativeFromJson, nativeToJson);
    nameContains.value = json['nameContains'] == null
        ? null
        : nativeFromJson<String>(json['nameContains']);

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

    final ListOrganizationsPagedVariables otherTyped =
        other as ListOrganizationsPagedVariables;
    return limit == otherTyped.limit &&
        offset == otherTyped.offset &&
        nameContains == otherTyped.nameContains &&
        status == otherTyped.status;
  }

  @override
  int get hashCode => Object.hashAll([
    limit.hashCode,
    offset.hashCode,
    nameContains.hashCode,
    status.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['limit'] = nativeToJson<int>(limit);
    json['offset'] = nativeToJson<int>(offset);
    if (nameContains.state == OptionalState.set) {
      json['nameContains'] = nameContains.toJson();
    }
    if (status.state == OptionalState.set) {
      json['status'] = status.toJson();
    }
    return json;
  }

  ListOrganizationsPagedVariables({
    required this.limit,
    required this.offset,
    required this.nameContains,
    required this.status,
  });
}
