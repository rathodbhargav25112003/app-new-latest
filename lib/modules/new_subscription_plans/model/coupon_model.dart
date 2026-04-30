import 'package:json_annotation/json_annotation.dart';

part 'coupon_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CouponResponseModel {
  CouponResponseModel({
    this.message,
    this.coupon,
  });

  factory CouponResponseModel.fromJson(Map<String, dynamic> json) => 
      _$CouponResponseModelFromJson(json);

  final String? message;
  final CouponModel? coupon;

  Map<String, dynamic> toJson() => _$CouponResponseModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CouponModel {
  CouponModel({
    this.subscriptionId,
    this.planId,
    this.isSingleUse,
    this.isMultipleUse,
    this.isActive,
    this.isFixPrice,
    this.isPercentage,
    this.id,
    this.code,
    this.discountPrize,
    this.discountPercentage,
    this.fromDate,
    this.toDate,
    this.createdAt,
    this.updatedAt,
    this.numericId,
    this.version,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) => 
      _$CouponModelFromJson(json);

  @JsonKey(name: 'subscription_id')
  final List<String>? subscriptionId;
  
  @JsonKey(name: 'plan_id')
  final List<String>? planId;
  
  final bool? isSingleUse;
  final bool? isMultipleUse;
  final bool? isActive;
  final bool? isFixPrice;
  final bool? isPercentage;
  
  @JsonKey(name: '_id')
  final String? id;
  
  final String? code;
  final double? discountPrize;
  final double? discountPercentage;
  final DateTime? fromDate;
  final DateTime? toDate;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  
  final int? numericId;
  
  @JsonKey(name: '__v')
  final int? version;

  Map<String, dynamic> toJson() => _$CouponModelToJson(this);
} 