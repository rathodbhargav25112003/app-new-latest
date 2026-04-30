import 'package:json_annotation/json_annotation.dart';

part 'report_list_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ReportListModel {
  ReportListModel({
    this.id,
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
  });

  factory ReportListModel.fromJson(Map<String, dynamic> json) => _$ReportListModelFromJson(json);

  @JsonKey(name:"_id")
  String? id;
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

  Map<String, dynamic> toJson() => _$ReportListModelToJson(this);
}
