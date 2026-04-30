// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizModel _$QuizModelFromJson(Map<String, dynamic> json) => QuizModel(
      description: json['description'] as String?,
      marksAwarded: json['marks_awarded'] as num?,
      marksDeducted: json['marks_deducted'] as num?,
      timeDuration: json['time_duration'] as String?,
      correct: (json['correct'] as num?)?.toInt(),
      created_at: json['created_at'] as String?,
      dateTime: json['dateTime'] as String?,
      incorrect: (json['incorrect'] as num?)?.toInt(),
      isTodayQuizComplete: json['isTodayQuizComplete'] as bool?,
      quizId: json['quiz_id'] as String?,
      quizName: json['quiz_name'] as String?,
      test: (json['test'] as List<dynamic>?)
          ?.map((e) => TestData.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalQuestion: (json['totalQuestion'] as num?)?.toInt(),
      quizUserExamId: json['quizUserExam_id'] as String?,
    );

Map<String, dynamic> _$QuizModelToJson(QuizModel instance) => <String, dynamic>{
      'quiz_id': instance.quizId,
      'quizUserExam_id': instance.quizUserExamId,
      'quiz_name': instance.quizName,
      'dateTime': instance.dateTime,
      'time_duration': instance.timeDuration,
      'description': instance.description,
      'isTodayQuizComplete': instance.isTodayQuizComplete,
      'correct': instance.correct,
      'test': instance.test?.map((e) => e.toJson()).toList(),
      'incorrect': instance.incorrect,
      'marks_deducted': instance.marksDeducted,
      'marks_awarded': instance.marksAwarded,
      'totalQuestion': instance.totalQuestion,
      'created_at': instance.created_at,
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
      explanation: json['explanation'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      id: (json['id'] as num?)?.toInt(),
      optionsData: (json['options'] as List<dynamic>?)
          ?.map((e) => Options.fromJson(e as Map<String, dynamic>))
          .toList(),
      questionNumber: (json['question_number'] as num?)?.toInt(),
      statusColor: (json['statusColor'] as num?)?.toInt(),
      txtColor: (json['txtColor'] as num?)?.toInt(),
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
      'options': instance.optionsData?.map((e) => e.toJson()).toList(),
      'question_number': instance.questionNumber,
      'statusColor': instance.statusColor,
      'txtColor': instance.txtColor,
      'bookmarks': instance.bookmarks,
    };

Options _$OptionsFromJson(Map<String, dynamic> json) => Options(
      answerImg: json['answer_image'] as String?,
      answerTitle: json['answer_title'] as String?,
      sId: json['_id'] as String?,
      value: json['value'] as String?,
    );

Map<String, dynamic> _$OptionsToJson(Options instance) => <String, dynamic>{
      'answer_image': instance.answerImg,
      'answer_title': instance.answerTitle,
      '_id': instance.sId,
      'value': instance.value,
    };
