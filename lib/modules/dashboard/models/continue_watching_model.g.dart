// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'continue_watching_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContinueWatchingModel _$ContinueWatchingModelFromJson(
        Map<String, dynamic> json) =>
    ContinueWatchingModel(
      title: json['title'] as String?,
      videoResults: (json['videoResults'] as List<dynamic>?)
          ?.map((e) =>
              VideoResultsDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pdfResults: (json['pdfResults'] as List<dynamic>?)
          ?.map((e) => PdfTopicDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      examResults: (json['examResults'] as List<dynamic>?)
          ?.map((e) => ExamTopicDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      mockExamResults: (json['mockExamResults'] as List<dynamic>?)
          ?.map((e) =>
              MockExamTopicDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ContinueWatchingModelToJson(
        ContinueWatchingModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'videoResults': instance.videoResults?.map((e) => e.toJson()).toList(),
      'pdfResults': instance.pdfResults?.map((e) => e.toJson()).toList(),
      'examResults': instance.examResults?.map((e) => e.toJson()).toList(),
      'mockExamResults':
          instance.mockExamResults?.map((e) => e.toJson()).toList(),
    };

VideoResultsDetailModel _$VideoResultsDetailModelFromJson(
        Map<String, dynamic> json) =>
    VideoResultsDetailModel(
      id: (json['id'] as num?)?.toInt(),
      contentId: json['content_id'] as String?,
      contentType: json['content_type'] as String?,
      videoUrl: json['video_url'] as String?,
      topicId: json['topic_id'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      sid: json['sid'] as String?,
      contentUrl: json['content_url'] as String?,
      isAccess: json['is_access'] as bool?,
      isCompleted: json['isCompleted'] as bool?,
      pdfcontents: json['Pdfcontents'] as String?,
      sId: json['_id'] as String?,
      title: json['title'] as String?,
      subscriptionId: (json['subscription_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isfeatured: json['isfeatured'] as bool?,
      iV: (json['__v'] as num?)?.toInt(),
      subcategoryId: json['subcategory_id'] as String?,
      categoryId: json['category_id'] as String?,
      isPublic: json['isPublic'] as bool?,
      pdfId: json['pdf_id'] as String?,
      pausedTime: json['pausedTime'] as String?,
      thumbnail: json['thumbnail'] as String?,
      videoFiles: (json['videoFiles'] as List<dynamic>?)
          ?.map((e) => Files.fromJson(e as Map<String, dynamic>))
          .toList(),
      downloadVideo: (json['downloadVideo'] as List<dynamic>?)
          ?.map((e) => Download.fromJson(e as Map<String, dynamic>))
          .toList(),
      isBookmark: json['isBookmark'] as bool?,
      annotation: (json['annotation'] as List<dynamic>?)
          ?.map((e) => AnnotationList.fromJson(e as Map<String, dynamic>))
          .toList(),
      videoLink: json['videoLink'] as String?,
      historyId: json['historyId'] as String?,
      hlsLink: json['hlsLink'] as String?,
    );

Map<String, dynamic> _$VideoResultsDetailModelToJson(
        VideoResultsDetailModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'id': instance.id,
      '__v': instance.iV,
      'historyId': instance.historyId,
      'subscription_id': instance.subscriptionId,
      'category_id': instance.categoryId,
      'subcategory_id': instance.subcategoryId,
      'title': instance.title,
      'topic_id': instance.topicId,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'sid': instance.sid,
      'content_id': instance.contentId,
      'pdf_id': instance.pdfId,
      'content_type': instance.contentType,
      'video_url': instance.videoUrl,
      'content_url': instance.contentUrl,
      'is_access': instance.isAccess,
      'thumbnail': instance.thumbnail,
      'isPublic': instance.isPublic,
      'isCompleted': instance.isCompleted,
      'isfeatured': instance.isfeatured,
      'Pdfcontents': instance.pdfcontents,
      'pausedTime': instance.pausedTime,
      'videoLink': instance.videoLink,
      'videoFiles': instance.videoFiles?.map((e) => e.toJson()).toList(),
      'downloadVideo': instance.downloadVideo?.map((e) => e.toJson()).toList(),
      'isBookmark': instance.isBookmark,
      'annotation': instance.annotation?.map((e) => e.toJson()).toList(),
      'hlsLink': instance.hlsLink,
    };

PdfTopicDetailModel _$PdfTopicDetailModelFromJson(Map<String, dynamic> json) =>
    PdfTopicDetailModel(
      id: (json['id'] as num?)?.toInt(),
      contentId: json['content_id'] as String?,
      contentType: json['content_type'] as String?,
      videoUrl: json['video_url'] as String?,
      topicId: json['topic_id'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      sid: json['sid'] as String?,
      contentUrl: json['content_url'] as String?,
      isAccess: json['is_access'] as bool?,
      sId: json['_id'] as String?,
      title: json['title'] as String?,
      subscriptionId: (json['subscription_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isfeatured: json['isfeatured'] as bool?,
      iV: (json['__v'] as num?)?.toInt(),
      subcategoryId: json['subcategory_id'] as String?,
      categoryId: json['category_id'] as String?,
      isPublic: json['isPublic'] as bool?,
      isCompleted: json['isCompleted'] as bool?,
      pdfId: json['pdf_id'] as String?,
      isBookmark: json['isBookmark'] as bool?,
      historyId: json['historyId'] as String?,
    )
      ..topicName = json['topic_name'] as String?
      ..subcategoryName = json['subcategory_name'] as String?
      ..categoryName = json['category_name'] as String?
      ..annotationData = json['notesAnnotation'] as Map<String, dynamic>?
      ..annotation = (json['annotation'] as List<dynamic>?)
          ?.map((e) => AnnotationList.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$PdfTopicDetailModelToJson(
        PdfTopicDetailModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'id': instance.id,
      '__v': instance.iV,
      'historyId': instance.historyId,
      'subscription_id': instance.subscriptionId,
      'category_id': instance.categoryId,
      'subcategory_id': instance.subcategoryId,
      'title': instance.title,
      'topic_id': instance.topicId,
      'topic_name': instance.topicName,
      'subcategory_name': instance.subcategoryName,
      'category_name': instance.categoryName,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'sid': instance.sid,
      'content_id': instance.contentId,
      'pdf_id': instance.pdfId,
      'content_type': instance.contentType,
      'video_url': instance.videoUrl,
      'content_url': instance.contentUrl,
      'is_access': instance.isAccess,
      'isCompleted': instance.isCompleted,
      'isPublic': instance.isPublic,
      'isfeatured': instance.isfeatured,
      'isBookmark': instance.isBookmark,
      'notesAnnotation': instance.annotationData,
      'annotation': instance.annotation?.map((e) => e.toJson()).toList(),
    };

ExamTopicDetailModel _$ExamTopicDetailModelFromJson(
        Map<String, dynamic> json) =>
    ExamTopicDetailModel(
      id: (json['id'] as num?)?.toInt(),
      topicId: json['topic_id'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      sId: json['_id'] as String?,
      subscriptionId: (json['subscription_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isfeatured: json['isfeatured'] as bool?,
      iV: (json['__v'] as num?)?.toInt(),
      subcategoryId: json['subcategory_id'] as String?,
      categoryId: json['category_id'] as String?,
      isPublic: json['isPublic'] as bool?,
      marksDeducted: (json['marks_deducted'] as num?)?.toDouble(),
      marksAwarded: (json['marks_awarded'] as num?)?.toInt(),
      timeDuration: json['time_duration'] as String?,
      examName: json['exam_name'] as String?,
      instruction: json['instruction'] as String?,
      fromtime: json['fromtime'] as String?,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt(),
      declarationTime: json['declarationTime'] as String?,
      examId: json['examId'] as String?,
      isDeclaration: json['isDeclaration'] as bool?,
      isAttempt: json['isAttempt'] as bool?,
      isSection: json['isSection'] as bool?,
      isAccess: json['isAccess'] as bool?,
      remainingAttempts: (json['remainingAttempts'] as num?)?.toInt(),
      isPracticeMode: json['is_practice_mode'] as bool?,
      negativeMarking: json['negative_marking'] as bool?,
      totime: json['totime'] as String?,
      historyId: json['historyId'] as String?,
      attempt: (json['attempt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ExamTopicDetailModelToJson(
        ExamTopicDetailModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'id': instance.id,
      '__v': instance.iV,
      'historyId': instance.historyId,
      'totalQuestions': instance.totalQuestions,
      'subscription_id': instance.subscriptionId,
      'category_id': instance.categoryId,
      'subcategory_id': instance.subcategoryId,
      'topic_id': instance.topicId,
      'declarationTime': instance.declarationTime,
      'examId': instance.examId,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'negative_marking': instance.negativeMarking,
      'marks_deducted': instance.marksDeducted,
      'isPublic': instance.isPublic,
      'isDeclaration': instance.isDeclaration,
      'isAttempt': instance.isAttempt,
      'isSection': instance.isSection,
      'isAccess': instance.isAccess,
      'isfeatured': instance.isfeatured,
      'exam_name': instance.examName,
      'time_duration': instance.timeDuration,
      'marks_awarded': instance.marksAwarded,
      'remainingAttempts': instance.remainingAttempts,
      'attempt': instance.attempt,
      'instruction': instance.instruction,
      'is_practice_mode': instance.isPracticeMode,
      'fromtime': instance.fromtime,
      'totime': instance.totime,
    };

MockExamTopicDetailModel _$MockExamTopicDetailModelFromJson(
        Map<String, dynamic> json) =>
    MockExamTopicDetailModel(
      id: (json['id'] as num?)?.toInt(),
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      sId: json['_id'] as String?,
      isfeatured: json['isfeatured'] as bool?,
      iV: (json['__v'] as num?)?.toInt(),
      categoryId: json['category_id'] as String?,
      marksDeducted: (json['marks_deducted'] as num?)?.toDouble(),
      marksAwarded: (json['marks_awarded'] as num?)?.toInt(),
      timeDuration: json['time_duration'] as String?,
      examName: json['exam_name'] as String?,
      remainingAttempts: (json['remainingAttempts'] as num?)?.toInt(),
      instruction: json['instruction'] as String?,
      fromtime: json['fromtime'] as String?,
      isPracticeMode: json['is_practice_mode'] as bool?,
      negativeMarking: json['negative_marking'] as bool?,
      totime: json['totime'] as String?,
      attempt: (json['attempt'] as num?)?.toInt(),
    )
      ..examId = json['examId'] as String?
      ..totalQuestions = (json['totalQuestions'] as num?)?.toInt()
      ..isDeclaration = json['isDeclaration'] as bool?
      ..isAttempt = json['isAttempt'] as bool?
      ..isAccess = json['isAccess'] as bool?
      ..isSection = json['isSection'] as bool?
      ..declarationTime = json['declarationTime'] as String?;

Map<String, dynamic> _$MockExamTopicDetailModelToJson(
        MockExamTopicDetailModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'examId': instance.examId,
      'id': instance.id,
      '__v': instance.iV,
      'remainingAttempts': instance.remainingAttempts,
      'totalQuestions': instance.totalQuestions,
      'isDeclaration': instance.isDeclaration,
      'isAttempt': instance.isAttempt,
      'isAccess': instance.isAccess,
      'isSection': instance.isSection,
      'category_id': instance.categoryId,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'negative_marking': instance.negativeMarking,
      'marks_deducted': instance.marksDeducted,
      'isfeatured': instance.isfeatured,
      'exam_name': instance.examName,
      'time_duration': instance.timeDuration,
      'marks_awarded': instance.marksAwarded,
      'attempt': instance.attempt,
      'instruction': instance.instruction,
      'is_practice_mode': instance.isPracticeMode,
      'fromtime': instance.fromtime,
      'declarationTime': instance.declarationTime,
      'totime': instance.totime,
    };
