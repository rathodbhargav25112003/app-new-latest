// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CouponResponseModel _$CouponResponseModelFromJson(Map<String, dynamic> json) =>
    CouponResponseModel(
      message: json['message'] as String?,
      coupon: json['coupon'] == null
          ? null
          : CouponModel.fromJson(json['coupon'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CouponResponseModelToJson(
        CouponResponseModel instance) =>
    <String, dynamic>{
      'message': instance.message,
      'coupon': instance.coupon?.toJson(),
    };

CouponModel _$CouponModelFromJson(Map<String, dynamic> json) => CouponModel(
      subscriptionId: (json['subscription_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      planId:
          (json['plan_id'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isSingleUse: json['isSingleUse'] as bool?,
      isMultipleUse: json['isMultipleUse'] as bool?,
      isActive: json['isActive'] as bool?,
      isFixPrice: json['isFixPrice'] as bool?,
      isPercentage: json['isPercentage'] as bool?,
      id: json['_id'] as String?,
      code: json['code'] as String?,
      discountPrize: (json['discountPrize'] as num?)?.toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      fromDate: json['fromDate'] == null
          ? null
          : DateTime.parse(json['fromDate'] as String),
      toDate: json['toDate'] == null
          ? null
          : DateTime.parse(json['toDate'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      numericId: (json['numericId'] as num?)?.toInt(),
      version: (json['__v'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CouponModelToJson(CouponModel instance) =>
    <String, dynamic>{
      'subscription_id': instance.subscriptionId,
      'plan_id': instance.planId,
      'isSingleUse': instance.isSingleUse,
      'isMultipleUse': instance.isMultipleUse,
      'isActive': instance.isActive,
      'isFixPrice': instance.isFixPrice,
      'isPercentage': instance.isPercentage,
      '_id': instance.id,
      'code': instance.code,
      'discountPrize': instance.discountPrize,
      'discountPercentage': instance.discountPercentage,
      'fromDate': instance.fromDate?.toIso8601String(),
      'toDate': instance.toDate?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'numericId': instance.numericId,
      '__v': instance.version,
    };
