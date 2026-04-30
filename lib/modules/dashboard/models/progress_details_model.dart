import 'package:json_annotation/json_annotation.dart';

part 'progress_details_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProgressDetailsModel{

  ProgressDetailsModel({
    this.isSubscribed,
    this.McqExamCount,
    this.McqAttemptExamCount,
    this.mcqQuestion,
    this.mcqAttemtQuestion,
    this.neetSsExamCount,
    this.neetSUserExamCount,
    this.inissETExamCount,
    this.innissETUserExamCount,
    this.videoCount,
    this.completedVideoCount,
    this.totalVideoDuration,
    this.completedVideoDuration,
    this.pdfCount,
    this.completedPdfCount,
  });

  factory ProgressDetailsModel.fromJson(Map<String, dynamic> json) => _$ProgressDetailsModelFromJson(json);

  bool? isSubscribed;
  int? McqExamCount;
  int? McqAttemptExamCount;
  int? mcqQuestion;
  int? mcqAttemtQuestion;
  @JsonKey(name: 'Neet_SSExamCount')
  int? neetSsExamCount;
  @JsonKey(name: 'Neet_SSUserExamCount')
  int? neetSUserExamCount;
  @JsonKey(name: 'INISS_ETExamCount')
  int? inissETExamCount;
  @JsonKey(name: 'INISS_ETUserExamCount')
  int? innissETUserExamCount;
  int? videoCount;
  int? completedVideoCount;
  int? totalVideoDuration;
  int? completedVideoDuration;
  int? pdfCount;
  int? completedPdfCount;

  Map<String, dynamic> toJson() => _$ProgressDetailsModelToJson(this);
}