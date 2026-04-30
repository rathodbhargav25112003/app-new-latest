import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'user_score.g.dart';

@JsonSerializable()
class UserScore {
  final int score;
  final String time;
  final int rank;
  final String fullname;
  final int totalMarks;
  final int correct;
  @JsonKey(name: 'inCorrect')
  final int inCorrect;
  final int skipped;
  final int isAttemptcount;
  final bool isMyRank;

  UserScore({
    required this.score,
    required this.time,
    required this.rank,
    required this.fullname,
    this.isAttemptcount = 1,
    required this.correct,
    required this.totalMarks,
    required this.inCorrect,
    required this.skipped,
    required this.isMyRank,
  });

  /// Factory constructor for creating a new `UserScore` instance from a map
  factory UserScore.fromJson(Map<String, dynamic> json) =>
      _$UserScoreFromJson(json);

  /// Method for serializing the `UserScore` instance to a map
  Map<String, dynamic> toJson() => _$UserScoreToJson(this);
}

List<UserScore> parseUserScores(List<dynamic> parsed) {
  return parsed.map((json) => UserScore.fromJson(json)).toList();
}
