import 'package:json_annotation/json_annotation.dart';

part 'video_chapterization_list_model.g.dart';

@JsonSerializable(explicitToJson: true)
class VideoChapterizationListModel {
  VideoChapterizationListModel({
    this.uri,
    this.title,
    this.timeCode
  });

  factory VideoChapterizationListModel.fromJson(Map<String, dynamic> json) => _$VideoChapterizationListModelFromJson(json);

  String? uri;
  String? title;
  @JsonKey(name: 'timecode')
  int? timeCode;

  Map<String, dynamic> toJson() => _$VideoChapterizationListModelToJson(this);
}
