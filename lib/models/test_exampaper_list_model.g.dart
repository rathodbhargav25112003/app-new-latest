// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_exampaper_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestExamPaperListModel _$TestExamPaperListModelFromJson(
        Map<String, dynamic> json) =>
    TestExamPaperListModel(
      negativeMarking: json['negative_marking'] as bool?,
      marksDeducted: (json['marks_deducted'] as num?)?.toDouble(),
      examId: json['_id'] as String?,
      id: (json['id'] as num?)?.toInt(),
      examName: json['exam_name'] as String?,
      categoryId: json['category_id'] as String?,
      timeDuration: json['time_duration'] as String?,
      marksAwarded: (json['marks_awarded'] as num?)?.toInt(),
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      isAttempt: json['isAttempt'] as bool?,
      plan_id: json['plan_id'] as String?,
      isfreeTrail: json['isfreeTrail'] as bool?,
      sid: json['sid'] as String?,
      instruction: json['instruction'] as String?,
      test: (json['test'] as List<dynamic>?)
          ?.map((e) => TestData.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPracticeExamAttempt: json['isPracticeExamAttempt'] as bool?,
      isAccess: json['isAccess'] as bool?,
      isPracticeMode: json['is_practice_mode'] as bool?,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt(),
      totalMarks: (json['totalMarks'] as num?)?.toInt(),
      highestScore: (json['highestScore'] as num?)?.toInt(),
      highestScoreRank: (json['highestScoreRank'] as num?)?.toInt(),
      remainingAttempts: (json['remainingAttempts'] as num?)?.toInt(),
      fromtime: json['fromtime'] as String?,
      totime: json['totime'] as String?,
      isDeclaration: json['isDeclaration'] as bool?,
      exitUserExamId: json['exitUserExam_id'] as String?,
      isCorrect: json['is_correct'] as bool?,
      declarationTime: json['declarationTime'] as String?,
      day: json['day'] as String? ?? "0",
      isGivenTest: json['isGivenTest'] as bool?,
      isSection: json['isSection'] as bool?,
      sectionWiseCount: (json['sectionWiseCount'] as num?)?.toInt(),
    )
      ..sectionData = (json['sectiondata'] as List<dynamic>?)
          ?.map((e) => SectionData.fromJson(e as Map<String, dynamic>))
          .toList()
      ..lastPracticeTime = json['lastPracticeTime'] as String?
      ..lastTestModeTime = json['lastTestModeTime'] as String?
      ..userExamType = json['userExamType'] as String?
      ..isCompleted = json['isCompleted'] as bool?
      ..practiceAnswersCount = (json['practiceAnswersCount'] as num?)?.toInt();

Map<String, dynamic> _$TestExamPaperListModelToJson(
        TestExamPaperListModel instance) =>
    <String, dynamic>{
      'negative_marking': instance.negativeMarking,
      'marks_deducted': instance.marksDeducted,
      '_id': instance.examId,
      'id': instance.id,
      'isDeclaration': instance.isDeclaration,
      'isGivenTest': instance.isGivenTest,
      'declarationTime': instance.declarationTime,
      'exam_name': instance.examName,
      'category_id': instance.categoryId,
      'time_duration': instance.timeDuration,
      'marks_awarded': instance.marksAwarded,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'isAttempt': instance.isAttempt,
      'sid': instance.sid,
      'instruction': instance.instruction,
      'day': instance.day,
      'test': instance.test?.map((e) => e.toJson()).toList(),
      'sectiondata': instance.sectionData?.map((e) => e.toJson()).toList(),
      'isPracticeExamAttempt': instance.isPracticeExamAttempt,
      'isAccess': instance.isAccess,
      'is_practice_mode': instance.isPracticeMode,
      'isSection': instance.isSection,
      'isfreeTrail': instance.isfreeTrail,
      'plan_id': instance.plan_id,
      'sectionWiseCount': instance.sectionWiseCount,
      'highestScoreRank': instance.highestScoreRank,
      'highestScore': instance.highestScore,
      'totalMarks': instance.totalMarks,
      'totalQuestions': instance.totalQuestions,
      'remainingAttempts': instance.remainingAttempts,
      'exitUserExam_id': instance.exitUserExamId,
      'is_correct': instance.isCorrect,
      'fromtime': instance.fromtime,
      'totime': instance.totime,
      'lastPracticeTime': instance.lastPracticeTime,
      'lastTestModeTime': instance.lastTestModeTime,
      'userExamType': instance.userExamType,
      'isCompleted': instance.isCompleted,
      'practiceAnswersCount': instance.practiceAnswersCount,
    };

TestData _$TestDataFromJson(Map<String, dynamic> json) => TestData(
      questionImg: (json['question_image'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      explanationImg: (json['explanation_image'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      sId: json['_id'] as String?,
      examId: json['exam_id'] as String?,
      questionText: json['question_text'] as String?,
      correctOption: json['correct_option'] as String?,
      correctPercentage: json['correctPercentage'] as String?,
      explanation: json['explanation'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      id: (json['id'] as num?)?.toInt(),
      skipped: json['skipped'] as bool?,
      optionsData: (json['options'] as List<dynamic>?)
          ?.map((e) => Options.fromJson(e as Map<String, dynamic>))
          .toList(),
      questionNumber: (json['question_number'] as num?)?.toInt(),
      selectedOption: json['selected_option'] as String?,
      isCorrect: json['is_correct'] as bool?,
      statusColor: (json['statusColor'] as num?)?.toInt(),
      isHighlight: json['isHighlight'] as bool?,
      txtColor: (json['txtColor'] as num?)?.toInt(),
      annotationData: (json['annotation_data'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      bookmarks: json['bookmarks'] as bool?,
    );

Map<String, dynamic> _$TestDataToJson(TestData instance) => <String, dynamic>{
      'question_image': instance.questionImg,
      'explanation_image': instance.explanationImg,
      '_id': instance.sId,
      'exam_id': instance.examId,
      'question_text': instance.questionText,
      'correct_option': instance.correctOption,
      'explanation': instance.explanation,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'id': instance.id,
      'skipped': instance.skipped,
      'isHighlight': instance.isHighlight,
      'annotation_data': instance.annotationData,
      'options': instance.optionsData?.map((e) => e.toJson()).toList(),
      'question_number': instance.questionNumber,
      'selected_option': instance.selectedOption,
      'correctPercentage': instance.correctPercentage,
      'is_correct': instance.isCorrect,
      'statusColor': instance.statusColor,
      'txtColor': instance.txtColor,
      'bookmarks': instance.bookmarks,
    };

SectionData _$SectionDataFromJson(Map<String, dynamic> json) => SectionData(
      section: json['section'] as String?,
      timeDuration: json['time_duration'] as String?,
      questionCount: (json['questionCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SectionDataToJson(SectionData instance) =>
    <String, dynamic>{
      'section': instance.section,
      'time_duration': instance.timeDuration,
      'questionCount': instance.questionCount,
    };

Options _$OptionsFromJson(Map<String, dynamic> json) => Options(
      answerImg: json['answer_image'] as String?,
      answerTitle: json['answer_title'] as String?,
      sId: json['_id'] as String?,
      value: json['value'] as String?,
      percentage: json['percentage'] as String?,
    );

Map<String, dynamic> _$OptionsToJson(Options instance) => <String, dynamic>{
      'answer_image': instance.answerImg,
      'answer_title': instance.answerTitle,
      '_id': instance.sId,
      'value': instance.value,
      'percentage': instance.percentage,
    };
