// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscribed_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscribedPlanModel _$SubscribedPlanModelFromJson(Map<String, dynamic> json) =>
    SubscribedPlanModel(
      benifit:
          (json['benifit'] as List<dynamic>?)?.map((e) => e as String).toList(),
      deleted_at: json['deleted_at'] as String?,
      subscription_id: json['subscription_id'] as String?,
      plan_id: json['_id'] as String?,
      order_id: json['order_id'] as String?,
      plan_name: json['plan_name'] as String?,
      buyDuration: json['buyDuration'] == null
          ? null
          : Durations.fromJson(json['buyDuration'] as Map<String, dynamic>),
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      expirationDate: json['expiration_date'] as String?,
      description: json['description'] as String?,
      pdf_topic_id: (json['pdf_topic_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      amount: json['amount'] as num?,
      isPreviousPlan: json['isPrevious'] as bool?,
    )
      ..id = (json['id'] as num?)?.toInt()
      ..active_user = (json['active_user'] as num?)?.toInt()
      ..isVideosAccess = json['is_videos'] as bool?
      ..isNotesAccess = json['is_notes'] as bool?
      ..isExamsAccess = json['is_exams'] as bool?;

Map<String, dynamic> _$SubscribedPlanModelToJson(
        SubscribedPlanModel instance) =>
    <String, dynamic>{
      'benifit': instance.benifit,
      'deleted_at': instance.deleted_at,
      'subscription_id': instance.subscription_id,
      '_id': instance.plan_id,
      'order_id': instance.order_id,
      'plan_name': instance.plan_name,
      'buyDuration': instance.buyDuration?.toJson(),
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'id': instance.id,
      'amount': instance.amount,
      'active_user': instance.active_user,
      'expiration_date': instance.expirationDate,
      'description': instance.description,
      'is_videos': instance.isVideosAccess,
      'is_notes': instance.isNotesAccess,
      'is_exams': instance.isExamsAccess,
      'pdf_topic_id': instance.pdf_topic_id,
      'isPrevious': instance.isPreviousPlan,
    };

Durations _$DurationsFromJson(Map<String, dynamic> json) => Durations(
      durationId: json['_id'] as String?,
      price: (json['price'] as num?)?.toInt(),
      day: json['day'] as String?,
      offer: json['offer'] as String?,
    );

Map<String, dynamic> _$DurationsToJson(Durations instance) => <String, dynamic>{
      '_id': instance.durationId,
      'price': instance.price,
      'day': instance.day,
      'offer': instance.offer,
    };
