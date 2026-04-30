import 'package:json_annotation/json_annotation.dart';

part 'get_offer_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetAllOfferUserModel {
  GetAllOfferUserModel({
    this.sId,
    this.discountPercentage,
    this.discountPrize,
    this.isMultipleUse,
    this.isSingleUse,
    this.description,
    this.created_at,
    this.updated_at,
    this.id,
    this.iV,
  });

  factory GetAllOfferUserModel.fromJson(Map<String, dynamic> json) => _$GetAllOfferUserModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  num? discountPrize;
  int? discountPercentage;
  bool? isSingleUse;
  bool? isMultipleUse;
  String? description;
  String? updated_at;
  String? created_at;
  int? id;
  @JsonKey(name: '__v')
  int? iV;

  Map<String, dynamic> toJson() => _$GetAllOfferUserModelToJson(this);
}