import 'package:json_annotation/json_annotation.dart';

part 'strength_model.g.dart';

@JsonSerializable()
class ReportSrengthModel {
  List<TopThreeCorrect>? topThreeCorrect;
  List<LastThreeIncorrect>? lastThreeIncorrect;

  ReportSrengthModel({this.topThreeCorrect, this.lastThreeIncorrect});

  ReportSrengthModel.fromJson(Map<String, dynamic> json) {
    if (json['topThreeCorrect'] != null) {
      topThreeCorrect = <TopThreeCorrect>[];
      json['topThreeCorrect'].forEach((v) {
        topThreeCorrect!.add(TopThreeCorrect.fromJson(v));
      });
    }
    if (json['lastThreeIncorrect'] != null) {
      lastThreeIncorrect = <LastThreeIncorrect>[];
      json['lastThreeIncorrect'].forEach((v) {
        lastThreeIncorrect!.add(LastThreeIncorrect.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (topThreeCorrect != null) {
      data['topThreeCorrect'] =
          topThreeCorrect!.map((v) => v.toJson()).toList();
    }
    if (lastThreeIncorrect != null) {
      data['lastThreeIncorrect'] =
          lastThreeIncorrect!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

@JsonSerializable(explicitToJson: true)
class TopThreeCorrect {
  String? topicName;
  int? totalQuestions;
  int? correctAnswers;
  int? incorrectAnswers;
  String? correctAnswersPercentage;
  String? incorrectAnswersPercentage;

  TopThreeCorrect({
    this.topicName,
    this.totalQuestions,
    this.correctAnswers,
    this.incorrectAnswers,
    this.correctAnswersPercentage,
    this.incorrectAnswersPercentage,
  });

  factory TopThreeCorrect.fromJson(Map<String, dynamic> json) =>
      _$TopThreeCorrectFromJson(json);

  Map<String, dynamic> toJson() => _$TopThreeCorrectToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LastThreeIncorrect {
  String? topicName;
  int? totalQuestions;
  int? correctAnswers;
  int? incorrectAnswers;
  String? correctAnswersPercentage;
  String? incorrectAnswersPercentage;

  LastThreeIncorrect({
     this.topicName,
     this.totalQuestions,
     this.correctAnswers,
     this.incorrectAnswers,
     this.correctAnswersPercentage,
     this.incorrectAnswersPercentage,
  });

  factory LastThreeIncorrect.fromJson(Map<String, dynamic> json) =>
      _$LastThreeIncorrectFromJson(json);

  Map<String, dynamic> toJson() => _$LastThreeIncorrectToJson(this);
}
