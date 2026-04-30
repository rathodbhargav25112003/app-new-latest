import 'package:json_annotation/json_annotation.dart';

part 'create_video_note_history_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateVideoNoteHistoryModel {
  CreateVideoNoteHistoryModel({
    this.id,
    this.contentId,
    this.contentType,
    this.created_at,
    this.updated_at,
    this.sId,
    this.iV,
    this.userId,
  });

  factory CreateVideoNoteHistoryModel.fromJson(Map<String, dynamic> json) => _$CreateVideoNoteHistoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  int? id;
  @JsonKey(name: '__v')
  int? iV;
  @JsonKey(name: 'content_id')
  String? contentId;
  @JsonKey(name: 'user_id')
  String? userId;
  @JsonKey(name: 'content_type')
  String? contentType;
  String? created_at;
  String? updated_at;

  Map<String, dynamic> toJson() => _$CreateVideoNoteHistoryModelToJson(this);
}