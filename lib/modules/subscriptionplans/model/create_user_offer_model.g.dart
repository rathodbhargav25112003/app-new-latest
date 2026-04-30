// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_user_offer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateUserOfferModel _$CreateUserOfferModelFromJson(
        Map<String, dynamic> json) =>
    CreateUserOfferModel(
      amount: (json['amount'] as num?)?.toInt(),
      user_id: json['user_id'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      id: (json['id'] as num?)?.toInt(),
    )
      ..sId = json['_id'] as String?
      ..offer_id = json['offer_id'] as String?;

Map<String, dynamic> _$CreateUserOfferModelToJson(
        CreateUserOfferModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'amount': instance.amount,
      'user_id': instance.user_id,
      'offer_id': instance.offer_id,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'id': instance.id,
    };
