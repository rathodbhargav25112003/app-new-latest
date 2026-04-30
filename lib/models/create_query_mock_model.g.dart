// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_query_mock_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateQueryMockModel _$CreateQueryMockModelFromJson(
        Map<String, dynamic> json) =>
    CreateQueryMockModel(
      isSolveQuery: json['isSolveQuery'] as bool?,
      id: json['_id'] as String?,
      userId: json['user_id'] as String?,
      questionId: json['question_id'] as String?,
      query: json['query'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$CreateQueryMockModelToJson(
        CreateQueryMockModel instance) =>
    <String, dynamic>{
      'isSolveQuery': instance.isSolveQuery,
      '_id': instance.id,
      'user_id': instance.userId,
      'question_id': instance.questionId,
      'query': instance.query,
      'created_at': instance.createdAt,
    };
