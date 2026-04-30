import 'package:json_annotation/json_annotation.dart';

part 'get_explanation_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetExplanationModel {
  GetExplanationModel({
    this.text,
  });

  factory GetExplanationModel.fromJson(Map<String, dynamic> json) => _$GetExplanationModelFromJson(json);

  String? text;

  Map<String, dynamic> toJson() => _$GetExplanationModelToJson(this);
}