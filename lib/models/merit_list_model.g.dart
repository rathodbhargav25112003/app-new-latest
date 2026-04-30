// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merit_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeritListModel _$MeritListModelFromJson(Map<String, dynamic> json) =>
    MeritListModel(
      examId: json['exam_id'] as String?,
      fullName: json['fullname'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      rank: (json['rank'] as num?)?.toInt(),
      correct: (json['correct'] as num?)?.toInt(),
      inCorrect: (json['inCorrect'] as num?)?.toInt(),
      isMyRank: json['isMyRank'] as bool?,
      skipped: (json['skipped'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MeritListModelToJson(MeritListModel instance) =>
    <String, dynamic>{
      'exam_id': instance.examId,
      'fullname': instance.fullName,
      'score': instance.score,
      'rank': instance.rank,
      'inCorrect': instance.inCorrect,
      'skipped': instance.skipped,
      'correct': instance.correct,
      'isMyRank': instance.isMyRank,
    };
