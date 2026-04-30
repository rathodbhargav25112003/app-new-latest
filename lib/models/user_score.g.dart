// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserScore _$UserScoreFromJson(Map<String, dynamic> json) => UserScore(
      score: (json['score'] as num).toInt(),
      time: json['time'] as String,
      rank: (json['rank'] as num).toInt(),
      fullname: json['fullname'] as String,
      isAttemptcount: (json['isAttemptcount'] as num?)?.toInt() ?? 1,
      correct: (json['correct'] as num).toInt(),
      totalMarks: (json['totalMarks'] as num).toInt(),
      inCorrect: (json['inCorrect'] as num).toInt(),
      skipped: (json['skipped'] as num).toInt(),
      isMyRank: json['isMyRank'] as bool,
    );

Map<String, dynamic> _$UserScoreToJson(UserScore instance) => <String, dynamic>{
      'score': instance.score,
      'time': instance.time,
      'rank': instance.rank,
      'fullname': instance.fullname,
      'totalMarks': instance.totalMarks,
      'correct': instance.correct,
      'inCorrect': instance.inCorrect,
      'skipped': instance.skipped,
      'isAttemptcount': instance.isAttemptcount,
      'isMyRank': instance.isMyRank,
    };
