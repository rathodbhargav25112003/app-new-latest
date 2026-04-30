// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_all_my_custom_test_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyCustomTestListModel _$MyCustomTestListModelFromJson(
        Map<String, dynamic> json) =>
    MyCustomTestListModel(
      isSubscribe: json['isSubscribe'] as bool?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Data.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MyCustomTestListModelToJson(
        MyCustomTestListModel instance) =>
    <String, dynamic>{
      'isSubscribe': instance.isSubscribe,
      'data': instance.data?.map((e) => e.toJson()).toList(),
    };

Data _$DataFromJson(Map<String, dynamic> json) => Data(
      timeDuration: json['time_duration'] as String?,
      marksAwarded: (json['marks_awarded'] as num?)?.toInt(),
      remainingAttempts: (json['RemainingAttempts'] as num?)?.toInt(),
      description: json['Description'] as String?,
      subcategory: (json['subcategory'] as num?)?.toInt(),
      sId: json['_id'] as String?,
      category: (json['category'] as num?)?.toInt(),
      exam: (json['exam'] as num?)?.toInt(),
      exitUserExamId: json['exitUserExam_id'] as String?,
      isGivenTest: json['isGivenTest'] as bool?,
      isAttempt: json['isAttempt'] as bool?,
      numberOfQuestions: (json['NumberOfQuestions'] as num?)?.toInt(),
      testName: json['testName'] as String?,
      test: (json['test'] as List<dynamic>?)
          ?.map((e) => TestData.fromJson(e as Map<String, dynamic>))
          .toList(),
      topic: (json['topic'] as num?)?.toInt(),
    )..marksDeducted = (json['marks_deducted'] as num?)?.toInt();

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
      '_id': instance.sId,
      'testName': instance.testName,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'topic': instance.topic,
      'exam': instance.exam,
      'NumberOfQuestions': instance.numberOfQuestions,
      'time_duration': instance.timeDuration,
      'Description': instance.description,
      'marks_awarded': instance.marksAwarded,
      'marks_deducted': instance.marksDeducted,
      'RemainingAttempts': instance.remainingAttempts,
      'isGivenTest': instance.isGivenTest,
      'isAttempt': instance.isAttempt,
      'test': instance.test?.map((e) => e.toJson()).toList(),
      'exitUserExam_id': instance.exitUserExamId,
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
      selectedOption: json['selected_option'] as String?,
      isCorrect: json['is_correct'] as bool?,
    );

Map<String, dynamic> _$TestDataToJson(TestData instance) => <String, dynamic>{
      'question_image': instance.questionImg,
      'explanation_image': instance.explanationImg,
      '_id': instance.sId,
      'exam_id': instance.examId,
      'question_text': instance.questionText,
      'correct_option': instance.correctOption,
      'selected_option': instance.selectedOption,
      'is_correct': instance.isCorrect,
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
