// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'master_solution_reports_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MasterSolutionReportsModel _$MasterSolutionReportsModelFromJson(
        Map<String, dynamic> json) =>
    MasterSolutionReportsModel(
      questions: (json['questions'] as List<dynamic>?)
          ?.map((e) => Questions.fromJson(e as Map<String, dynamic>))
          .toList(),
      topicName: json['topicName'] as String?,
    );

Map<String, dynamic> _$MasterSolutionReportsModelToJson(
        MasterSolutionReportsModel instance) =>
    <String, dynamic>{
      'questions': instance.questions?.map((e) => e.toJson()).toList(),
      'topicName': instance.topicName,
    };

Questions _$QuestionsFromJson(Map<String, dynamic> json) => Questions(
      isCorrect: json['is_correct'] as bool?,
      bookmarks: json['bookmarks'] as bool?,
      selectedOption: json['selected_option'] as String?,
      questionImg: (json['question_image'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      explanationImg: (json['explanation_image'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      questionId: json['question_id'] as String?,
      userAnswerId: json['userAnswer_id'] as String?,
      examId: json['exam_id'] as String?,
      questionText: json['question_text'] as String?,
      correctOption: json['correct_option'] as String?,
      correctPercentage: json['correctPercentage'] as String?,
      explanation: json['explanation'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      id: (json['id'] as num?)?.toInt(),
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => Options.fromJson(e as Map<String, dynamic>))
          .toList(),
      questionNumber: (json['question_number'] as num?)?.toInt(),
      timePerQuestion: json['timePerQuestion'] as String?,
      isHighlight: json['isHighlight'] as bool?,
      annotationData: (json['annotation_data'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      statusColor: (json['statusColor'] as num?)?.toInt(),
      txtColor: (json['txtColor'] as num?)?.toInt(),
      guess: json['guess'] as String?,
      Notes: json['Notes'] as String?,
      topicName: json['topicName'] as String?,
      skipped: json['skipped'] as bool?,
    )
      ..markedforreview = json['marked_for_review'] as String?
      ..attemptedmarkedforreview =
          json['attempted_marked_for_review'] as String?
      ..bookmarkId = json['bookmark_id'] as String?;

Map<String, dynamic> _$QuestionsToJson(Questions instance) => <String, dynamic>{
      'is_correct': instance.isCorrect,
      'bookmarks': instance.bookmarks,
      'selected_option': instance.selectedOption,
      'guess': instance.guess,
      'question_image': instance.questionImg,
      'explanation_image': instance.explanationImg,
      'question_id': instance.questionId,
      'userAnswer_id': instance.userAnswerId,
      'exam_id': instance.examId,
      'question_text': instance.questionText,
      'correct_option': instance.correctOption,
      'marked_for_review': instance.markedforreview,
      'attempted_marked_for_review': instance.attemptedmarkedforreview,
      'correctPercentage': instance.correctPercentage,
      'isHighlight': instance.isHighlight,
      'annotation_data': instance.annotationData,
      'explanation': instance.explanation,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'id': instance.id,
      'options': instance.options?.map((e) => e.toJson()).toList(),
      'question_number': instance.questionNumber,
      'statusColor': instance.statusColor,
      'txtColor': instance.txtColor,
      'bookmark_id': instance.bookmarkId,
      'Notes': instance.Notes,
      'topicName': instance.topicName,
      'timePerQuestion': instance.timePerQuestion,
      'skipped': instance.skipped,
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
