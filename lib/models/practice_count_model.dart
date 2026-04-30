import 'package:json_annotation/json_annotation.dart';

part 'practice_count_model.g.dart';

@JsonSerializable(explicitToJson: true)
class PracticeCountModel {
  int? attempted;
  int? correctAnswers;
  int? incorrectAnswers;
  @JsonKey(name: 'not_visited')
  int? notVisited;
  int? bookmarkCount;

  PracticeCountModel(
      {this.correctAnswers,
      this.incorrectAnswers,
      this.attempted,
      this.notVisited,
      this.bookmarkCount});

  factory PracticeCountModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeCountModelFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeCountModelToJson(this);
}
