import 'package:json_annotation/json_annotation.dart';

part 'merit_list_model.g.dart';

@JsonSerializable(explicitToJson: true)
class MeritListModel {
  MeritListModel({
    this.examId,
    this.fullName,
    this.score,
    this.rank,
    this.correct,
    this.inCorrect,
    this.isMyRank,
    this.skipped,
  });

  factory MeritListModel.fromJson(Map<String, dynamic> json) => _$MeritListModelFromJson(json);

  @JsonKey(name: 'exam_id')
  String? examId;
  @JsonKey(name: 'fullname')
  String? fullName;
  double? score;
  int? rank;
  int? inCorrect;
  int? skipped;
  int? correct;
  bool? isMyRank;

  Map<String, dynamic> toJson() => _$MeritListModelToJson(this);
}
