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

  final FirebaseDataConnect _dataConnect;
  CreateReturnRecordVariablesBuilder(this._dataConnect, {required  this.id,required  this.orgId,required  this.branchId,required  this.employeeId,required  this.employeeName,required  this.customerName,required  this.invoiceNumber,required  this.returnReason,required  this.amount,});
  Deserializer<CreateReturnRecordData> dataDeserializer = (dynamic json)  => CreateReturnRecordData.fromJson(jsonDecode(json));
  Serializer<CreateReturnRecordVariables> varsSerializer = (CreateReturnRecordVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateReturnRecordData, CreateReturnRecordVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateReturnRecordData, CreateReturnRecordVariables> ref() {
    CreateReturnRecordVariables vars= CreateReturnRecordVariables(id: id,orgId: orgId,branchId: branchId,employeeId: employeeId,employeeName: employeeName,customerName: customerName,invoiceNumber: invoiceNumber,returnReason: returnReason,amount: amount,);
    return _dataConnect.mutation("CreateReturnRecord", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateReturnRecordReturnRecordInsert {
  final String id;
  CreateReturnRecordReturnRecordInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateReturnRecordReturnRecordInsert otherTyped = other as CreateReturnRecordReturnRecordInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateReturnRecordReturnRecordInsert({
    required this.id,
  });
}

@immutable
class CreateReturnRecordData {
  final CreateReturnRecordReturnRecordInsert returnRecord_insert;
  CreateReturnRecordData.fromJson(dynamic json):
  
  returnRecord_insert = CreateReturnRecordReturnRecordInsert.fromJson(json['returnRecord_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
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

  CreateReturnRecordData({
    required this.returnRecord_insert,
  });
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
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateReturnRecordVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  orgId = nativeFromJson<String>(json['orgId']),
  branchId = nativeFromJson<String>(json['branchId']),
  employeeId = nativeFromJson<String>(json['employeeId']),
  employeeName = nativeFromJson<String>(json['employeeName']),
  customerName = nativeFromJson<String>(json['customerName']),
  invoiceNumber = nativeFromJson<String>(json['invoiceNumber']),
  returnReason = nativeFromJson<String>(json['returnReason']),
  amount = nativeFromJson<double>(json['amount']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateReturnRecordVariables otherTyped = other as CreateReturnRecordVariables;
    return id == otherTyped.id && 
    orgId == otherTyped.orgId && 
    branchId == otherTyped.branchId && 
    employeeId == otherTyped.employeeId && 
    employeeName == otherTyped.employeeName && 
    customerName == otherTyped.customerName && 
    invoiceNumber == otherTyped.invoiceNumber && 
    returnReason == otherTyped.returnReason && 
    amount == otherTyped.amount;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, orgId.hashCode, branchId.hashCode, employeeId.hashCode, employeeName.hashCode, customerName.hashCode, invoiceNumber.hashCode, returnReason.hashCode, amount.hashCode]);
  

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
  });
}

