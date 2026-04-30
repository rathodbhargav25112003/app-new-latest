// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_search_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlobalSearchDataModel _$GlobalSearchDataModelFromJson(
        Map<String, dynamic> json) =>
    GlobalSearchDataModel(
      id: json['_id'] as String?,
      categoryName: json['category_name'] as String?,
      subcategoryName: json['subcategory_name'] as String?,
      subName: json['sub_name'] as String?,
      topicName: json['topic_name'] as String?,
      description: json['description'] as String?,
      title: json['title'] as String?,
      contentUrl: json['content_url'] as String?,
      topicId: json['topic_id'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      categoryId: json['category_id'] as String?,
      examName: json['exam_name'] as String?,
      attempt: (json['attempt'] as num?)?.toInt(),
      totime: json['totime'] as String?,
      negativeMarking: json['negative_marking'] as bool?,
      isPracticeMode: json['is_practice_mode'] as bool?,
      fromtime: json['fromtime'] as String?,
      instruction: json['instruction'] as String?,
      timeDuration: json['time_duration'] as String?,
      marksAwarded: (json['marks_awarded'] as num?)?.toInt(),
      marksDeducted: (json['marks_deducted'] as num?)?.toDouble(),
      pdfId: json['pdf_id'] as String?,
      isPublic: json['isPublic'] as bool?,
      videoUrl: json['video_url'] as String?,
      questionId: (json['question_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isAccess: json['isAccess'] as bool?,
      numberOfQuestions: (json['NumberOfQuestions'] as num?)?.toInt(),
      type: json['type'] as String?,
      user_id: json['user_id'] as String?,
      exam: (json['exam'] as List<dynamic>?)
          ?.map((e) =>
              GlobalCustomCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      testName: json['testName'] as String?,
      category: (json['category'] as List<dynamic>?)
          ?.map((e) =>
              GlobalCustomCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      subcategory: (json['subcategory'] as List<dynamic>?)
          ?.map((e) =>
              GlobalCustomCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      topic: (json['topic'] as List<dynamic>?)
          ?.map((e) =>
              GlobalCustomCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      bannerImg: json['Banner_img'] as String?,
      contentType: json['content_type'] as String?,
      Description: json['Description'] as String?,
      isfeatured: json['isfeatured'] as bool?,
      isBookmark: json['isBookmark'] as bool?,
      videoLink: json['videoLink'] as String?,
    )
      ..subscriptionId = (json['subscription_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..annotation = (json['annotation'] as List<dynamic>?)
          ?.map((e) => AnnotationList.fromJson(e as Map<String, dynamic>))
          .toList()
      ..videoFiles = (json['videoFiles'] as List<dynamic>?)
          ?.map((e) => Files.fromJson(e as Map<String, dynamic>))
          .toList()
      ..downloadVideo = (json['downloadVideo'] as List<dynamic>?)
          ?.map((e) => Download.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$GlobalSearchDataModelToJson(
        GlobalSearchDataModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'category_name': instance.categoryName,
      'subcategory_name': instance.subcategoryName,
      'subscription_id': instance.subscriptionId,
      'sub_name': instance.subName,
      'content_url': instance.contentUrl,
      'video_url': instance.videoUrl,
      'topic_name': instance.topicName,
      'subcategory_id': instance.subcategoryId,
      'topic_id': instance.topicId,
      'category_id': instance.categoryId,
      'title': instance.title,
      'description': instance.description,
      'Banner_img': instance.bannerImg,
      'content_type': instance.contentType,
      'pdf_id': instance.pdfId,
      'type': instance.type,
      'isAccess': instance.isAccess,
      'isfeatured': instance.isfeatured,
      'isBookmark': instance.isBookmark,
      'isPublic': instance.isPublic,
      'negative_marking': instance.negativeMarking,
      'marks_deducted': instance.marksDeducted,
      'is_practice_mode': instance.isPracticeMode,
      'fromtime': instance.fromtime,
      'totime': instance.totime,
      'exam_name': instance.examName,
      'time_duration': instance.timeDuration,
      'marks_awarded': instance.marksAwarded,
      'attempt': instance.attempt,
      'instruction': instance.instruction,
      'user_id': instance.user_id,
      'testName': instance.testName,
      'videoLink': instance.videoLink,
      'Description': instance.Description,
      'NumberOfQuestions': instance.numberOfQuestions,
      'question_id': instance.questionId,
      'category': instance.category?.map((e) => e.toJson()).toList(),
      'subcategory': instance.subcategory?.map((e) => e.toJson()).toList(),
      'topic': instance.topic?.map((e) => e.toJson()).toList(),
      'exam': instance.exam?.map((e) => e.toJson()).toList(),
      'annotation': instance.annotation?.map((e) => e.toJson()).toList(),
      'videoFiles': instance.videoFiles?.map((e) => e.toJson()).toList(),
      'downloadVideo': instance.downloadVideo?.map((e) => e.toJson()).toList(),
    };

GlobalCustomCategoryModel _$GlobalCustomCategoryModelFromJson(
        Map<String, dynamic> json) =>
    GlobalCustomCategoryModel(
      id: json['_id'] as String?,
      categoryName: json['category_name'] as String?,
      subcategoryName: json['subcategory_name'] as String?,
      topicName: json['topic_name'] as String?,
      topicId: json['topic_id'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      categoryId: json['category_id'] as String?,
      examName: json['exam_name'] as String?,
      examId: json['exam_id'] as String?,
    );

Map<String, dynamic> _$GlobalCustomCategoryModelToJson(
        GlobalCustomCategoryModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'category_name': instance.categoryName,
      'subcategory_name': instance.subcategoryName,
      'topic_name': instance.topicName,
      'exam_name': instance.examName,
      'exam_id': instance.examId,
      'subcategory_id': instance.subcategoryId,
      'topic_id': instance.topicId,
      'category_id': instance.categoryId,
    };
