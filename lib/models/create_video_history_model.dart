import 'package:json_annotation/json_annotation.dart';

part 'create_video_history_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateVideoHistoryModel {
  CreateVideoHistoryModel({
    this.sId,
    this.content_id,
    this.user_id,
    this.createdAt,
    this.updatedAt,
    this.id,
    this.iV
  });

  factory CreateVideoHistoryModel.fromJson(Map<String, dynamic> json) => _$CreateVideoHistoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  String? content_id;
  String? user_id;
  String? createdAt;
  String? updatedAt;
  int? id;
  @JsonKey(name: '__v')
  int? iV;

  Map<String, dynamic> toJson() => _$CreateVideoHistoryModelToJson(this);
}