// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method_details_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentMethodDetailsModel _$PaymentMethodDetailsModelFromJson(
        Map<String, dynamic> json) =>
    PaymentMethodDetailsModel(
      id: json['_id'] as String?,
      razorpayKey: json['razorpayKey'] as String?,
      razorpaySecretKey: json['razorpaySecretKey'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
    );

Map<String, dynamic> _$PaymentMethodDetailsModelToJson(
        PaymentMethodDetailsModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'razorpayKey': instance.razorpayKey,
      'razorpaySecretKey': instance.razorpaySecretKey,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
    };
