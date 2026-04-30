// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_offers_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetOffersModel _$GetOffersModelFromJson(Map<String, dynamic> json) =>
    GetOffersModel(
      upperbanner: (json['upperbanner'] as List<dynamic>?)
          ?.map((e) => UpperBanner.fromJson(e as Map<String, dynamic>))
          .toList(),
      lowerbanner: (json['lowerbanner'] as List<dynamic>?)
          ?.map((e) => LowerBanner.fromJson(e as Map<String, dynamic>))
          .toList(),
      id: json['_id'] as String?,
      offer: json['offer'] as String?,
      offerUrl: json['offerUrl'] as String?,
      created_at: json['created_at'] as String?,
      err: json['err'] == null
          ? null
          : ErrorModel.fromJson(json['err'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetOffersModelToJson(GetOffersModel instance) =>
    <String, dynamic>{
      'upperbanner': instance.upperbanner?.map((e) => e.toJson()).toList(),
      'lowerbanner': instance.lowerbanner?.map((e) => e.toJson()).toList(),
      '_id': instance.id,
      'offer': instance.offer,
      'offerUrl': instance.offerUrl,
      'created_at': instance.created_at,
      'err': instance.err?.toJson(),
    };

UpperBanner _$UpperBannerFromJson(Map<String, dynamic> json) => UpperBanner(
      upperbanner_url: json['upperbanner_url'] as String?,
      upperbanner_img: json['upperbanner_img'] as String?,
      uid: json['_id'] as String?,
    );

Map<String, dynamic> _$UpperBannerToJson(UpperBanner instance) =>
    <String, dynamic>{
      'upperbanner_url': instance.upperbanner_url,
      'upperbanner_img': instance.upperbanner_img,
      '_id': instance.uid,
    };

LowerBanner _$LowerBannerFromJson(Map<String, dynamic> json) => LowerBanner(
      lowerbanner_url: json['lowerbanner_url'] as String?,
      lowerbanner_img: json['lowerbanner_img'] as String?,
      lid: json['_id'] as String?,
    );

Map<String, dynamic> _$LowerBannerToJson(LowerBanner instance) =>
    <String, dynamic>{
      'lowerbanner_url': instance.lowerbanner_url,
      'lowerbanner_img': instance.lowerbanner_img,
      '_id': instance.lid,
    };

ErrorModel _$ErrorModelFromJson(Map<String, dynamic> json) => ErrorModel(
      code: json['code'],
      message: json['message'] as String?,
      params: json['params'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ErrorModelToJson(ErrorModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'params': instance.params,
    };
