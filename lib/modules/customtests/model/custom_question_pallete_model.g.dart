// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_question_pallete_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomTestQuestionPalleteModel _$CustomTestQuestionPalleteModelFromJson(
        Map<String, dynamic> json) =>
    CustomTestQuestionPalleteModel(
      questionId: json['question_id'] as String?,
      questionNumber: (json['question_number'] as num?)?.toInt(),
      isAttempted: json['attempted'] as bool?,
      isMarkedForReview: json['marked_for_review'] as bool?,
      isAttemptedMarkedForReview: json['attempted_marked_for_review'] as bool?,
      isSkipped: json['skipped'] as bool?,
      isGuess: json['guess'] as bool?,
    );

Map<String, dynamic> _$CustomTestQuestionPalleteModelToJson(
        CustomTestQuestionPalleteModel instance) =>
    <String, dynamic>{
      'question_id': instance.questionId,
      'question_number': instance.questionNumber,
      'attempted': instance.isAttempted,
      'marked_for_review': instance.isMarkedForReview,
      'attempted_marked_for_review': instance.isAttemptedMarkedForReview,
      'skipped': instance.isSkipped,
      'guess': instance.isGuess,
    };
