import 'package:json_annotation/json_annotation.dart';

part 'create_user_offer_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateUserOfferModel{
  CreateUserOfferModel({
    this.amount,
    this.user_id,
    this.created_at,
    this.updated_at,
    this.id,
  });

  factory CreateUserOfferModel.fromJson(Map<String, dynamic> json) =>
      _$CreateUserOfferModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  int? amount;
  String? user_id;
  String? offer_id;
  String? created_at;
  String? updated_at;
  int? id;

  Map<String, dynamic> toJson() => _$CreateUserOfferModelToJson(this);
}
