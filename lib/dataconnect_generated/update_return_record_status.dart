part of 'workaxis_connector.dart';

class UpdateReturnRecordStatusVariablesBuilder {
  String id;
  String status;

  final FirebaseDataConnect _dataConnect;
  UpdateReturnRecordStatusVariablesBuilder(this._dataConnect, {required  this.id,required  this.status,});
  Deserializer<UpdateReturnRecordStatusData> dataDeserializer = (dynamic json)  => UpdateReturnRecordStatusData.fromJson(jsonDecode(json));
  Serializer<UpdateReturnRecordStatusVariables> varsSerializer = (UpdateReturnRecordStatusVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateReturnRecordStatusData, UpdateReturnRecordStatusVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateReturnRecordStatusData, UpdateReturnRecordStatusVariables> ref() {
    UpdateReturnRecordStatusVariables vars= UpdateReturnRecordStatusVariables(id: id,status: status,);
    return _dataConnect.mutation("UpdateReturnRecordStatus", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateReturnRecordStatusReturnRecordUpdate {
  final String id;
  UpdateReturnRecordStatusReturnRecordUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReturnRecordStatusReturnRecordUpdate otherTyped = other as UpdateReturnRecordStatusReturnRecordUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateReturnRecordStatusReturnRecordUpdate({
    required this.id,
  });
}

@immutable
class UpdateReturnRecordStatusData {
  final UpdateReturnRecordStatusReturnRecordUpdate? returnRecord_update;
  UpdateReturnRecordStatusData.fromJson(dynamic json):
  
  returnRecord_update = json['returnRecord_update'] == null ? null : UpdateReturnRecordStatusReturnRecordUpdate.fromJson(json['returnRecord_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReturnRecordStatusData otherTyped = other as UpdateReturnRecordStatusData;
    return returnRecord_update == otherTyped.returnRecord_update;
    
  }
  @override
  int get hashCode => returnRecord_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (returnRecord_update != null) {
      json['returnRecord_update'] = returnRecord_update!.toJson();
    }
    return json;
  }

  UpdateReturnRecordStatusData({
    this.returnRecord_update,
  });
}

@immutable
class UpdateReturnRecordStatusVariables {
  final String id;
  final String status;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateReturnRecordStatusVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReturnRecordStatusVariables otherTyped = other as UpdateReturnRecordStatusVariables;
    return id == otherTyped.id && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  UpdateReturnRecordStatusVariables({
    required this.id,
    required this.status,
  });
}

