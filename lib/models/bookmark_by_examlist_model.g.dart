// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_by_examlist_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookMarkByExamListModel _$BookMarkByExamListModelFromJson(
        Map<String, dynamic> json) =>
    BookMarkByExamListModel(
      examId: json['exam_id'] as String?,
      examName: json['exam_name'] as String?,
      instruction: json['instruction'] as String?,
      topic_id: json['topic_id'] as String?,
      category_id: json['category_id'] as String?,
      bookmarkCount: (json['bookmarkCount'] as num?)?.toInt(),
      questionCount: (json['questionCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BookMarkByExamListModelToJson(
        BookMarkByExamListModel instance) =>
    <String, dynamic>{
      'exam_id': instance.examId,
      'exam_name': instance.examName,
      'topic_id': instance.topic_id,
      'category_id': instance.category_id,
      'instruction': instance.instruction,
      'bookmarkCount': instance.bookmarkCount,
      'questionCount': instance.questionCount,
    };
