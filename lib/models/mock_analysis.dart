import 'package:json_annotation/json_annotation.dart';

part 'mock_analysis.g.dart';

@JsonSerializable()
class McqAnalysis {
  final int mymark;
  final int totalQuestions;
  final int mark;
  final String totalTime;
  final String percentage;
  final int correctAnswers;
  final int incorrectAnswers;
  final int skippedAnswers;
  final String correctAnswersPercentage;
  final String incorrectAnswersPercentage;
  final String skippedAnswersPercentage;
  final String accuracyPercentage;
  final int guessedAnswersCount;
  final int correctGuessCount;
  final String correctGuessPercentage;
  final int wrongGuessCount;
  final String wrongGuessPercentage;
  final int incorrect_correct;
  final int correct_incorrect;
  final int incorrect_incorres;

  McqAnalysis({
    required this.mymark,
    required this.totalQuestions,
    required this.mark,
    required this.totalTime,
    required this.percentage,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.skippedAnswers,
    required this.correctAnswersPercentage,
    required this.incorrectAnswersPercentage,
    required this.skippedAnswersPercentage,
    required this.accuracyPercentage,
    required this.guessedAnswersCount,
    required this.correctGuessCount,
    required this.correctGuessPercentage,
    required this.wrongGuessCount,
    required this.wrongGuessPercentage,
    required this.incorrect_correct,
    required this.correct_incorrect,
    required this.incorrect_incorres,
  });

  // Factory method for JSON deserialization
  factory McqAnalysis.fromJson(Map<String, dynamic> json) =>
      _$McqAnalysisFromJson(json);

  // Method for JSON serialization
  Map<String, dynamic> toJson() => _$McqAnalysisToJson(this);
}
