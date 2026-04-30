import 'package:json_annotation/json_annotation.dart';

import '../../../models/video_data_model.dart';

part 'global_search_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GlobalSearchDataModel{
  GlobalSearchDataModel({
    this.id,
    this.categoryName,
    this.subcategoryName,
    this.subName,
    this.topicName,
    this.description,
    this.title,
    this.contentUrl,
    this.topicId,
    this.subcategoryId,
    this.categoryId,
    this.examName,
    this.attempt,
    this.totime,
    this.negativeMarking,
    this.isPracticeMode,
    this.fromtime,
    this.instruction,
    this.timeDuration,
    this.marksAwarded,
    this.marksDeducted,
    this.pdfId,
    this.isPublic,
    this.videoUrl,
    this.questionId,
    this.isAccess,
    this.numberOfQuestions,
    this.type,
    this.user_id,
    this.exam,
    this.testName,
    this.category,
    this.subcategory,
    this.topic,
    this.bannerImg,
    this.contentType,
    this.Description,
    this.isfeatured,
    this.isBookmark,
    this.videoLink,
  });

  factory GlobalSearchDataModel.fromJson(Map<String, dynamic> json) => _$GlobalSearchDataModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'category_name')
  String? categoryName;
  @JsonKey(name: 'subcategory_name')
  String? subcategoryName;
  @JsonKey(name: 'subscription_id')
  List<String>? subscriptionId;
  @JsonKey(name: 'sub_name')
  String? subName;
  @JsonKey(name: 'content_url')
  String? contentUrl;
  @JsonKey(name: 'video_url')
  String? videoUrl;
  @JsonKey(name: 'topic_name')
  String? topicName;
  @JsonKey(name: 'subcategory_id')
  String? subcategoryId;
  @JsonKey(name: 'topic_id')
  String? topicId;
  @JsonKey(name: 'category_id')
  String? categoryId;
  String? title;
  String? description;
  @JsonKey(name: 'Banner_img')
  String? bannerImg;
  @JsonKey(name: 'content_type')
  String? contentType;
  @JsonKey(name: 'pdf_id')
  String? pdfId;
  String? type;
  @JsonKey(name: 'isAccess')
  bool? isAccess;
  bool? isfeatured;
  bool? isBookmark;
  bool? isPublic;
  @JsonKey(name: 'negative_marking')
  bool? negativeMarking;
  @JsonKey(name: 'marks_deducted')
  double? marksDeducted;
  @JsonKey(name: 'is_practice_mode')
  bool? isPracticeMode;
  String? fromtime;
  String? totime;
  @JsonKey(name: 'exam_name')
  String? examName;
  @JsonKey(name: 'time_duration')
  String? timeDuration;
  @JsonKey(name: 'marks_awarded')
  int? marksAwarded;
  int? attempt;
  String? instruction;
  @JsonKey(name: 'user_id')
  String? user_id;
  String? testName;
  String? videoLink;
  String? Description;
  @JsonKey(name: 'NumberOfQuestions')
  int? numberOfQuestions;
  @JsonKey(name: 'question_id')
  List<String>? questionId;
  List<GlobalCustomCategoryModel>? category;
  List<GlobalCustomCategoryModel>? subcategory;
  List<GlobalCustomCategoryModel>? topic;
  List<GlobalCustomCategoryModel>? exam;
  List<AnnotationList>? annotation;
  List<Files>? videoFiles;
  List<Download>? downloadVideo;

  Map<String, dynamic> toJson() => _$GlobalSearchDataModelToJson(this);
}


@JsonSerializable(explicitToJson: true)
class GlobalCustomCategoryModel{
  GlobalCustomCategoryModel({
    this.id,
    this.categoryName,
    this.subcategoryName,
    this.topicName,
    this.topicId,
    this.subcategoryId,
    this.categoryId,
    this.examName,
    this.examId
  });

  factory GlobalCustomCategoryModel.fromJson(Map<String, dynamic> json) => _$GlobalCustomCategoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'category_name')
  String? categoryName;
  @JsonKey(name: 'subcategory_name')
  String? subcategoryName;
  @JsonKey(name: 'topic_name')
  String? topicName;
  @JsonKey(name: 'exam_name')
  String? examName;
  @JsonKey(name: 'exam_id')
  String? examId;
  @JsonKey(name: 'subcategory_id')
  String? subcategoryId;
  @JsonKey(name: 'topic_id')
  String? topicId;
  @JsonKey(name: 'category_id')
  String? categoryId;

  Map<String, dynamic> toJson() => _$GlobalCustomCategoryModelToJson(this);
}