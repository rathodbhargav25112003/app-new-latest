import 'package:json_annotation/json_annotation.dart';

part 'bookmark_mainlist_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BookMarkMainListModel {
  BookMarkMainListModel({
    this.examId,
    this.negativeMarking,
    this.examName,
    this.subcategoryId,
    this.subcategoryName,
    this.categoryId,
    this.categoryName,
    this.topicId,
    this.topicName,
    this.timeDuration,
    this.marksDeducted,
    this.marksAwarded,
    this.createdAt,
    this.attemptCount,
  });

  factory BookMarkMainListModel.fromJson(Map<String, dynamic> json) => _$BookMarkMainListModelFromJson(json);

  @JsonKey(name:"exam_id")
  String? examId;
  @JsonKey(name: "negative_marking")
  bool? negativeMarking;
  @JsonKey(name: 'exam_name')
  String? examName;
  @JsonKey(name: 'subcategory_id')
  String? subcategoryId;
  @JsonKey(name: 'subcategory_name')
  String? subcategoryName;
  @JsonKey(name: 'category_id')
  String? categoryId;
  @JsonKey(name: 'category_name')
  String? categoryName;
  @JsonKey(name: 'topic_id')
  String? topicId;
  @JsonKey(name: 'topic_name')
  String? topicName;
  @JsonKey(name: 'time_duration')
  String? timeDuration;
  @JsonKey(name: 'marks_deducted')
  num? marksDeducted;
  @JsonKey(name: 'marks_awarded')
  num? marksAwarded;
  @JsonKey(name: 'created_at')
  String? createdAt;
  @JsonKey(name: 'Attemptcount')
  int? attemptCount;

  Map<String, dynamic> toJson() => _$BookMarkMainListModelToJson(this);
}
