// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionModel _$SubscriptionModelFromJson(Map<String, dynamic> json) =>
    SubscriptionModel(
      benifit:
          (json['benifit'] as List<dynamic>?)?.map((e) => e as String).toList(),
      deleted_at: json['deleted_at'],
      sid: json['_id'] as String?,
      plan_id: json['plan_id'] as String?,
      plan_name: json['plan_name'] as String?,
      duration: (json['duration'] as List<dynamic>?)
          ?.map((e) => Durations.fromJson(e as Map<String, dynamic>))
          .toList(),
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      id: (json['id'] as num?)?.toInt(),
      active_user: (json['active_user'] as num?)?.toInt(),
      description: json['description'] as String?,
      order: (json['order'] as num?)?.toInt(),
      pdf_topic_id: (json['pdf_topic_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      exam: json['exam'] as bool?,
      freetrail: json['freetrail'] as bool?,
      liveClass: json['liveClass'] as bool?,
      mockExam: json['mockExam'] as bool?,
      notes: json['notes'] as bool?,
      videos: json['videos'] as bool?,
      addFixedValidity: json['addFixedValidity'] as bool?,
      fixedValidityPlan: json['fixedValidityPlan'] == null
          ? null
          : FixedValidity.fromJson(
              json['fixedValidityPlan'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubscriptionModelToJson(SubscriptionModel instance) =>
    <String, dynamic>{
      'benifit': instance.benifit,
      'deleted_at': instance.deleted_at,
      '_id': instance.sid,
      'plan_id': instance.plan_id,
      'plan_name': instance.plan_name,
      'duration': instance.duration?.map((e) => e.toJson()).toList(),
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'id': instance.id,
      'active_user': instance.active_user,
      'description': instance.description,
      'order': instance.order,
      'pdf_topic_id': instance.pdf_topic_id,
      'liveClass': instance.liveClass,
      'exam': instance.exam,
      'mockExam': instance.mockExam,
      'videos': instance.videos,
      'notes': instance.notes,
      'freetrail': instance.freetrail,
      'addFixedValidity': instance.addFixedValidity,
      'fixedValidityPlan': instance.fixedValidityPlan?.toJson(),
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

FixedValidity _$FixedValidityFromJson(Map<String, dynamic> json) =>
    FixedValidity(
      text: json['text'] as String?,
      price: (json['price'] as num?)?.toInt(),
      toTime: json['totime'] as String?,
      offer: json['offer'] as String?,
    );

Map<String, dynamic> _$FixedValidityToJson(FixedValidity instance) =>
    <String, dynamic>{
      'text': instance.text,
      'price': instance.price,
      'totime': instance.toTime,
      'offer': instance.offer,
    };
