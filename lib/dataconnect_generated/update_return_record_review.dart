part of 'workaxis_connector.dart';

class UpdateReturnRecordReviewVariablesBuilder {
  String id;
  String status;
  Optional<String> _reviewerNotes = Optional.optional(
    nativeFromJson,
    nativeToJson,
  );

  final FirebaseDataConnect _dataConnect;
  UpdateReturnRecordReviewVariablesBuilder reviewerNotes(String? t) {
    _reviewerNotes.value = t;
    return this;
  }

  UpdateReturnRecordReviewVariablesBuilder(
    this._dataConnect, {
    required this.id,
    required this.status,
  });
  Deserializer<UpdateReturnRecordReviewData> dataDeserializer = (
    dynamic json,
  ) => UpdateReturnRecordReviewData.fromJson(jsonDecode(json));
  Serializer<UpdateReturnRecordReviewVariables> varsSerializer = (
    UpdateReturnRecordReviewVariables vars,
  ) => jsonEncode(vars.toJson());
  Future<
    OperationResult<
      UpdateReturnRecordReviewData,
      UpdateReturnRecordReviewVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<UpdateReturnRecordReviewData, UpdateReturnRecordReviewVariables>
  ref() {
    UpdateReturnRecordReviewVariables vars = UpdateReturnRecordReviewVariables(
      id: id,
      status: status,
      reviewerNotes: _reviewerNotes,
    );
    return _dataConnect.mutation(
      "UpdateReturnRecordReview",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class UpdateReturnRecordReviewReturnRecordUpdate {
  final String id;
  UpdateReturnRecordReviewReturnRecordUpdate.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReturnRecordReviewReturnRecordUpdate otherTyped =
        other as UpdateReturnRecordReviewReturnRecordUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateReturnRecordReviewReturnRecordUpdate({required this.id});
}

@immutable
class UpdateReturnRecordReviewData {
  final UpdateReturnRecordReviewReturnRecordUpdate? returnRecord_update;
  UpdateReturnRecordReviewData.fromJson(dynamic json)
    : returnRecord_update = json['returnRecord_update'] == null
          ? null
          : UpdateReturnRecordReviewReturnRecordUpdate.fromJson(
              json['returnRecord_update'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReturnRecordReviewData otherTyped =
        other as UpdateReturnRecordReviewData;
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

  UpdateReturnRecordReviewData({this.returnRecord_update});
}

@immutable
class UpdateReturnRecordReviewVariables {
  final String id;
  final String status;
  late final Optional<String> reviewerNotes;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  UpdateReturnRecordReviewVariables.fromJson(Map<String, dynamic> json)
    : id = nativeFromJson<String>(json['id']),
      status = nativeFromJson<String>(json['status']) {
    reviewerNotes = Optional.optional(nativeFromJson, nativeToJson);
    reviewerNotes.value = json['reviewerNotes'] == null
        ? null
        : nativeFromJson<String>(json['reviewerNotes']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReturnRecordReviewVariables otherTyped =
        other as UpdateReturnRecordReviewVariables;
    return id == otherTyped.id &&
        status == otherTyped.status &&
        reviewerNotes == otherTyped.reviewerNotes;
  }

  @override
  int get hashCode =>
      Object.hashAll([id.hashCode, status.hashCode, reviewerNotes.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = nativeToJson<String>(status);
    if (reviewerNotes.state == OptionalState.set) {
      json['reviewerNotes'] = reviewerNotes.toJson();
    }
    return json;
  }

  UpdateReturnRecordReviewVariables({
    required this.id,
    required this.status,
    required this.reviewerNotes,
  });
}
