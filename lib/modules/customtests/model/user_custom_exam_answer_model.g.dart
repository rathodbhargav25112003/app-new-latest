// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_custom_exam_answer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserCustomExamAnswer _$UserCustomExamAnswerFromJson(
        Map<String, dynamic> json) =>
    UserCustomExamAnswer(
      isCorrect: json['is_correct'] as bool?,
      attempted: json['attempted'] as bool?,
      markedForReview: json['marked_for_review'] as bool?,
      attemptedMarkedForReview: json['attempted_marked_for_review'] as bool?,
      skipped: json['skipped'] as bool?,
      bookmarks: json['bookmarks'] as bool?,
      deleted_at: json['deleted_at'] as String?,
      sId: json['_id'] as String?,
      guess: json['guess'] as String?,
      selectedOption: json['selected_option'] as String?,
      previousSelected: json['previousSelected'] as String?,
      userExamId: json['userExam_id'] as String?,
      questionId: json['question_id'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      time: json['time'] as String?,
      iV: (json['__v'] as num?)?.toInt(),
      id: (json['id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserCustomExamAnswerToJson(
        UserCustomExamAnswer instance) =>
    <String, dynamic>{
      'is_correct': instance.isCorrect,
      'attempted': instance.attempted,
      'marked_for_review': instance.markedForReview,
      'attempted_marked_for_review': instance.attemptedMarkedForReview,
      'skipped': instance.skipped,
      'bookmarks': instance.bookmarks,
      'deleted_at': instance.deleted_at,
      '_id': instance.sId,
      'time': instance.time,
      'guess': instance.guess,
      'previousSelected': instance.previousSelected,
      'userExam_id': instance.userExamId,
      'question_id': instance.questionId,
      'selected_option': instance.selectedOption,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'id': instance.id,
      '__v': instance.iV,
    };
