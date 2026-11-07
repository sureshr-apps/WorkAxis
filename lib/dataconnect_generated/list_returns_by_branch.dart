part of 'workaxis_connector.dart';

class ListReturnsByBranchVariablesBuilder {
  String branchId;

  final FirebaseDataConnect _dataConnect;
  ListReturnsByBranchVariablesBuilder(this._dataConnect, {required  this.branchId,});
  Deserializer<ListReturnsByBranchData> dataDeserializer = (dynamic json)  => ListReturnsByBranchData.fromJson(jsonDecode(json));
  Serializer<ListReturnsByBranchVariables> varsSerializer = (ListReturnsByBranchVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListReturnsByBranchData, ListReturnsByBranchVariables>> execute() {
    return ref().execute();
  }

  QueryRef<ListReturnsByBranchData, ListReturnsByBranchVariables> ref() {
    ListReturnsByBranchVariables vars= ListReturnsByBranchVariables(branchId: branchId,);
    return _dataConnect.query("ListReturnsByBranch", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListReturnsByBranchReturnRecords {
  final String id;
  final String employeeId;
  final String employeeName;
  final String customerName;
  final String invoiceNumber;
  final String status;
  final String returnReason;
  final double amount;
  final Timestamp createdAt;
  ListReturnsByBranchReturnRecords.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  employeeId = nativeFromJson<String>(json['employeeId']),
  employeeName = nativeFromJson<String>(json['employeeName']),
  customerName = nativeFromJson<String>(json['customerName']),
  invoiceNumber = nativeFromJson<String>(json['invoiceNumber']),
  status = nativeFromJson<String>(json['status']),
  returnReason = nativeFromJson<String>(json['returnReason']),
  amount = nativeFromJson<double>(json['amount']),
  createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListReturnsByBranchReturnRecords otherTyped = other as ListReturnsByBranchReturnRecords;
    return id == otherTyped.id && 
    employeeId == otherTyped.employeeId && 
    employeeName == otherTyped.employeeName && 
    customerName == otherTyped.customerName && 
    invoiceNumber == otherTyped.invoiceNumber && 
    status == otherTyped.status && 
    returnReason == otherTyped.returnReason && 
    amount == otherTyped.amount && 
    createdAt == otherTyped.createdAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, employeeId.hashCode, employeeName.hashCode, customerName.hashCode, invoiceNumber.hashCode, status.hashCode, returnReason.hashCode, amount.hashCode, createdAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['employeeId'] = nativeToJson<String>(employeeId);
    json['employeeName'] = nativeToJson<String>(employeeName);
    json['customerName'] = nativeToJson<String>(customerName);
    json['invoiceNumber'] = nativeToJson<String>(invoiceNumber);
    json['status'] = nativeToJson<String>(status);
    json['returnReason'] = nativeToJson<String>(returnReason);
    json['amount'] = nativeToJson<double>(amount);
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  ListReturnsByBranchReturnRecords({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.customerName,
    required this.invoiceNumber,
    required this.status,
    required this.returnReason,
    required this.amount,
    required this.createdAt,
  });
}

@immutable
class ListReturnsByBranchData {
  final List<ListReturnsByBranchReturnRecords> returnRecords;
  ListReturnsByBranchData.fromJson(dynamic json):
  
  returnRecords = (json['returnRecords'] as List<dynamic>)
        .map((e) => ListReturnsByBranchReturnRecords.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
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

  ListReturnsByBranchData({
    required this.returnRecords,
  });
}

@immutable
class ListReturnsByBranchVariables {
  final String branchId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListReturnsByBranchVariables.fromJson(Map<String, dynamic> json):
  
  branchId = nativeFromJson<String>(json['branchId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListReturnsByBranchVariables otherTyped = other as ListReturnsByBranchVariables;
    return branchId == otherTyped.branchId;
    
  }
  @override
  int get hashCode => branchId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['branchId'] = nativeToJson<String>(branchId);
    return json;
  }

  ListReturnsByBranchVariables({
    required this.branchId,
  });
}

