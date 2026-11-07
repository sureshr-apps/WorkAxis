part of 'workaxis_connector.dart';

class ListMyReturnsVariablesBuilder {
  int limit;
  int offset;
  Optional<String> _status = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  ListMyReturnsVariablesBuilder status(String? t) {
    _status.value = t;
    return this;
  }

  ListMyReturnsVariablesBuilder(
    this._dataConnect, {
    required this.limit,
    required this.offset,
  });
  Deserializer<ListMyReturnsData> dataDeserializer = (dynamic json) =>
      ListMyReturnsData.fromJson(jsonDecode(json));
  Serializer<ListMyReturnsVariables> varsSerializer = (
    ListMyReturnsVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<QueryResult<ListMyReturnsData, ListMyReturnsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListMyReturnsData, ListMyReturnsVariables> ref() {
    ListMyReturnsVariables vars = ListMyReturnsVariables(
      limit: limit,
      offset: offset,
      status: _status,
    );
    return _dataConnect.query(
      "ListMyReturns",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class ListMyReturnsReturnRecords {
  final String id;
  final ListMyReturnsReturnRecordsBranch branch;
  final String employeeId;
  final String employeeName;
  final String invoiceNumber;
  final String status;
  final String returnReason;
  final String? productTitle;
  final double? quantity;
  final String? unit;
  final String? billImageUrl;
  final String? remarks;
  final String? reviewerNotes;
  final String? reviewerName;
  final Timestamp? reviewedAt;
  final Timestamp createdAt;
  ListMyReturnsReturnRecords.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      branch = ListMyReturnsReturnRecordsBranch.fromJson(json['branch']),
      employeeId = nativeFromJson<String>(json['employeeId']),
      employeeName = nativeFromJson<String>(json['employeeName']),
      invoiceNumber = nativeFromJson<String>(json['invoiceNumber']),
      status = nativeFromJson<String>(json['status']),
      returnReason = nativeFromJson<String>(json['returnReason']),
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

    final ListMyReturnsReturnRecords otherTyped =
        other as ListMyReturnsReturnRecords;
    return id == otherTyped.id &&
        branch == otherTyped.branch &&
        employeeId == otherTyped.employeeId &&
        employeeName == otherTyped.employeeName &&
        invoiceNumber == otherTyped.invoiceNumber &&
        status == otherTyped.status &&
        returnReason == otherTyped.returnReason &&
        productTitle == otherTyped.productTitle &&
        quantity == otherTyped.quantity &&
        unit == otherTyped.unit &&
        billImageUrl == otherTyped.billImageUrl &&
        remarks == otherTyped.remarks &&
        reviewerNotes == otherTyped.reviewerNotes &&
        reviewerName == otherTyped.reviewerName &&
        reviewedAt == otherTyped.reviewedAt &&
        createdAt == otherTyped.createdAt;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    branch.hashCode,
    employeeId.hashCode,
    employeeName.hashCode,
    invoiceNumber.hashCode,
    status.hashCode,
    returnReason.hashCode,
    productTitle.hashCode,
    quantity.hashCode,
    unit.hashCode,
    billImageUrl.hashCode,
    remarks.hashCode,
    reviewerNotes.hashCode,
    reviewerName.hashCode,
    reviewedAt.hashCode,
    createdAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['branch'] = branch.toJson();
    json['employeeId'] = nativeToJson<String>(employeeId);
    json['employeeName'] = nativeToJson<String>(employeeName);
    json['invoiceNumber'] = nativeToJson<String>(invoiceNumber);
    json['status'] = nativeToJson<String>(status);
    json['returnReason'] = nativeToJson<String>(returnReason);
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
    if (reviewerName != null) {
      json['reviewerName'] = nativeToJson<String?>(reviewerName);
    }
    if (reviewedAt != null) {
      json['reviewedAt'] = reviewedAt!.toJson();
    }
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  ListMyReturnsReturnRecords({
    required this.id,
    required this.branch,
    required this.employeeId,
    required this.employeeName,
    required this.invoiceNumber,
    required this.status,
    required this.returnReason,
    this.productTitle,
    this.quantity,
    this.unit,
    this.billImageUrl,
    this.remarks,
    this.reviewerNotes,
    this.reviewerName,
    this.reviewedAt,
    required this.createdAt,
  });
}

@immutable
class ListMyReturnsReturnRecordsBranch {
  final String id;
  final String name;
  ListMyReturnsReturnRecordsBranch.fromJson(dynamic json)
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

    final ListMyReturnsReturnRecordsBranch otherTyped =
        other as ListMyReturnsReturnRecordsBranch;
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

  ListMyReturnsReturnRecordsBranch({required this.id, required this.name});
}

@immutable
class ListMyReturnsTotal {
  final int count_;
  ListMyReturnsTotal.fromJson(dynamic json)
    : count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyReturnsTotal otherTyped = other as ListMyReturnsTotal;
    return count_ == otherTyped.count_;
  }

  @override
  int get hashCode => count_.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  ListMyReturnsTotal({required this.count_});
}

@immutable
class ListMyReturnsData {
  final List<ListMyReturnsReturnRecords> returnRecords;
  final List<ListMyReturnsTotal> total;
  ListMyReturnsData.fromJson(dynamic json)
    : returnRecords = (json['returnRecords'] as List<dynamic>)
          .map((e) => ListMyReturnsReturnRecords.fromJson(e))
          .toList(),
      total = (json['total'] as List<dynamic>)
          .map((e) => ListMyReturnsTotal.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyReturnsData otherTyped = other as ListMyReturnsData;
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

  ListMyReturnsData({required this.returnRecords, required this.total});
}

@immutable
class ListMyReturnsVariables {
  final int limit;
  final int offset;
  late final Optional<String> status;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  ListMyReturnsVariables.fromJson(Map<String, dynamic> json)
    : limit = nativeFromJson<int>(json['limit']),
      offset = nativeFromJson<int>(json['offset']) {
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

    final ListMyReturnsVariables otherTyped = other as ListMyReturnsVariables;
    return limit == otherTyped.limit &&
        offset == otherTyped.offset &&
        status == otherTyped.status;
  }

  @override
  int get hashCode =>
      Object.hashAll([limit.hashCode, offset.hashCode, status.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['limit'] = nativeToJson<int>(limit);
    json['offset'] = nativeToJson<int>(offset);
    if (status.state == OptionalState.set) {
      json['status'] = status.toJson();
    }
    return json;
  }

  ListMyReturnsVariables({
    required this.limit,
    required this.offset,
    required this.status,
  });
}
