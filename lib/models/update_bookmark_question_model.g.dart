// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_bookmark_question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateBookMarkModel _$UpdateBookMarkModelFromJson(Map<String, dynamic> json) =>
    UpdateBookMarkModel(
      msg: json['msg'] as String?,
      data: json['data'] == null
          ? null
          : BookMarkData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UpdateBookMarkModelToJson(
        UpdateBookMarkModel instance) =>
    <String, dynamic>{
      'msg': instance.msg,
      'data': instance.data?.toJson(),
    };

BookMarkData _$BookMarkDataFromJson(Map<String, dynamic> json) => BookMarkData(
      isCorrect: json['is_correct'] as bool?,
      attempted: json['attempted'] as bool?,
      markedForReview: json['marked_for_review'] as bool?,
      attemptedMarkedForReview: json['attempted_marked_for_review'] as bool?,
      skipped: json['skipped'] as bool?,
      bookmarks: json['bookmarks'] as bool?,
      id: json['_id'] as String?,
      userExamId: json['userExam_id'] as String?,
      questionId: json['question_id'] as String?,
      selectedOption: json['selected_option'] as String?,
      time: json['time'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
    );

Map<String, dynamic> _$BookMarkDataToJson(BookMarkData instance) =>
    <String, dynamic>{
      'is_correct': instance.isCorrect,
      'attempted': instance.attempted,
      'marked_for_review': instance.markedForReview,
      'attempted_marked_for_review': instance.attemptedMarkedForReview,
      'skipped': instance.skipped,
      'bookmarks': instance.bookmarks,
      '_id': instance.id,
      'userExam_id': instance.userExamId,
      'question_id': instance.questionId,
      'selected_option': instance.selectedOption,
      'time': instance.time,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
    };
