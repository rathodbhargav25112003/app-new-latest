// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_count_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeCountModel _$PracticeCountModelFromJson(Map<String, dynamic> json) =>
    PracticeCountModel(
      correctAnswers: (json['correctAnswers'] as num?)?.toInt(),
      incorrectAnswers: (json['incorrectAnswers'] as num?)?.toInt(),
      attempted: (json['attempted'] as num?)?.toInt(),
      notVisited: (json['not_visited'] as num?)?.toInt(),
      bookmarkCount: (json['bookmarkCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PracticeCountModelToJson(PracticeCountModel instance) =>
    <String, dynamic>{
      'attempted': instance.attempted,
      'correctAnswers': instance.correctAnswers,
      'incorrectAnswers': instance.incorrectAnswers,
      'not_visited': instance.notVisited,
      'bookmarkCount': instance.bookmarkCount,
    };
