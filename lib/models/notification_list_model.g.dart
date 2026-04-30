// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationListModel _$NotificationListModelFromJson(
        Map<String, dynamic> json) =>
    NotificationListModel(
      id: json['_id'] as String?,
      notificationType: json['notification_type'] as String?,
      notification: json['notification'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$NotificationListModelToJson(
        NotificationListModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'notification_type': instance.notificationType,
      'notification': instance.notification,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'title': instance.title,
    };
