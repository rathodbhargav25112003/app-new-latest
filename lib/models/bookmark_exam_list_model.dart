import 'package:json_annotation/json_annotation.dart';

part 'bookmark_exam_list_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BookMarkExamListModel {
  BookMarkExamListModel({
    this.userExamId,
    this.isAttemptcount,
    this.examName,
    this.bookmarksCount,
  });

  factory BookMarkExamListModel.fromJson(Map<String, dynamic> json) => _$BookMarkExamListModelFromJson(json);

  @JsonKey(name:"userExam_id")
  String? userExamId;
  num? isAttemptcount;
  @JsonKey(name:"exam_name")
  String? examName;
  int? bookmarksCount;

  Map<String, dynamic> toJson() => _$BookMarkExamListModelToJson(this);
}
