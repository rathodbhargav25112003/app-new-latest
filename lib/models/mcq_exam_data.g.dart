// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcq_exam_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McqExamData _$McqExamDataFromJson(Map<String, dynamic> json) => McqExamData(
      isPractice: json['isPractice'] as bool? ?? false,
      isAttempt: json['isAttempt'] as bool? ?? false,
      lastPracticeTime: json['lastPracticeTime'] as String? ?? '',
      lastPracticeId: json['lastPracticeId'] as String? ?? '',
      lastTestModeTime: json['lastTestModeTime'] as String? ?? '',
      lastTestModeId: json['lastTestModeId'] as String? ?? '',
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      totalMarks: (json['totalMarks'] as num?)?.toInt() ?? 0,
      bookmarkCount: (json['bookmarkCount'] as num?)?.toInt() ?? 0,
      practiceReport: json['practiceReport'] == null
          ? null
          : PracticeReport.fromJson(
              json['practiceReport'] as Map<String, dynamic>),
      attemptList: (json['attemptList'] as List<dynamic>?)
          ?.map((e) => Attempt.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$McqExamDataToJson(McqExamData instance) =>
    <String, dynamic>{
      'isPractice': instance.isPractice,
      'isAttempt': instance.isAttempt,
      'lastPracticeTime': instance.lastPracticeTime,
      'lastPracticeId': instance.lastPracticeId,
      'lastTestModeTime': instance.lastTestModeTime,
      'lastTestModeId': instance.lastTestModeId,
      'totalQuestions': instance.totalQuestions,
      'totalMarks': instance.totalMarks,
      'bookmarkCount': instance.bookmarkCount,
      'practiceReport': instance.practiceReport,
      'attemptList': instance.attemptList,
    };

PracticeReport _$PracticeReportFromJson(Map<String, dynamic> json) =>
    PracticeReport(
      userExam_id: json['userExam_id'] as String? ?? '',
      correctAnswersCount: (json['correctAnswersCount'] as num?)?.toInt() ?? 0,
      incorrectAnswersCount:
          (json['incorrectAnswersCount'] as num?)?.toInt() ?? 0,
      skippedAnswersCount: (json['skippedAnswersCount'] as num?)?.toInt() ?? 0,
      attemptedQuestion: (json['attemptedQuestion'] as num?)?.toInt() ?? 0,
      bookmarkCount: (json['bookmarkCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PracticeReportToJson(PracticeReport instance) =>
    <String, dynamic>{
      'userExam_id': instance.userExam_id,
      'correctAnswersCount': instance.correctAnswersCount,
      'incorrectAnswersCount': instance.incorrectAnswersCount,
      'skippedAnswersCount': instance.skippedAnswersCount,
      'attemptedQuestion': instance.attemptedQuestion,
      'bookmarkCount': instance.bookmarkCount,
    };

Attempt _$AttemptFromJson(Map<String, dynamic> json) => Attempt(
      userExam_id: json['userExam_id'] as String? ?? '',
      userExamType: json['userExamType'] as String? ?? '',
      mainUserExam_id: json['mainUserExam_id'] as String? ?? '',
      correctAnswersCount: (json['correctAnswersCount'] as num?)?.toInt() ?? 0,
      incorrectAnswersCount:
          (json['incorrectAnswersCount'] as num?)?.toInt() ?? 0,
      skippedAnswersCount: (json['skippedAnswersCount'] as num?)?.toInt() ?? 0,
      attemptedQuestion: (json['attemptedQuestion'] as num?)?.toInt() ?? 0,
      accuracyPercentage: json['accuracyPercentage'] as String? ?? '0.0',
      isAttemptcount: (json['isAttemptcount'] as num?)?.toInt() ?? 0,
      mymark: (json['mymark'] as num?)?.toInt() ?? 0,
      totalMarks: (json['totalMarks'] as num?)?.toInt() ?? 0,
      bookmarkCount: (json['bookmarkCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AttemptToJson(Attempt instance) => <String, dynamic>{
      'userExam_id': instance.userExam_id,
      'userExamType': instance.userExamType,
      'mainUserExam_id': instance.mainUserExam_id,
      'correctAnswersCount': instance.correctAnswersCount,
      'incorrectAnswersCount': instance.incorrectAnswersCount,
      'skippedAnswersCount': instance.skippedAnswersCount,
      'attemptedQuestion': instance.attemptedQuestion,
      'accuracyPercentage': instance.accuracyPercentage,
      'isAttemptcount': instance.isAttemptcount,
      'mymark': instance.mymark,
      'totalMarks': instance.totalMarks,
      'bookmarkCount': instance.bookmarkCount,
    };
