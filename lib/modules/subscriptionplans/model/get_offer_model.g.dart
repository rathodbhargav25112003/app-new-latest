// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_offer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAllOfferUserModel _$GetAllOfferUserModelFromJson(
        Map<String, dynamic> json) =>
    GetAllOfferUserModel(
      sId: json['_id'] as String?,
      discountPercentage: (json['discountPercentage'] as num?)?.toInt(),
      discountPrize: json['discountPrize'] as num?,
      isMultipleUse: json['isMultipleUse'] as bool?,
      isSingleUse: json['isSingleUse'] as bool?,
      description: json['description'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      id: (json['id'] as num?)?.toInt(),
      iV: (json['__v'] as num?)?.toInt(),
    );

Map<String, dynamic> _$GetAllOfferUserModelToJson(
        GetAllOfferUserModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'discountPrize': instance.discountPrize,
      'discountPercentage': instance.discountPercentage,
      'isSingleUse': instance.isSingleUse,
      'isMultipleUse': instance.isMultipleUse,
      'description': instance.description,
      'updated_at': instance.updated_at,
      'created_at': instance.created_at,
      'id': instance.id,
      '__v': instance.iV,
    };
