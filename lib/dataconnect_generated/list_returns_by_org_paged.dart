part of 'workaxis_connector.dart';

class ListReturnsByOrgPagedVariablesBuilder {
  String orgId;
  int limit;
  int offset;
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _branchId = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  ListReturnsByOrgPagedVariablesBuilder status(String? t) {
    _status.value = t;
    return this;
  }

  ListReturnsByOrgPagedVariablesBuilder branchId(String? t) {
    _branchId.value = t;
    return this;
  }

  ListReturnsByOrgPagedVariablesBuilder(
    this._dataConnect, {
    required this.orgId,
    required this.limit,
    required this.offset,
  });
  Deserializer<ListReturnsByOrgPagedData> dataDeserializer = (dynamic json) =>
      ListReturnsByOrgPagedData.fromJson(jsonDecode(json));
  Serializer<ListReturnsByOrgPagedVariables> varsSerializer = (
    ListReturnsByOrgPagedVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<QueryResult<ListReturnsByOrgPagedData, ListReturnsByOrgPagedVariables>>
  execute() {
    return ref().execute();
  }

  QueryRef<ListReturnsByOrgPagedData, ListReturnsByOrgPagedVariables> ref() {
    ListReturnsByOrgPagedVariables vars = ListReturnsByOrgPagedVariables(
      orgId: orgId,
      limit: limit,
      offset: offset,
      status: _status,
      branchId: _branchId,
    );
    return _dataConnect.query(
      "ListReturnsByOrgPaged",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class ListReturnsByOrgPagedReturnRecords {
  final String id;
  final ListReturnsByOrgPagedReturnRecordsBranch branch;
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
  ListReturnsByOrgPagedReturnRecords.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      branch = ListReturnsByOrgPagedReturnRecordsBranch.fromJson(
        json['branch'],
      ),
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

    final ListReturnsByOrgPagedReturnRecords otherTyped =
        other as ListReturnsByOrgPagedReturnRecords;
    return id == otherTyped.id &&
        branch == otherTyped.branch &&
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
    branch.hashCode,
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
    json['branch'] = branch.toJson();
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

  ListReturnsByOrgPagedReturnRecords({
    required this.id,
    required this.branch,
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
class ListReturnsByOrgPagedReturnRecordsBranch {
  final String id;
  final String name;
  ListReturnsByOrgPagedReturnRecordsBranch.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListReturnsByOrgPagedReturnRecordsBranch otherTyped =
        other as ListReturnsByOrgPagedReturnRecordsBranch;
    return id == otherTyped.id && name == otherTyped.name;
  }

  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  ListReturnsByOrgPagedReturnRecordsBranch({
    required this.id,
    required this.name,
  });
}

@immutable
class ListReturnsByOrgPagedTotal {
  final int count_;
  ListReturnsByOrgPagedTotal.fromJson(dynamic json)
    : count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListReturnsByOrgPagedTotal otherTyped =
        other as ListReturnsByOrgPagedTotal;
    return count_ == otherTyped.count_;
  }

  @override
  int get hashCode => count_.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  ListReturnsByOrgPagedTotal({required this.count_});
}

@immutable
class ListReturnsByOrgPagedData {
  final List<ListReturnsByOrgPagedReturnRecords> returnRecords;
  final List<ListReturnsByOrgPagedTotal> total;
  ListReturnsByOrgPagedData.fromJson(dynamic json)
    : returnRecords = (json['returnRecords'] as List<dynamic>)
          .map((e) => ListReturnsByOrgPagedReturnRecords.fromJson(e))
          .toList(),
      total = (json['total'] as List<dynamic>)
          .map((e) => ListReturnsByOrgPagedTotal.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListReturnsByOrgPagedData otherTyped =
        other as ListReturnsByOrgPagedData;
    return returnRecords == otherTyped.returnRecords &&
        total == otherTyped.total;
  }

  @override
  int get hashCode => Object.hashAll([returnRecords.hashCode, total.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['returnRecords'] = returnRecords.map((e) => e.toJson()).toList();
    json['total'] = total.map((e) => e.toJson()).toList();
    return json;
  }

  ListReturnsByOrgPagedData({required this.returnRecords, required this.total});
}

@immutable
class ListReturnsByOrgPagedVariables {
  final String orgId;
  final int limit;
  final int offset;
  late final Optional<String> status;
  late final Optional<String> branchId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  ListReturnsByOrgPagedVariables.fromJson(Map<String, dynamic> json)
    : orgId = nativeFromJson<String>(json['orgId']),
      limit = nativeFromJson<int>(json['limit']),
      offset = nativeFromJson<int>(json['offset']) {
    status = Optional.optional(nativeFromJson, nativeToJson);
    status.value = json['status'] == null
        ? null
        : nativeFromJson<String>(json['status']);

    branchId = Optional.optional(nativeFromJson, nativeToJson);
    branchId.value = json['branchId'] == null
        ? null
        : nativeFromJson<String>(json['branchId']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListReturnsByOrgPagedVariables otherTyped =
        other as ListReturnsByOrgPagedVariables;
    return orgId == otherTyped.orgId &&
        limit == otherTyped.limit &&
        offset == otherTyped.offset &&
        status == otherTyped.status &&
        branchId == otherTyped.branchId;
  }

  @override
  int get hashCode => Object.hashAll([
    orgId.hashCode,
    limit.hashCode,
    offset.hashCode,
    status.hashCode,
    branchId.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orgId'] = nativeToJson<String>(orgId);
    json['limit'] = nativeToJson<int>(limit);
    json['offset'] = nativeToJson<int>(offset);
    if (status.state == OptionalState.set) {
      json['status'] = status.toJson();
    }
    if (branchId.state == OptionalState.set) {
      json['branchId'] = branchId.toJson();
    }
    return json;
  }

  ListReturnsByOrgPagedVariables({
    required this.orgId,
    required this.limit,
    required this.offset,
    required this.status,
    required this.branchId,
  });
}
