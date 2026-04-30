import 'package:json_annotation/json_annotation.dart';

part 'get_all_coupon_user_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetAllCouponUserModel {
  GetAllCouponUserModel({
    this.sId,
    this.subcategory_id,
    this.created_at,
    this.updated_at,
    this.id,
    this.iV,
    this.isActive,
    this.code,
    this.discountPrize
  });

  factory GetAllCouponUserModel.fromJson(Map<String, dynamic> json) => _$GetAllCouponUserModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
    String? subcategory_id;
  String? created_at;
  String? code;
  int? discountPrize;
  bool? isActive;
  String? updated_at;
  int? id;
  @JsonKey(name: '__v')
  int? iV;

  Map<String, dynamic> toJson() => _$GetAllCouponUserModelToJson(this);
}