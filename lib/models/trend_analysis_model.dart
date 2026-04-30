import 'dart:convert';
import 'package:shusruta_lms/models/strength_model.dart';
// To parse this JSON data, do
//
//     final trendAnalysisModel = trendAnalysisModelFromJson(jsonString);

TrendAnalysisModel trendAnalysisModelFromJson(String str) =>
    TrendAnalysisModel.fromJson(json.decode(str));

String trendAnalysisModelToJson(TrendAnalysisModel data) =>
    json.encode(data.toJson());

class TrendAnalysisModel {
  String examName;
  int totalUser;
  int userRank;
  int userFirstRank;
  num mymark;
  int candidate;
  int question;
  String duration;
  bool isDeclaration;
  bool isNeetSS;
  bool isAttempt;
  String declarationTime;
  dynamic mark;
  int isAttemptcount;
  DateTime date;
  String percentage;
  int correctAnswers;
  int incorrectAnswers;
  int skippedAnswers;
  String correctAnswersPercentage;
  String incorrectAnswersPercentage;
  String skippedAnswersPercentage;
  int leftqusestion;
  String accuracyPercentage;
  int attemptquetion;
  String userExamId;
  String timeOnQuestion;
  String time;
  int remainingAttempts;
  int guessedAnswersCount;
  int correctGuessCount;
  String correctGuessPercentage;
  int wrongGuessCount;
  String wrongGuessPercentage;
  String predicted_rank_2024;
  int incorrectCorrect;
  int correctIncorrect;
  int incorrectIncorres;
  List<TopicWiseReport> topicWiseReport;
  List<TopThreeCorrect> topThreeCorrect;
  List<LastThreeIncorrect> lastThreeIncorrect;

  TrendAnalysisModel({
    required this.examName,
    required this.totalUser,
    required this.predicted_rank_2024,
    required this.userRank,
    required this.userFirstRank,
    required this.mymark,
    required this.candidate,
    required this.question,
    required this.isAttempt,
    required this.duration,
    required this.isNeetSS,
    required this.isDeclaration,
    required this.declarationTime,
    required this.mark,
    required this.isAttemptcount,
    required this.date,
    required this.percentage,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.skippedAnswers,
    required this.correctAnswersPercentage,
    required this.incorrectAnswersPercentage,
    required this.skippedAnswersPercentage,
    required this.leftqusestion,
    required this.accuracyPercentage,
    required this.attemptquetion,
    required this.userExamId,
    required this.timeOnQuestion,
    required this.time,
    required this.remainingAttempts,
    required this.guessedAnswersCount,
    required this.correctGuessCount,
    required this.correctGuessPercentage,
    required this.wrongGuessCount,
    required this.wrongGuessPercentage,
    required this.incorrectCorrect,
    required this.correctIncorrect,
    required this.incorrectIncorres,
    required this.topicWiseReport,
    required this.topThreeCorrect,
    required this.lastThreeIncorrect,
  });

