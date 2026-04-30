import 'package:json_annotation/json_annotation.dart';

part 'create_section_exam_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateSectionExamModel {
  CreateSectionExamModel({
    this.id,
    this.userExamId,
    this.section,
    this.created_at,
    this.updated_at,
    this.err
  });

  factory CreateSectionExamModel.fromJson(Map<String, dynamic> json) => _$CreateSectionExamModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'userExam_id')
  String? userExamId;
  String? created_at;
  String? updated_at;
  List<Section>? section;
  errMsg? err;

  Map<String, dynamic> toJson() => _$CreateSectionExamModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Section {
  Section({
    this.id,
    this.sectionId,
    this.status,
  });

  factory Section.fromJson(Map<String, dynamic> json) => _$SectionFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'section_id')
  String? sectionId;
  String? status;

  Map<String, dynamic> toJson() => _$SectionToJson(this);
}


@JsonSerializable(explicitToJson: true)
class errMsg {
  errMsg({
    this.message,
  });

  factory errMsg.fromJson(Map<String, dynamic> json) =>
      _$errMsgFromJson(json);

  String? message;

  Map<String, dynamic> toJson() => _$errMsgToJson(this);
}
