import 'package:json_annotation/json_annotation.dart';

part 'get_all_testimonial_list_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetTestimonialListModel{
  GetTestimonialListModel({
    this.id,
    this.rating,
    this.sId,
    this.description,
    this.name
  });

  factory GetTestimonialListModel.fromJson(Map<String, dynamic> json) => _$GetTestimonialListModelFromJson(json);

  int? rating;
  @JsonKey(name: '_id')
  String? sId;
  String? name;
  String? description;
  int? id;

  Map<String, dynamic> toJson() => _$GetTestimonialListModelToJson(this);
}
