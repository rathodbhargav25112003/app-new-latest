import 'package:json_annotation/json_annotation.dart';

part 'exam_attempts_model.g.dart';

@JsonSerializable()
class ExamAttemptsModel {
  final String lastTime;
  final String examId;
  final String declarationTime;
  final String totime;
  final String fromtime;
  final List<Attempt> attemptList;

  ExamAttemptsModel({
    required this.lastTime,
    required this.examId,
    required this.declarationTime,
    required this.totime,
    required this.fromtime,
    required this.attemptList,
  });

  // Factory methods for serialization
  factory ExamAttemptsModel.fromJson(Map<String, dynamic> json) =>
      _$ExamAttemptsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExamAttemptsModelToJson(this);
}

@JsonSerializable()
class Attempt {
  final String userExamId;
  final int isAttemptcount;
  final int userRank;
  final int mymark;
  final int Question;
  final int visitedQuestions;
  final int totalMarks;
  final String percentage;
  final String accuracyPercentage;
  final int correctAnswers;
  final int incorrectAnswers;
  final int skippedAnswers;
  @JsonKey(name: 'predicted_rank_2024')
  String predictedrank2024;
  @JsonKey(name: 'predicted_rank_2022')
  String predictedrank2022;
  @JsonKey(name: 'predicted_rank_2023')
  String predictedrank2023;

  Attempt({
    required this.userExamId,
    required this.isAttemptcount,
    required this.userRank,
    required this.mymark,
    required this.Question,
    required this.visitedQuestions,
    required this.totalMarks,
    required this.percentage,
    required this.accuracyPercentage,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.skippedAnswers,
    required this.predictedrank2024,
    required this.predictedrank2022,
    required this.predictedrank2023,
  });

  // Factory methods for serialization
  factory Attempt.fromJson(Map<String, dynamic> json) =>
      _$AttemptFromJson(json);

  Map<String, dynamic> toJson() => _$AttemptToJson(this);
}
