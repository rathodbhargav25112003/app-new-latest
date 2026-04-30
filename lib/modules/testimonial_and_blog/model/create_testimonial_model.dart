import 'package:json_annotation/json_annotation.dart';

part 'create_testimonial_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateTestimonialModel{
  CreateTestimonialModel({
    this.id,
    this.rating,
    this.sId,
    this.description,
    this.name
  });

  factory CreateTestimonialModel.fromJson(Map<String, dynamic> json) => _$CreateTestimonialModelFromJson(json);

  int? rating;
  @JsonKey(name: '_id')
  String? sId;
  String? name;
  String? description;
  int? id;

  Map<String, dynamic> toJson() => _$CreateTestimonialModelToJson(this);
}
