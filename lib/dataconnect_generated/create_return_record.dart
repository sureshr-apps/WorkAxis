part of 'workaxis_connector.dart';

class CreateReturnRecordVariablesBuilder {
  String id;
  String orgId;
  String branchId;
  String employeeId;
  String employeeName;
  String customerName;
  String invoiceNumber;
  String returnReason;
  double amount;
  Optional<String> _productTitle = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<double> _quantity = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _unit = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _billImageUrl = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<String> _remarks = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  CreateReturnRecordVariablesBuilder productTitle(String? t) {
    _productTitle.value = t;
    return this;
  }

  CreateReturnRecordVariablesBuilder quantity(double? t) {
    _quantity.value = t;
    return this;
  }

  CreateReturnRecordVariablesBuilder unit(String? t) {
    _unit.value = t;
    return this;
  }

  CreateReturnRecordVariablesBuilder billImageUrl(String? t) {
    _billImageUrl.value = t;
    return this;
  }

  CreateReturnRecordVariablesBuilder remarks(String? t) {
    _remarks.value = t;
    return this;
  }

  CreateReturnRecordVariablesBuilder(
    this._dataConnect, {
    required this.id,
    required this.orgId,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    required this.customerName,
    required this.invoiceNumber,
    required this.returnReason,
    required this.amount,
  });
  Deserializer<CreateReturnRecordData> dataDeserializer = (dynamic json) =>
      CreateReturnRecordData.fromJson(jsonDecode(json));
  Serializer<CreateReturnRecordVariables> varsSerializer = (
    CreateReturnRecordVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateReturnRecordData, CreateReturnRecordVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<CreateReturnRecordData, CreateReturnRecordVariables> ref() {
    CreateReturnRecordVariables vars = CreateReturnRecordVariables(
      id: id,
      orgId: orgId,
      branchId: branchId,
      employeeId: employeeId,
      employeeName: employeeName,
      customerName: customerName,
      invoiceNumber: invoiceNumber,
      returnReason: returnReason,
      amount: amount,
      productTitle: _productTitle,
      quantity: _quantity,
      unit: _unit,
      billImageUrl: _billImageUrl,
      remarks: _remarks,
    );
    return _dataConnect.mutation(
      "CreateReturnRecord",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class CreateReturnRecordReturnRecordInsert {
  final String id;
  CreateReturnRecordReturnRecordInsert.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateReturnRecordReturnRecordInsert otherTyped =
        other as CreateReturnRecordReturnRecordInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateReturnRecordReturnRecordInsert({required this.id});
}

@immutable
class CreateReturnRecordData {
  final CreateReturnRecordReturnRecordInsert returnRecord_insert;
  CreateReturnRecordData.fromJson(dynamic json)
    : returnRecord_insert = CreateReturnRecordReturnRecordInsert.fromJson(
        json['returnRecord_insert'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateReturnRecordData otherTyped = other as CreateReturnRecordData;
    return returnRecord_insert == otherTyped.returnRecord_insert;
  }

  @override
  int get hashCode => returnRecord_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['returnRecord_insert'] = returnRecord_insert.toJson();
    return json;
  }

  CreateReturnRecordData({required this.returnRecord_insert});
}

@immutable
class CreateReturnRecordVariables {
  final String id;
  final String orgId;
  final String branchId;
  final String employeeId;
  final String employeeName;
  final String customerName;
  final String invoiceNumber;
  final String returnReason;
  final double amount;
  late final Optional<String> productTitle;
  late final Optional<double> quantity;
  late final Optional<String> unit;
  late final Optional<String> billImageUrl;
  late final Optional<String> remarks;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  CreateReturnRecordVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']),
      orgId = nativeFromJson<String>(json['orgId']),
      branchId = nativeFromJson<String>(json['branchId']),
      employeeId = nativeFromJson<String>(json['employeeId']),
      employeeName = nativeFromJson<String>(json['employeeName']),
      customerName = nativeFromJson<String>(json['customerName']),
      invoiceNumber = nativeFromJson<String>(json['invoiceNumber']),
      returnReason = nativeFromJson<String>(json['returnReason']),
      amount = nativeFromJson<double>(json['amount']) {
    productTitle = Optional.optional(nativeFromJson, nativeToJson);
    productTitle.value = json['productTitle'] == null
        ? null
        : nativeFromJson<String>(json['productTitle']);

    quantity = Optional.optional(nativeFromJson, nativeToJson);
    quantity.value = json['quantity'] == null
        ? null
        : nativeFromJson<double>(json['quantity']);

    unit = Optional.optional(nativeFromJson, nativeToJson);
    unit.value = json['unit'] == null
        ? null
        : nativeFromJson<String>(json['unit']);

    billImageUrl = Optional.optional(nativeFromJson, nativeToJson);
    billImageUrl.value = json['billImageUrl'] == null
        ? null
        : nativeFromJson<String>(json['billImageUrl']);

    remarks = Optional.optional(nativeFromJson, nativeToJson);
    remarks.value = json['remarks'] == null
        ? null
        : nativeFromJson<String>(json['remarks']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final CreateReturnRecordVariables otherTyped =
        other as CreateReturnRecordVariables;
    return id == otherTyped.id &&
        orgId == otherTyped.orgId &&
        branchId == otherTyped.branchId &&
        employeeId == otherTyped.employeeId &&
        employeeName == otherTyped.employeeName &&
        customerName == otherTyped.customerName &&
        invoiceNumber == otherTyped.invoiceNumber &&
        returnReason == otherTyped.returnReason &&
        amount == otherTyped.amount &&
        productTitle == otherTyped.productTitle &&
        quantity == otherTyped.quantity &&
        unit == otherTyped.unit &&
        billImageUrl == otherTyped.billImageUrl &&
        remarks == otherTyped.remarks;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    orgId.hashCode,
    branchId.hashCode,
    employeeId.hashCode,
    employeeName.hashCode,
    customerName.hashCode,
    invoiceNumber.hashCode,
    returnReason.hashCode,
    amount.hashCode,
    productTitle.hashCode,
    quantity.hashCode,
    unit.hashCode,
    billImageUrl.hashCode,
    remarks.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['orgId'] = nativeToJson<String>(orgId);
    json['branchId'] = nativeToJson<String>(branchId);
    json['employeeId'] = nativeToJson<String>(employeeId);
    json['employeeName'] = nativeToJson<String>(employeeName);
    json['customerName'] = nativeToJson<String>(customerName);
    json['invoiceNumber'] = nativeToJson<String>(invoiceNumber);
    json['returnReason'] = nativeToJson<String>(returnReason);
    json['amount'] = nativeToJson<double>(amount);
    if (productTitle.state == OptionalState.set) {
      json['productTitle'] = productTitle.toJson();
    }
    if (quantity.state == OptionalState.set) {
      json['quantity'] = quantity.toJson();
    }
    if (unit.state == OptionalState.set) {
      json['unit'] = unit.toJson();
    }
    if (billImageUrl.state == OptionalState.set) {
      json['billImageUrl'] = billImageUrl.toJson();
    }
    if (remarks.state == OptionalState.set) {
      json['remarks'] = remarks.toJson();
    }
    return json;
  }

  CreateReturnRecordVariables({
    required this.id,
    required this.orgId,
    required this.branchId,
    required this.employeeId,
    required this.employeeName,
    required this.customerName,
    required this.invoiceNumber,
    required this.returnReason,
    required this.amount,
    required this.productTitle,
    required this.quantity,
    required this.unit,
    required this.billImageUrl,
    required this.remarks,
  });
}
