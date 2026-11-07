part of 'workaxis_connector.dart';

class CreateOrganizationVariablesBuilder {
  String id;
  String name;
  String code;
  Optional<String> _category = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _country = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _currency = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreateOrganizationVariablesBuilder category(String? t) {
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

  CreateOrganizationVariablesBuilder(this._dataConnect, {required  this.id,required  this.name,required  this.code,});
  Deserializer<CreateOrganizationData> dataDeserializer = (dynamic json)  => CreateOrganizationData.fromJson(jsonDecode(json));
  Serializer<CreateOrganizationVariables> varsSerializer = (CreateOrganizationVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateOrganizationData, CreateOrganizationVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateOrganizationData, CreateOrganizationVariables> ref() {
    CreateOrganizationVariables vars= CreateOrganizationVariables(id: id,name: name,code: code,category: _category,country: _country,status: _status,currency: _currency,);
    return _dataConnect.mutation("CreateOrganization", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateOrganizationOrganizationInsert {
  final String id;
  CreateOrganizationOrganizationInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateOrganizationOrganizationInsert otherTyped = other as CreateOrganizationOrganizationInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateOrganizationOrganizationInsert({
    required this.id,
  });
}

@immutable
class CreateOrganizationData {
  final CreateOrganizationOrganizationInsert organization_insert;
  CreateOrganizationData.fromJson(dynamic json):
  
  organization_insert = CreateOrganizationOrganizationInsert.fromJson(json['organization_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
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

  CreateOrganizationData({
    required this.organization_insert,
  });
}

@immutable
class CreateOrganizationVariables {
  final String id;
  final String name;
  final String code;
  late final Optional<String>category;
  late final Optional<String>country;
  late final Optional<String>status;
  late final Optional<String>currency;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateOrganizationVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  code = nativeFromJson<String>(json['code']) {
  
  
  
  
  
    category = Optional.optional(nativeFromJson, nativeToJson);
    category.value = json['category'] == null ? null : nativeFromJson<String>(json['category']);
  
  
    country = Optional.optional(nativeFromJson, nativeToJson);
    country.value = json['country'] == null ? null : nativeFromJson<String>(json['country']);
  
  
    status = Optional.optional(nativeFromJson, nativeToJson);
    status.value = json['status'] == null ? null : nativeFromJson<String>(json['status']);
  
  
    currency = Optional.optional(nativeFromJson, nativeToJson);
    currency.value = json['currency'] == null ? null : nativeFromJson<String>(json['currency']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateOrganizationVariables otherTyped = other as CreateOrganizationVariables;
    return id == otherTyped.id && 
    name == otherTyped.name && 
    code == otherTyped.code && 
    category == otherTyped.category && 
    country == otherTyped.country && 
    status == otherTyped.status && 
    currency == otherTyped.currency;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, code.hashCode, category.hashCode, country.hashCode, status.hashCode, currency.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['code'] = nativeToJson<String>(code);
    if(category.state == OptionalState.set) {
      json['category'] = category.toJson();
    }
    if(country.state == OptionalState.set) {
      json['country'] = country.toJson();
    }
    if(status.state == OptionalState.set) {
      json['status'] = status.toJson();
    }
    if(currency.state == OptionalState.set) {
      json['currency'] = currency.toJson();
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
  });
}

