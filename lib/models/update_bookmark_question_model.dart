import 'package:json_annotation/json_annotation.dart';

part 'update_bookmark_question_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UpdateBookMarkModel {
  UpdateBookMarkModel({
    this.msg,
    this.data,
    });

  factory UpdateBookMarkModel.fromJson(Map<String, dynamic> json) => _$UpdateBookMarkModelFromJson(json);

  String? msg;
  BookMarkData? data;
  
  Map<String, dynamic> toJson() => _$UpdateBookMarkModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BookMarkData {
  BookMarkData({
    this.isCorrect,
    this.attempted,
    this.markedForReview,
    this.attemptedMarkedForReview,
    this.skipped,
    this.bookmarks,
    this.id,
    this.userExamId,
    this.questionId,
    this.selectedOption,
    this.time,
    this.created_at,
    this.updated_at,
  });

  factory BookMarkData.fromJson(Map<String, dynamic> json) => _$BookMarkDataFromJson(json);

  @JsonKey(name: 'is_correct')
  bool? isCorrect;
  bool? attempted;
  @JsonKey(name: 'marked_for_review')
  bool? markedForReview;
  @JsonKey(name: 'attempted_marked_for_review')
  bool? attemptedMarkedForReview;
  bool? skipped;
  bool? bookmarks;
  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'userExam_id')
  String? userExamId;
  @JsonKey(name: 'question_id')
  String? questionId;
  @JsonKey(name: 'selected_option')
  String? selectedOption;
  String? time;
  String? created_at;
  String? updated_at;

  Map<String, dynamic> toJson() => _$BookMarkDataToJson(this);
}