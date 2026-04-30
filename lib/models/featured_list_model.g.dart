// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeaturedListModel _$FeaturedListModelFromJson(Map<String, dynamic> json) =>
    FeaturedListModel(
      video: (json['video'] as List<dynamic>?)
          ?.map((e) => Videos.fromJson(e as Map<String, dynamic>))
          .toList(),
      pdf: (json['PDF'] as List<dynamic>?)
          ?.map((e) => Pdfs.fromJson(e as Map<String, dynamic>))
          .toList(),
      test: (json['test'] as List<dynamic>?)
          ?.map((e) => TestsPaper.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FeaturedListModelToJson(FeaturedListModel instance) =>
    <String, dynamic>{
      'video': instance.video?.map((e) => e.toJson()).toList(),
      'PDF': instance.pdf?.map((e) => e.toJson()).toList(),
      'test': instance.test?.map((e) => e.toJson()).toList(),
    };

Videos _$VideosFromJson(Map<String, dynamic> json) => Videos(
      is_access: json['is_access'] as bool?,
      isfeatured: json['isfeatured'] as bool?,
      id: json['_id'] as String?,
      videoUrl: json['video_url'] as String?,
      contentType: json['content_type'] as String?,
      contentUrl: json['content_url'] as String?,
      topicId: json['topic_id'] as String?,
      topicName: json['topic_name'] as String?,
      thumbImg: json['Banner_img'] as String?,
    );

Map<String, dynamic> _$VideosToJson(Videos instance) => <String, dynamic>{
      'is_access': instance.is_access,
      'isfeatured': instance.isfeatured,
      '_id': instance.id,
      'video_url': instance.videoUrl,
      'content_type': instance.contentType,
      'content_url': instance.contentUrl,
      'topic_id': instance.topicId,
      'topic_name': instance.topicName,
      'Banner_img': instance.thumbImg,
    };

Pdfs _$PdfsFromJson(Map<String, dynamic> json) => Pdfs(
      is_access: json['is_access'] as bool?,
      isfeatured: json['isfeatured'] as bool?,
      id: json['_id'] as String?,
      videoUrl: json['video_url'] as String?,
      contentType: json['content_type'] as String?,
      contentUrl: json['content_url'] as String?,
      topicId: json['topic_id'] as String?,
      topicName: json['topic_name'] as String?,
    );

Map<String, dynamic> _$PdfsToJson(Pdfs instance) => <String, dynamic>{
      'is_access': instance.is_access,
      'isfeatured': instance.isfeatured,
      '_id': instance.id,
      'video_url': instance.videoUrl,
      'content_type': instance.contentType,
      'content_url': instance.contentUrl,
      'topic_id': instance.topicId,
      'topic_name': instance.topicName,
    };

TestsPaper _$TestsPaperFromJson(Map<String, dynamic> json) => TestsPaper(
      negativeMarking: json['negative_marking'] as bool?,
      marksDeducted: (json['marks_deducted'] as num?)?.toDouble(),
      examId: json['_id'] as String?,
      id: (json['id'] as num?)?.toInt(),
      examName: json['exam_name'] as String?,
      categoryId: json['category_id'] as String?,
      timeDuration: json['time_duration'] as String?,
      marksAwarded: (json['marks_awarded'] as num?)?.toInt(),
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      isAttempt: json['isAttempt'] as bool?,
      sid: json['sid'] as String?,
      instruction: json['instruction'] as String?,
      questions: (json['questions'] as List<dynamic>?)
          ?.map((e) => FeaturedTestData.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPracticeExamAttempt: json['isPracticeExamAttempt'] as bool?,
    );

Map<String, dynamic> _$TestsPaperToJson(TestsPaper instance) =>
    <String, dynamic>{
      'negative_marking': instance.negativeMarking,
      'marks_deducted': instance.marksDeducted,
      '_id': instance.examId,
      'id': instance.id,
      'exam_name': instance.examName,
      'category_id': instance.categoryId,
      'time_duration': instance.timeDuration,
      'marks_awarded': instance.marksAwarded,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'isAttempt': instance.isAttempt,
      'sid': instance.sid,
      'instruction': instance.instruction,
      'questions': instance.questions?.map((e) => e.toJson()).toList(),
      'isPracticeExamAttempt': instance.isPracticeExamAttempt,
    };

FeaturedTestData _$FeaturedTestDataFromJson(Map<String, dynamic> json) =>
    FeaturedTestData(
      questionImg: (json['question_image'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      explanationImg: (json['explanation_image'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      sId: json['_id'] as String?,
      examId: json['exam_id'] as String?,
      questionText: json['question_text'] as String?,
      correctOption: json['correct_option'] as String?,
      explanation: json['explanation'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      id: (json['id'] as num?)?.toInt(),
      optionsData: (json['options'] as List<dynamic>?)
          ?.map((e) => Options.fromJson(e as Map<String, dynamic>))
          .toList(),
      questionNumber: (json['question_number'] as num?)?.toInt(),
      statusColor: (json['statusColor'] as num?)?.toInt(),
      txtColor: (json['txtColor'] as num?)?.toInt(),
      bookmarks: json['bookmarks'] as bool?,
    );

Map<String, dynamic> _$FeaturedTestDataToJson(FeaturedTestData instance) =>
    <String, dynamic>{
      'question_image': instance.questionImg,
      'explanation_image': instance.explanationImg,
      '_id': instance.sId,
      'exam_id': instance.examId,
      'question_text': instance.questionText,
      'correct_option': instance.correctOption,
      'explanation': instance.explanation,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'id': instance.id,
      'options': instance.optionsData?.map((e) => e.toJson()).toList(),
      'question_number': instance.questionNumber,
      'statusColor': instance.statusColor,
      'txtColor': instance.txtColor,
      'bookmarks': instance.bookmarks,
    };

Options _$OptionsFromJson(Map<String, dynamic> json) => Options(
      answerImg: json['answer_image'] as String?,
      answerTitle: json['answer_title'] as String?,
      sId: json['_id'] as String?,
      value: json['value'] as String?,
    );

Map<String, dynamic> _$OptionsToJson(Options instance) => <String, dynamic>{
      'answer_image': instance.answerImg,
      'answer_title': instance.answerTitle,
      '_id': instance.sId,
      'value': instance.value,
    };
