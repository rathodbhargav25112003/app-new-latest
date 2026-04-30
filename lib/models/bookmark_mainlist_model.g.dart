// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_mainlist_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookMarkMainListModel _$BookMarkMainListModelFromJson(
        Map<String, dynamic> json) =>
    BookMarkMainListModel(
      examId: json['exam_id'] as String?,
      negativeMarking: json['negative_marking'] as bool?,
      examName: json['exam_name'] as String?,
      subcategoryId: json['subcategory_id'] as String?,
      subcategoryName: json['subcategory_name'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      topicId: json['topic_id'] as String?,
      topicName: json['topic_name'] as String?,
      timeDuration: json['time_duration'] as String?,
      marksDeducted: json['marks_deducted'] as num?,
      marksAwarded: json['marks_awarded'] as num?,
      createdAt: json['created_at'] as String?,
      attemptCount: (json['Attemptcount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BookMarkMainListModelToJson(
        BookMarkMainListModel instance) =>
    <String, dynamic>{
      'exam_id': instance.examId,
      'negative_marking': instance.negativeMarking,
      'exam_name': instance.examName,
      'subcategory_id': instance.subcategoryId,
      'subcategory_name': instance.subcategoryName,
      'category_id': instance.categoryId,
      'category_name': instance.categoryName,
      'topic_id': instance.topicId,
      'topic_name': instance.topicName,
      'time_duration': instance.timeDuration,
      'marks_deducted': instance.marksDeducted,
      'marks_awarded': instance.marksAwarded,
      'created_at': instance.createdAt,
      'Attemptcount': instance.attemptCount,
    };
