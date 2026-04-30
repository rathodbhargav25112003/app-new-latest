// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_offer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookOfferModel _$BookOfferModelFromJson(Map<String, dynamic> json) =>
    BookOfferModel(
      id: json['_id'] as String?,
      discount: json['discount'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
    );

Map<String, dynamic> _$BookOfferModelToJson(BookOfferModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'discount': instance.discount,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
    };
