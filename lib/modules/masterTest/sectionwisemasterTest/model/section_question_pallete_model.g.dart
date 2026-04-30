// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'section_question_pallete_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SectionQuestionPalleteModel _$SectionQuestionPalleteModelFromJson(
        Map<String, dynamic> json) =>
    SectionQuestionPalleteModel(
      section: json['section'] as String?,
      status: json['status'] as String?,
      questions: (json['questions'] as List<dynamic>?)
          ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SectionQuestionPalleteModelToJson(
        SectionQuestionPalleteModel instance) =>
    <String, dynamic>{
      'section': instance.section,
      'status': instance.status,
      'questions': instance.questions?.map((e) => e.toJson()).toList(),
    };

Question _$QuestionFromJson(Map<String, dynamic> json) => Question(
      questionId: json['question_id'] as String?,
      questionNumber: (json['question_number'] as num?)?.toInt(),
      isAttempted: json['attempted'] as bool?,
      isMarkedForReview: json['marked_for_review'] as bool?,
      isAttemptedMarkedForReview: json['attempted_marked_for_review'] as bool?,
      isSkipped: json['skipped'] as bool?,
      isGuess: json['guess'] as bool?,
    );

Map<String, dynamic> _$QuestionToJson(Question instance) => <String, dynamic>{
      'question_id': instance.questionId,
      'question_number': instance.questionNumber,
      'attempted': instance.isAttempted,
      'marked_for_review': instance.isMarkedForReview,
      'attempted_marked_for_review': instance.isAttemptedMarkedForReview,
      'skipped': instance.isSkipped,
      'guess': instance.isGuess,
    };
