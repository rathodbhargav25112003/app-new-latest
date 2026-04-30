// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homepage_watching_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomePageWatchingModel _$HomePageWatchingModelFromJson(
        Map<String, dynamic> json) =>
    HomePageWatchingModel(
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
      timeDuration: json['time_duration'] as String?,
      examName: json['exam_name'] as String?,
      topicName: json['topic_name'] as String?,
      type: json['type'] as String?,
      marksDeducted: (json['marks_deducted'] as num?)?.toDouble(),
      marksAwarded: (json['marks_awarded'] as num?)?.toInt(),
      instruction: json['instruction'] as String?,
      fromtime: json['fromtime'] as String?,
      isPracticeMode: json['is_practice_mode'] as bool?,
      negativeMarking: json['negative_marking'] as bool?,
      totime: json['totime'] as String?,
      attempt: (json['attempt'] as num?)?.toInt(),
      subcategoryName: json['subcategory_name'] as String?,
      categoryName: json['category_name'] as String?,
      pausedTime: json['pausedTime'] as String?,
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
      examId: json['examId'] as String?,
      remainingAttempts: (json['remainingAttempts'] as num?)?.toInt(),
      totalQuestions: (json['totalQuestions'] as num?)?.toInt(),
      isDeclaration: json['isDeclaration'] as bool?,
      isAttempt: json['isAttempt'] as bool?,
      isSection: json['isSection'] as bool?,
      declarationTime: json['declarationTime'] as String?,
    );

Map<String, dynamic> _$HomePageWatchingModelToJson(
        HomePageWatchingModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'id': instance.id,
      '__v': instance.iV,
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
      'isPublic': instance.isPublic,
      'isCompleted': instance.isCompleted,
      'isfeatured': instance.isfeatured,
      'Pdfcontents': instance.pdfcontents,
      'topic_name': instance.topicName,
      'subcategory_name': instance.subcategoryName,
      'category_name': instance.categoryName,
      'negative_marking': instance.negativeMarking,
      'marks_deducted': instance.marksDeducted,
      'exam_name': instance.examName,
      'time_duration': instance.timeDuration,
      'marks_awarded': instance.marksAwarded,
      'attempt': instance.attempt,
      'instruction': instance.instruction,
      'is_practice_mode': instance.isPracticeMode,
      'fromtime': instance.fromtime,
      'totime': instance.totime,
      'type': instance.type,
      'pausedTime': instance.pausedTime,
      'videoLink': instance.videoLink,
      'examId': instance.examId,
      'remainingAttempts': instance.remainingAttempts,
      'totalQuestions': instance.totalQuestions,
      'isDeclaration': instance.isDeclaration,
      'isAttempt': instance.isAttempt,
      'isSection': instance.isSection,
      'declarationTime': instance.declarationTime,
      'videoFiles': instance.videoFiles?.map((e) => e.toJson()).toList(),
      'downloadVideo': instance.downloadVideo?.map((e) => e.toJson()).toList(),
      'isBookmark': instance.isBookmark,
      'annotation': instance.annotation?.map((e) => e.toJson()).toList(),
    };
