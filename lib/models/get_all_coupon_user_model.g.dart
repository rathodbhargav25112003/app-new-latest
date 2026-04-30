// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_all_coupon_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAllCouponUserModel _$GetAllCouponUserModelFromJson(
        Map<String, dynamic> json) =>
    GetAllCouponUserModel(
      sId: json['_id'] as String?,
      subcategory_id: json['subcategory_id'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      id: (json['id'] as num?)?.toInt(),
      iV: (json['__v'] as num?)?.toInt(),
      isActive: json['isActive'] as bool?,
      code: json['code'] as String?,
      discountPrize: (json['discountPrize'] as num?)?.toInt(),
    );

Map<String, dynamic> _$GetAllCouponUserModelToJson(
        GetAllCouponUserModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'subcategory_id': instance.subcategory_id,
      'created_at': instance.created_at,
      'code': instance.code,
      'discountPrize': instance.discountPrize,
      'isActive': instance.isActive,
      'updated_at': instance.updated_at,
      'id': instance.id,
      '__v': instance.iV,
    };
