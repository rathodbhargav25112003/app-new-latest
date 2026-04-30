// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_custom_test_query_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCustomTestQueryModel _$CreateCustomTestQueryModelFromJson(
        Map<String, dynamic> json) =>
    CreateCustomTestQueryModel(
      isSolveQuery: json['isSolveQuery'] as bool?,
      id: json['_id'] as String?,
      userId: json['user_id'] as String?,
      questionId: json['question_id'] as String?,
      query: json['query'] as String?,
      createdAt: json['created_at'] as String?,
      otherIssue: json['OtherIssue'] as bool?,
      explanationIssue: json['ExplanationIssue'] as bool?,
      incorrectAnswer: json['IncorrectAnswer'] as bool?,
      incorrectQuestion: json['IncorrectQuestion'] as bool?,
    );

Map<String, dynamic> _$CreateCustomTestQueryModelToJson(
        CreateCustomTestQueryModel instance) =>
    <String, dynamic>{
      'isSolveQuery': instance.isSolveQuery,
      'IncorrectQuestion': instance.incorrectQuestion,
      'IncorrectAnswer': instance.incorrectAnswer,
      'ExplanationIssue': instance.explanationIssue,
      'OtherIssue': instance.otherIssue,
      '_id': instance.id,
      'user_id': instance.userId,
      'question_id': instance.questionId,
      'query': instance.query,
      'created_at': instance.createdAt,
    };
