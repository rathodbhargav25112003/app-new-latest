import '../../../models/video_data_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'continue_watching_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ContinueWatchingModel {
  ContinueWatchingModel({
    this.title,
    this.videoResults,
    this.pdfResults,
    this.examResults,
    this.mockExamResults,
  });

  factory ContinueWatchingModel.fromJson(Map<String, dynamic> json) =>
      _$ContinueWatchingModelFromJson(json);

  String? title;
  List<VideoResultsDetailModel>? videoResults;
  List<PdfTopicDetailModel>? pdfResults;
  List<ExamTopicDetailModel>? examResults;
  List<MockExamTopicDetailModel>? mockExamResults;

  Map<String, dynamic> toJson() => _$ContinueWatchingModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class VideoResultsDetailModel {
  VideoResultsDetailModel({
    this.id,
    this.contentId,
    this.contentType,
    this.videoUrl,
    this.topicId,
    this.created_at,
    this.updated_at,
    this.sid,
    this.contentUrl,
    this.isAccess,
    this.isCompleted,
    this.pdfcontents,
    this.sId,
    this.title,
    this.subscriptionId,
    this.isfeatured,
    this.iV,
    this.subcategoryId,
    this.categoryId,
    this.isPublic,
    this.pdfId,
    this.pausedTime,
    this.thumbnail,
    this.videoFiles,
    this.downloadVideo,
    this.isBookmark,
    this.annotation,
    this.videoLink,
    this.historyId,
    this.hlsLink,
  });

  factory VideoResultsDetailModel.fromJson(Map<String, dynamic> json) =>
      _$VideoResultsDetailModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  int? id;
  @JsonKey(name: '__v')
  int? iV;
  String? historyId;
  @JsonKey(name: 'subscription_id')
  List<String>? subscriptionId;
  @JsonKey(name: 'category_id')
  String? categoryId;
  @JsonKey(name: 'subcategory_id')
  String? subcategoryId;
  String? title;
  @JsonKey(name: 'topic_id')
  String? topicId;
  String? created_at;
  String? updated_at;
  String? sid;
  @JsonKey(name: 'content_id')
  String? contentId;
  @JsonKey(name: 'pdf_id')
  String? pdfId;
  @JsonKey(name: 'content_type')
  String? contentType;
  @JsonKey(name: 'video_url')
  String? videoUrl;
  @JsonKey(name: 'content_url')
  String? contentUrl;
  @JsonKey(name: 'is_access')
  bool? isAccess;
  @JsonKey(name: 'thumbnail')
  String? thumbnail;
  bool? isPublic;
  bool? isCompleted;
  bool? isfeatured;
  @JsonKey(name: 'Pdfcontents')
  String? pdfcontents;
  String? pausedTime;
  String? videoLink;
  List<Files>? videoFiles;
  List<Download>? downloadVideo;
  bool? isBookmark;
  List<AnnotationList>? annotation;
  String? hlsLink;

  Map<String, dynamic> toJson() => _$VideoResultsDetailModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PdfTopicDetailModel {
  PdfTopicDetailModel(
      {this.id,
      this.contentId,
      this.contentType,
      this.videoUrl,
      this.topicId,
      this.created_at,
      this.updated_at,
      this.sid,
      this.contentUrl,
      this.isAccess,
      this.sId,
      this.title,
      this.subscriptionId,
      this.isfeatured,
      this.iV,
      this.subcategoryId,
      this.categoryId,
      this.isPublic,
      this.isCompleted,
      this.pdfId,
      this.isBookmark,
      this.historyId});

  factory PdfTopicDetailModel.fromJson(Map<String, dynamic> json) =>
      _$PdfTopicDetailModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  int? id;
  @JsonKey(name: '__v')
  int? iV;
  String? historyId;
  @JsonKey(name: 'subscription_id')
  List<String>? subscriptionId;
  @JsonKey(name: 'category_id')
  String? categoryId;
  @JsonKey(name: 'subcategory_id')
  String? subcategoryId;
  String? title;
  @JsonKey(name: 'topic_id')
  String? topicId;
  @JsonKey(name: 'topic_name')
  String? topicName;
  @JsonKey(name: 'subcategory_name')
  String? subcategoryName;
  @JsonKey(name: 'category_name')
  String? categoryName;
  String? created_at;
  String? updated_at;
  String? sid;
  @JsonKey(name: 'content_id')
  String? contentId;
  @JsonKey(name: 'pdf_id')
  String? pdfId;
  @JsonKey(name: 'content_type')
  String? contentType;
  @JsonKey(name: 'video_url')
  String? videoUrl;
  @JsonKey(name: 'content_url')
  String? contentUrl;
  @JsonKey(name: 'is_access')
  bool? isAccess;
  bool? isCompleted;
  bool? isPublic;
  bool? isfeatured;
  bool? isBookmark;
  @JsonKey(name: 'notesAnnotation')
  Map<String, dynamic>? annotationData;
  List<AnnotationList>? annotation;
  Map<String, dynamic> toJson() => _$PdfTopicDetailModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ExamTopicDetailModel {
  ExamTopicDetailModel(
      {this.id,
      this.topicId,
      this.created_at,
      this.updated_at,
      this.sId,
      this.subscriptionId,
      this.isfeatured,
      this.iV,
      this.subcategoryId,
      this.categoryId,
      this.isPublic,
      this.marksDeducted,
      this.marksAwarded,
      this.timeDuration,
      this.examName,
      this.instruction,
      this.fromtime,
      this.totalQuestions,
      this.declarationTime,
      this.examId,
      this.isDeclaration,
      this.isAttempt,
      this.isSection,
      this.isAccess,
      this.remainingAttempts,
      this.isPracticeMode,
      this.negativeMarking,
      this.totime,
      this.historyId,
      this.attempt});

  factory ExamTopicDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ExamTopicDetailModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  int? id;
  @JsonKey(name: '__v')
  int? iV;
  String? historyId;
  int? totalQuestions;
  @JsonKey(name: 'subscription_id')
  List<String>? subscriptionId;
  @JsonKey(name: 'category_id')
  String? categoryId;
  @JsonKey(name: 'subcategory_id')
  String? subcategoryId;
  @JsonKey(name: 'topic_id')
  String? topicId;
  String? declarationTime;
  String? examId;
  String? created_at;
  String? updated_at;
  @JsonKey(name: 'negative_marking')
  bool? negativeMarking;
  @JsonKey(name: 'marks_deducted')
  double? marksDeducted;
  bool? isPublic;
  bool? isDeclaration;
  bool? isAttempt;
  bool? isSection;
  bool? isAccess;
  bool? isfeatured;
  @JsonKey(name: 'exam_name')
  String? examName;
  @JsonKey(name: 'time_duration')
  String? timeDuration;
  @JsonKey(name: 'marks_awarded')
  int? marksAwarded;
  int? remainingAttempts;
  int? attempt;
  String? instruction;
  @JsonKey(name: 'is_practice_mode')
  bool? isPracticeMode;
  String? fromtime;
  String? totime;

  Map<String, dynamic> toJson() => _$ExamTopicDetailModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MockExamTopicDetailModel {
  MockExamTopicDetailModel({
    this.id,
    this.created_at,
    this.updated_at,
    this.sId,
    this.isfeatured,
    this.iV,
    this.categoryId,
    this.marksDeducted,
    this.marksAwarded,
    this.timeDuration,
    this.examName,
    this.remainingAttempts,
    this.instruction,
    this.fromtime,
    this.isPracticeMode,
    this.negativeMarking,
    this.totime,
    this.attempt,
  });

  factory MockExamTopicDetailModel.fromJson(Map<String, dynamic> json) =>
      _$MockExamTopicDetailModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  String? examId;
  int? id;
  @JsonKey(name: '__v')
  int? iV;
  int? remainingAttempts;
  int? totalQuestions;
  bool? isDeclaration;
  bool? isAttempt;
  bool? isAccess;
  bool? isSection;
  @JsonKey(name: 'category_id')
  String? categoryId;
  String? created_at;
  String? updated_at;
  @JsonKey(name: 'negative_marking')
  bool? negativeMarking;
  @JsonKey(name: 'marks_deducted')
  double? marksDeducted;
  bool? isfeatured;
  @JsonKey(name: 'exam_name')
  String? examName;
  @JsonKey(name: 'time_duration')
  String? timeDuration;
  @JsonKey(name: 'marks_awarded')
  int? marksAwarded;
  int? attempt;
  String? instruction;
  @JsonKey(name: 'is_practice_mode')
  bool? isPracticeMode;
  String? fromtime;
  String? declarationTime;
  String? totime;

  Map<String, dynamic> toJson() => _$MockExamTopicDetailModelToJson(this);
}
