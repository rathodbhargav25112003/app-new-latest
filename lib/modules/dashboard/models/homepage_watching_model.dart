import '../../../models/video_data_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'homepage_watching_model.g.dart';

@JsonSerializable(explicitToJson: true)
class HomePageWatchingModel {
  HomePageWatchingModel({
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
    this.timeDuration,
    this.examName,
    this.topicName,
    this.type,
    this.marksDeducted,
    this.marksAwarded,
    this.instruction,
    this.fromtime,
    this.isPracticeMode,
    this.negativeMarking,
    this.totime,
    this.attempt,
    this.subcategoryName,
    this.categoryName,
    this.pausedTime,
    this.videoFiles,
    this.downloadVideo,
    this.isBookmark,
    this.annotation,
    this.videoLink,
    this.examId,
    this.remainingAttempts,
    this.totalQuestions,
    this.isDeclaration,
    this.isAttempt,
    this.isSection,
    this.declarationTime,
  });

  factory HomePageWatchingModel.fromJson(Map<String, dynamic> json) =>
      _$HomePageWatchingModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  int? id;
  @JsonKey(name: '__v')
  int? iV;
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
  bool? isPublic;
  bool? isCompleted;
  bool? isfeatured;
  @JsonKey(name: 'Pdfcontents')
  String? pdfcontents;
  @JsonKey(name: 'topic_name')
  String? topicName;
  @JsonKey(name: 'subcategory_name')
  String? subcategoryName;
  @JsonKey(name: 'category_name')
  String? categoryName;
  @JsonKey(name: 'negative_marking')
  bool? negativeMarking;
  @JsonKey(name: 'marks_deducted')
  double? marksDeducted;
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
  String? totime;
  String? type;
  String? pausedTime;
  String? videoLink;
  String? examId;
  int? remainingAttempts;
  int? totalQuestions;
  bool? isDeclaration;
  bool? isAttempt;
  bool? isSection;
  String? declarationTime;
  List<Files>? videoFiles;
  List<Download>? downloadVideo;
  bool? isBookmark;
  List<AnnotationList>? annotation;

  Map<String, dynamic> toJson() => _$HomePageWatchingModelToJson(this);
}
