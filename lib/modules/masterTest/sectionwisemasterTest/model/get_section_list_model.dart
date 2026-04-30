import 'package:json_annotation/json_annotation.dart';

part 'get_section_list_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetSectionListModel {
  GetSectionListModel({
    this.sectionId,
    this.isCompleteSection,
    this.section,
    this.numberOfQuestions,
    this.timeDuration,
    this.status,
    this.isLocked,
    this.attempted = 0,
    this.skipped = 0,
    this.markedforreview = 0,
    this.attemptedandmarkedforreview = 0,
    this.guess = 0,
  });

  factory GetSectionListModel.fromJson(Map<String, dynamic> json) =>
      _$GetSectionListModelFromJson(json);

  @JsonKey(name: "section_id")
  String? sectionId;
  bool? isCompleteSection;
  @JsonKey(name: 'time_duration')
  String? timeDuration;
  bool? isLocked;
  String? status;
  String? section;
  @JsonKey(name: 'NumberOfQuestions')
  int? numberOfQuestions;
  @JsonKey(name: 'attempted')
  int? attempted;
  @JsonKey(name: 'skipped')
  int? skipped;
  @JsonKey(name: 'marked_for_review')
  int? markedforreview;
  @JsonKey(name: 'attempted_marked_for_review')
  int? attemptedandmarkedforreview;
  @JsonKey(name: 'guess')
  int? guess;
  @JsonKey(name: 'not_visited')
  int? notVisited;

  Map<String, dynamic> toJson() => _$GetSectionListModelToJson(this);
}
