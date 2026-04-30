import 'package:json_annotation/json_annotation.dart';

part 'featured_list_model.g.dart';

@JsonSerializable(explicitToJson: true)
class FeaturedListModel {
  FeaturedListModel({
    this.video,
    this.pdf,
    this.test
  });

  factory FeaturedListModel.fromJson(Map<String, dynamic> json) => _$FeaturedListModelFromJson(json);

  List<Videos>? video;
  @JsonKey(name:"PDF")
  List<Pdfs>? pdf;
  List<TestsPaper>? test;

  Map<String, dynamic> toJson() => _$FeaturedListModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Videos {
  Videos({
    this.is_access,
    this.isfeatured,
    this.id,
    this.videoUrl,
    this.contentType,
    this.contentUrl,
    this.topicId,
    this.topicName,
    this.thumbImg,
  });

  factory Videos.fromJson(Map<String, dynamic> json) =>
      _$VideosFromJson(json);

  bool? is_access;
  bool? isfeatured;
  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'video_url')
  String? videoUrl;
  @JsonKey(name: 'content_type')
  String? contentType;
  @JsonKey(name: 'content_url')
  String? contentUrl;
  @JsonKey(name: 'topic_id')
  String? topicId;
  @JsonKey(name: 'topic_name')
  String? topicName;
  @JsonKey(name: 'Banner_img')
  String? thumbImg;

  Map<String, dynamic> toJson() => _$VideosToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Pdfs {
  Pdfs({
    this.is_access,
    this.isfeatured,
    this.id,
    this.videoUrl,
    this.contentType,
    this.contentUrl,
    this.topicId,
    this.topicName,
  });

  factory Pdfs.fromJson(Map<String, dynamic> json) =>
      _$PdfsFromJson(json);

  bool? is_access;
  bool? isfeatured;
  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'video_url')
  String? videoUrl;
  @JsonKey(name: 'content_type')
  String? contentType;
  @JsonKey(name: 'content_url')
  String? contentUrl;
  @JsonKey(name: 'topic_id')
  String? topicId;
  @JsonKey(name: 'topic_name')
  String? topicName;

  Map<String, dynamic> toJson() => _$PdfsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TestsPaper {
  TestsPaper({
    this.negativeMarking,
    this.marksDeducted,
    this.examId,
    this.id,
    this.examName,
    this.categoryId,
    this.timeDuration,
    this.marksAwarded,
    this.created_at,
    this.updated_at,
    this.isAttempt,
    this.sid,
    this.instruction,
    this.questions,
    this.isPracticeExamAttempt
  });

  factory TestsPaper.fromJson(Map<String, dynamic> json) => _$TestsPaperFromJson(json);

  @JsonKey(name: 'negative_marking')
  bool? negativeMarking;
  @JsonKey(name: 'marks_deducted')
  double? marksDeducted;
  @JsonKey(name: '_id')
  String? examId;
  int? id;
  @JsonKey(name: 'exam_name')
  String? examName;
  @JsonKey(name: 'category_id')
  String? categoryId;
  @JsonKey(name: 'time_duration')
  String? timeDuration;
  @JsonKey(name: 'marks_awarded')
  int? marksAwarded;
  String? created_at;
  String? updated_at;
  bool? isAttempt;
  String? sid;
  String? instruction;
  List<FeaturedTestData>? questions;
  bool? isPracticeExamAttempt;

  Map<String, dynamic> toJson() => _$TestsPaperToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FeaturedTestData {
  FeaturedTestData({
    this.questionImg,
    this.explanationImg,
    this.sId,
    this.examId,
    this.questionText,
    this.correctOption,
    this.explanation,
    this.created_at,
    this.updated_at,
    this.id,
    this.optionsData,
    this.questionNumber,
    this.statusColor,
    this.txtColor,
    this.bookmarks,
  });

  factory FeaturedTestData.fromJson(Map<String, dynamic> json) => _$FeaturedTestDataFromJson(json);

  @JsonKey(name: 'question_image')
  List<String>? questionImg;
  @JsonKey(name: 'explanation_image')
  List<String>? explanationImg;
  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'exam_id')
  String? examId;
  @JsonKey(name: 'question_text')
  String? questionText;
  @JsonKey(name: 'correct_option')
  String? correctOption;
  String? explanation;
  String? created_at;
  String? updated_at;
  int? id;
  @JsonKey(name: 'options')
  List<Options>? optionsData;
  @JsonKey(name: 'question_number')
  int? questionNumber;
  int? statusColor;
  int? txtColor;
  bool? bookmarks;

  Map<String, dynamic> toJson() => _$FeaturedTestDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Options {
  Options({
    this.answerImg,
    this.answerTitle,
    this.sId,
    this.value});

  factory Options.fromJson(Map<String, dynamic> json) => _$OptionsFromJson(json);

  @JsonKey(name: 'answer_image')
  String? answerImg;
  @JsonKey(name: 'answer_title')
  String? answerTitle;
  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'value')
  String? value;

  Map<String, dynamic> toJson() => _$OptionsToJson(this);
}

