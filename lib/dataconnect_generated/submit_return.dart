part of 'workaxis_connector.dart';

class SubmitReturnVariablesBuilder {
  String branchId;
  String productTitle;
  String returnReason;
  double quantity;
  String unit;
  String invoiceNumber;
  Optional<String> _billImageUrl = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );
  Optional<String> _remarks = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  SubmitReturnVariablesBuilder billImageUrl(String? t) {
    _billImageUrl.value = t;
    return this;
  }

  SubmitReturnVariablesBuilder remarks(String? t) {
    _remarks.value = t;
    return this;
  }

  SubmitReturnVariablesBuilder(
    this._dataConnect, {
    required this.branchId,
    required this.productTitle,
    required this.returnReason,
    required this.quantity,
    required this.unit,
    required this.invoiceNumber,
  });
  Deserializer<SubmitReturnData> dataDeserializer = (dynamic json) =>
      SubmitReturnData.fromJson(jsonDecode(json));
  Serializer<SubmitReturnVariables> varsSerializer = (
    SubmitReturnVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<OperationResult<SubmitReturnData, SubmitReturnVariables>> execute() {
    return ref().execute();
  }

  MutationRef<SubmitReturnData, SubmitReturnVariables> ref() {
    SubmitReturnVariables vars = SubmitReturnVariables(
      branchId: branchId,
      productTitle: productTitle,
      returnReason: returnReason,
      quantity: quantity,
      unit: unit,
      invoiceNumber: invoiceNumber,
      billImageUrl: _billImageUrl,
      remarks: _remarks,
    );
    return _dataConnect.mutation(
      "SubmitReturn",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class SubmitReturnReturnRecordInsert {
  final String id;
  SubmitReturnReturnRecordInsert.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final SubmitReturnReturnRecordInsert otherTyped =
        other as SubmitReturnReturnRecordInsert;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  SubmitReturnReturnRecordInsert({required this.id});
}

@immutable
class SubmitReturnData {
  final SubmitReturnReturnRecordInsert returnRecord_insert;
  SubmitReturnData.fromJson(dynamic json)
    : returnRecord_insert = SubmitReturnReturnRecordInsert.fromJson(
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

    final SubmitReturnData otherTyped = other as SubmitReturnData;
    return returnRecord_insert == otherTyped.returnRecord_insert;
  }

  @override
  int get hashCode => returnRecord_insert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['returnRecord_insert'] = returnRecord_insert.toJson();
    return json;
  }

  SubmitReturnData({required this.returnRecord_insert});
}

@immutable
class SubmitReturnVariables {
  final String branchId;
  final String productTitle;
  final String returnReason;
  final double quantity;
  final String unit;
  final String invoiceNumber;
  late final Optional<String> billImageUrl;
  late final Optional<String> remarks;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  SubmitReturnVariables.fromJson(Map<String, dynamic> json)
    : branchId = nativeFromJson<String>(json['branchId']),
      productTitle = nativeFromJson<String>(json['productTitle']),
      returnReason = nativeFromJson<String>(json['returnReason']),
      quantity = nativeFromJson<double>(json['quantity']),
      unit = nativeFromJson<String>(json['unit']),
      invoiceNumber = nativeFromJson<String>(json['invoiceNumber']) {
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

    final SubmitReturnVariables otherTyped = other as SubmitReturnVariables;
    return branchId == otherTyped.branchId &&
        productTitle == otherTyped.productTitle &&
        returnReason == otherTyped.returnReason &&
        quantity == otherTyped.quantity &&
        unit == otherTyped.unit &&
        invoiceNumber == otherTyped.invoiceNumber &&
        billImageUrl == otherTyped.billImageUrl &&
        remarks == otherTyped.remarks;
  }

  @override
  int get hashCode => Object.hashAll([
    branchId.hashCode,
    productTitle.hashCode,
    returnReason.hashCode,
    quantity.hashCode,
    unit.hashCode,
    invoiceNumber.hashCode,
    billImageUrl.hashCode,
    remarks.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branchId'] = nativeToJson<String>(branchId);
    json['productTitle'] = nativeToJson<String>(productTitle);
    json['returnReason'] = nativeToJson<String>(returnReason);
    json['quantity'] = nativeToJson<double>(quantity);
    json['unit'] = nativeToJson<String>(unit);
    json['invoiceNumber'] = nativeToJson<String>(invoiceNumber);
    if (billImageUrl.state == OptionalState.set) {
      json['billImageUrl'] = billImageUrl.toJson();
    }
    if (remarks.state == OptionalState.set) {
      json['remarks'] = remarks.toJson();
    }
    return json;
  }

  SubmitReturnVariables({
    required this.branchId,
    required this.productTitle,
    required this.returnReason,
    required this.quantity,
    required this.unit,
    required this.invoiceNumber,
    required this.billImageUrl,
    required this.remarks,
  });
}