  factory TrendAnalysisModel.fromJson(Map<String, dynamic> json) =>
      TrendAnalysisModel(
        examName: json["exam_name"],
        predicted_rank_2024: json["predicted_rank_2024"],
        totalUser: json["totalUser"],
        isAttempt: json["isAttempt"],
        userRank: json["userRank"],
        userFirstRank: json["userFirstRank"],
        mymark: json["mymark"],
        candidate: json["candidate"],
        question: json["Question"],
        duration: json["Duration"],
        isNeetSS: json["Neet_SS"],
        isDeclaration: json["isDeclaration"],
        declarationTime: json["declarationTime"],
        mark: json["mark"],
        isAttemptcount: json["isAttemptcount"],
        date: DateTime.parse(json["Date"]),
        percentage: json["percentage"],
        correctAnswers: json["correctAnswers"],
        incorrectAnswers: json["incorrectAnswers"],
        skippedAnswers: json["skippedAnswers"],
        correctAnswersPercentage: json["correctAnswersPercentage"],
        incorrectAnswersPercentage: json["incorrectAnswersPercentage"],
        skippedAnswersPercentage: json["skippedAnswersPercentage"],
        leftqusestion: json["leftqusestion"],
        accuracyPercentage: json["accuracyPercentage"],
        attemptquetion: json["Attemptquetion"],
        userExamId: json["userExamId"],
        timeOnQuestion: json["TimeOnQuestion"],
        time: json["Time"],
        remainingAttempts: json["remainingAttempts"],
        guessedAnswersCount: json["guessedAnswersCount"],
        correctGuessCount: json["correctGuessCount"],
        correctGuessPercentage: json["correctGuessPercentage"],
        wrongGuessCount: json["wrongGuessCount"],
        wrongGuessPercentage: json["wrongGuessPercentage"],
        incorrectCorrect: json["incorrect_correct"],
        correctIncorrect: json["correct_incorrect"],
        incorrectIncorres: json["incorrect_incorres"],
        topicWiseReport: List<TopicWiseReport>.from(
            json["topicWiseReport"].map((x) => TopicWiseReport.fromJson(x))),
        topThreeCorrect: List<TopThreeCorrect>.from(
            json["topThreeCorrect"].map((x) => TopThreeCorrect.fromJson(x))),
        lastThreeIncorrect: List<LastThreeIncorrect>.from(
            json["lastThreeIncorrect"]
                .map((x) => LastThreeIncorrect.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "exam_name": examName,
        "totalUser": totalUser,
        "userRank": userRank,
        "userFirstRank": userFirstRank,
        "mymark": mymark,
        "candidate": candidate,
        "Question": question,
        "Duration": duration,
        "isDeclaration": isDeclaration,
        "declarationTime": declarationTime,
        "mark": mark,
        "isAttemptcount": isAttemptcount,
        "Date": date.toIso8601String(),
        "percentage": percentage,
        "correctAnswers": correctAnswers,
        "incorrectAnswers": incorrectAnswers,
        "skippedAnswers": skippedAnswers,
        "correctAnswersPercentage": correctAnswersPercentage,
        "incorrectAnswersPercentage": incorrectAnswersPercentage,
        "skippedAnswersPercentage": skippedAnswersPercentage,
        "leftqusestion": leftqusestion,
        "accuracyPercentage": accuracyPercentage,
        "Attemptquetion": attemptquetion,
        "userExamId": userExamId,
        "TimeOnQuestion": timeOnQuestion,
        "Time": time,
        "remainingAttempts": remainingAttempts,
        "guessedAnswersCount": guessedAnswersCount,
        "correctGuessCount": correctGuessCount,
        "correctGuessPercentage": correctGuessPercentage,
        "wrongGuessCount": wrongGuessCount,
        "wrongGuessPercentage": wrongGuessPercentage,
        "incorrect_correct": incorrectCorrect,
        "correct_incorrect": correctIncorrect,
        "incorrect_incorres": incorrectIncorres,
        "topicWiseReport":
            List<dynamic>.from(topicWiseReport.map((x) => x.toJson())),
        "topThreeCorrect":
            List<dynamic>.from(topThreeCorrect.map((x) => x.toJson())),
        "lastThreeIncorrect":
            List<dynamic>.from(lastThreeIncorrect.map((x) => x.toJson())),
      };
}

class TopicWiseReport {
  String topicName;
  int correctAnswers;
  int incorrectAnswers;
  int totalQuestions;
  int skippedAnswers;
  String totalTime;

  TopicWiseReport({
    required this.topicName,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.totalQuestions,
    required this.totalTime,
    required this.skippedAnswers,
  });

  factory TopicWiseReport.fromJson(Map<String, dynamic> json) =>
      TopicWiseReport(
        topicName: json["topicName"],
        correctAnswers: json["correctAnswers"],
        incorrectAnswers: json["incorrectAnswers"],
        totalQuestions: json["totalQuestions"],
        skippedAnswers: json["skippedAnswers"],
        totalTime: json["totalTime"],
      );

  Map<String, dynamic> toJson() => {
        "topicName": topicName,
        "correctAnswers": correctAnswers,
        "incorrectAnswers": incorrectAnswers,
        "totalQuestions": totalQuestions,
        "totalTime": totalTime,
      };
}
