// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_subscription_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateSubscriptionOrderModel _$CreateSubscriptionOrderModelFromJson(
        Map<String, dynamic> json) =>
    CreateSubscriptionOrderModel(
      deleted_at: json['deleted_at'],
      subId: json['_id'] as String?,
      amount: (json['amount'] as num?)?.toInt(),
      razorpay_order_id: json['razorpay_order_id'] as String?,
      subscription_id: json['subscription_id'] as String?,
      start_date: json['start_date'] as String?,
      expiration_date: json['expiration_date'] as String?,
      razorpay_payment_id: json['razorpay_payment_id'] as String?,
      razorpay_signature: json['razorpay_signature'] as String?,
      user_id: json['user_id'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      id: (json['id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CreateSubscriptionOrderModelToJson(
        CreateSubscriptionOrderModel instance) =>
    <String, dynamic>{
      'deleted_at': instance.deleted_at,
      '_id': instance.subId,
      'amount': instance.amount,
      'razorpay_order_id': instance.razorpay_order_id,
      'subscription_id': instance.subscription_id,
      'start_date': instance.start_date,
      'expiration_date': instance.expiration_date,
      'razorpay_payment_id': instance.razorpay_payment_id,
      'razorpay_signature': instance.razorpay_signature,
      'user_id': instance.user_id,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'id': instance.id,
    };
