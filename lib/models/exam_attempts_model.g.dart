// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_attempts_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExamAttemptsModel _$ExamAttemptsModelFromJson(Map<String, dynamic> json) =>
    ExamAttemptsModel(
      lastTime: json['lastTime'] as String,
      examId: json['examId'] as String,
      declarationTime: json['declarationTime'] as String,
      totime: json['totime'] as String,
      fromtime: json['fromtime'] as String,
      attemptList: (json['attemptList'] as List<dynamic>)
          .map((e) => Attempt.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExamAttemptsModelToJson(ExamAttemptsModel instance) =>
    <String, dynamic>{
      'lastTime': instance.lastTime,
      'examId': instance.examId,
      'declarationTime': instance.declarationTime,
      'totime': instance.totime,
      'fromtime': instance.fromtime,
      'attemptList': instance.attemptList,
    };

Attempt _$AttemptFromJson(Map<String, dynamic> json) => Attempt(
      userExamId: json['userExamId'] as String,
      isAttemptcount: (json['isAttemptcount'] as num).toInt(),
      userRank: (json['userRank'] as num).toInt(),
      mymark: (json['mymark'] as num).toInt(),
      Question: (json['Question'] as num).toInt(),
      visitedQuestions: (json['visitedQuestions'] as num).toInt(),
      totalMarks: (json['totalMarks'] as num).toInt(),
      percentage: json['percentage'] as String,
      accuracyPercentage: json['accuracyPercentage'] as String,
      correctAnswers: (json['correctAnswers'] as num).toInt(),
      incorrectAnswers: (json['incorrectAnswers'] as num).toInt(),
      skippedAnswers: (json['skippedAnswers'] as num).toInt(),
      predictedrank2024: json['predicted_rank_2024'] as String,
      predictedrank2022: json['predicted_rank_2022'] as String,
      predictedrank2023: json['predicted_rank_2023'] as String,
    );

Map<String, dynamic> _$AttemptToJson(Attempt instance) => <String, dynamic>{
      'userExamId': instance.userExamId,
      'isAttemptcount': instance.isAttemptcount,
      'userRank': instance.userRank,
      'mymark': instance.mymark,
      'Question': instance.Question,
      'visitedQuestions': instance.visitedQuestions,
      'totalMarks': instance.totalMarks,
      'percentage': instance.percentage,
      'accuracyPercentage': instance.accuracyPercentage,
      'correctAnswers': instance.correctAnswers,
      'incorrectAnswers': instance.incorrectAnswers,
      'skippedAnswers': instance.skippedAnswers,
      'predicted_rank_2024': instance.predictedrank2024,
      'predicted_rank_2022': instance.predictedrank2022,
      'predicted_rank_2023': instance.predictedrank2023,
    };
