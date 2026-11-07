part of 'workaxis_connector.dart';

class ListReturnsByBranchVariablesBuilder {
  String branchId;

  final FirebaseDataConnect _dataConnect;
  ListReturnsByBranchVariablesBuilder(
    this._dataConnect, {
    required this.branchId,
  });
  Deserializer<ListReturnsByBranchData> dataDeserializer = (dynamic json) =>
      ListReturnsByBranchData.fromJson(jsonDecode(json));
  Serializer<ListReturnsByBranchVariables> varsSerializer = (
    ListReturnsByBranchVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<QueryResult<ListReturnsByBranchData, ListReturnsByBranchVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<ListReturnsByBranchData, ListReturnsByBranchVariables> ref() {
    ListReturnsByBranchVariables vars = ListReturnsByBranchVariables(
      branchId: branchId,
    );
    return _dataConnect.query(
      "ListReturnsByBranch",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class ListReturnsByBranchReturnRecords {
  final String id;
  final String employeeId;
  final String? employeeUid;
  final String employeeName;
  final String customerName;
  final String invoiceNumber;
  final String status;
  final String returnReason;
  final double amount;
  final String? productTitle;
  final double? quantity;
  final String? unit;
  final String? billImageUrl;
  final String? remarks;
  final String? reviewerNotes;
  final String? reviewerUid;
  final String? reviewerName;
  final Timestamp? reviewedAt;
  final Timestamp createdAt;
  ListReturnsByBranchReturnRecords.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      employeeId = nativeFromJson<String>(json['employeeId']),
      employeeUid = json['employeeUid'] == null
          ? null
          : nativeFromJson<String>(json['employeeUid']),
      employeeName = nativeFromJson<String>(json['employeeName']),
      customerName = nativeFromJson<String>(json['customerName']),
      invoiceNumber = nativeFromJson<String>(json['invoiceNumber']),
      status = nativeFromJson<String>(json['status']),
      returnReason = nativeFromJson<String>(json['returnReason']),
      amount = nativeFromJson<double>(json['amount']),
      productTitle = json['productTitle'] == null
          ? null
          : nativeFromJson<String>(json['productTitle']),
      quantity = json['quantity'] == null
          ? null
          : nativeFromJson<double>(json['quantity']),
      unit = json['unit'] == null ? null : nativeFromJson<String>(json['unit']),
      billImageUrl = json['billImageUrl'] == null
          ? null
          : nativeFromJson<String>(json['billImageUrl']),
      remarks = json['remarks'] == null
          ? null
          : nativeFromJson<String>(json['remarks']),
      reviewerNotes = json['reviewerNotes'] == null
          ? null
          : nativeFromJson<String>(json['reviewerNotes']),
      reviewerUid = json['reviewerUid'] == null
          ? null
          : nativeFromJson<String>(json['reviewerUid']),
      reviewerName = json['reviewerName'] == null
          ? null
          : nativeFromJson<String>(json['reviewerName']),
      reviewedAt = json['reviewedAt'] == null
          ? null
          : Timestamp.fromJson(json['reviewedAt']),
      createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListReturnsByBranchReturnRecords otherTyped =
        other as ListReturnsByBranchReturnRecords;
    return id == otherTyped.id &&
        employeeId == otherTyped.employeeId &&
        employeeUid == otherTyped.employeeUid &&
        employeeName == otherTyped.employeeName &&
        customerName == otherTyped.customerName &&
        invoiceNumber == otherTyped.invoiceNumber &&
        status == otherTyped.status &&
        returnReason == otherTyped.returnReason &&
        amount == otherTyped.amount &&
        productTitle == otherTyped.productTitle &&
        quantity == otherTyped.quantity &&
        unit == otherTyped.unit &&
        billImageUrl == otherTyped.billImageUrl &&
        remarks == otherTyped.remarks &&
        reviewerNotes == otherTyped.reviewerNotes &&
        reviewerUid == otherTyped.reviewerUid &&
        reviewerName == otherTyped.reviewerName &&
        reviewedAt == otherTyped.reviewedAt &&
        createdAt == otherTyped.createdAt;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    employeeId.hashCode,
    employeeUid.hashCode,
    employeeName.hashCode,
    customerName.hashCode,
    invoiceNumber.hashCode,
    status.hashCode,
    returnReason.hashCode,
    amount.hashCode,
    productTitle.hashCode,
    quantity.hashCode,
    unit.hashCode,
    billImageUrl.hashCode,
    remarks.hashCode,
    reviewerNotes.hashCode,
    reviewerUid.hashCode,
    reviewerName.hashCode,
    reviewedAt.hashCode,
    createdAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['employeeId'] = nativeToJson<String>(employeeId);
    if (employeeUid != null) {
      json['employeeUid'] = nativeToJson<String?>(employeeUid);
    }
    json['employeeName'] = nativeToJson<String>(employeeName);
    json['customerName'] = nativeToJson<String>(customerName);
    json['invoiceNumber'] = nativeToJson<String>(invoiceNumber);
    json['status'] = nativeToJson<String>(status);
    json['returnReason'] = nativeToJson<String>(returnReason);
    json['amount'] = nativeToJson<double>(amount);
    if (productTitle != null) {
      json['productTitle'] = nativeToJson<String?>(productTitle);
    }
    if (quantity != null) {
      json['quantity'] = nativeToJson<double?>(quantity);
    }
    if (unit != null) {
      json['unit'] = nativeToJson<String?>(unit);
    }
    if (billImageUrl != null) {
      json['billImageUrl'] = nativeToJson<String?>(billImageUrl);
    }
    if (remarks != null) {
      json['remarks'] = nativeToJson<String?>(remarks);
    }
    if (reviewerNotes != null) {
      json['reviewerNotes'] = nativeToJson<String?>(reviewerNotes);
    }
    if (reviewerUid != null) {
      json['reviewerUid'] = nativeToJson<String?>(reviewerUid);
    }
    if (reviewerName != null) {
      json['reviewerName'] = nativeToJson<String?>(reviewerName);
    }
    if (reviewedAt != null) {
      json['reviewedAt'] = reviewedAt!.toJson();
    }
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  ListReturnsByBranchReturnRecords({
    required this.id,
    required this.employeeId,
    this.employeeUid,
    required this.employeeName,
    required this.customerName,
    required this.invoiceNumber,
    required this.status,
    required this.returnReason,
    required this.amount,
    this.productTitle,
    this.quantity,
    this.unit,
    this.billImageUrl,
    this.remarks,
    this.reviewerNotes,
    this.reviewerUid,
    this.reviewerName,
    this.reviewedAt,
    required this.createdAt,
  });
}

@immutable
class ListReturnsByBranchData {
  final List<ListReturnsByBranchReturnRecords> returnRecords;
  ListReturnsByBranchData.fromJson(dynamic json)
    : returnRecords = (json['returnRecords'] as List<dynamic>)
          .map((e) => ListReturnsByBranchReturnRecords.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListReturnsByBranchData otherTyped = other as ListReturnsByBranchData;
    return returnRecords == otherTyped.returnRecords;
  }

  @override
  int get hashCode => returnRecords.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['returnRecords'] = returnRecords.map((e) => e.toJson()).toList();
    return json;
  }

  ListReturnsByBranchData({required this.returnRecords});
}

@immutable
class ListReturnsByBranchVariables {
  final String branchId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  ListReturnsByBranchVariables.fromJson(Map<String, dynamic> json)
    : branchId = nativeFromJson<String>(json['branchId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListReturnsByBranchVariables otherTyped =
        other as ListReturnsByBranchVariables;
    return branchId == otherTyped.branchId;
  }

  @override
  int get hashCode => branchId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branchId'] = nativeToJson<String>(branchId);
    return json;
  }

  ListReturnsByBranchVariables({required this.branchId});
}
