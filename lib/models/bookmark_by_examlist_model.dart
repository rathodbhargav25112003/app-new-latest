import 'package:json_annotation/json_annotation.dart';

part 'bookmark_by_examlist_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BookMarkByExamListModel {
  BookMarkByExamListModel({
    this.examId,
    this.examName,
    this.instruction,
    this.topic_id,
    this.category_id,
    this.bookmarkCount,
    this.questionCount,
  });

  factory BookMarkByExamListModel.fromJson(Map<String, dynamic> json) =>
      _$BookMarkByExamListModelFromJson(json);

  @JsonKey(name: 'exam_id')
  String? examId;
  @JsonKey(name: 'exam_name')
  String? examName;
  String? topic_id;
  String? category_id;
  String? instruction;
  int? bookmarkCount;
  int? questionCount;

  Map<String, dynamic> toJson() => _$BookMarkByExamListModelToJson(this);
}
