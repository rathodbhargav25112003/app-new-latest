// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zoom_meeting_live_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ZoomLiveModel _$ZoomLiveModelFromJson(Map<String, dynamic> json) =>
    ZoomLiveModel(
      status: json['status'] as String?,
      join_url: json['join_url'] as String?,
      password: json['password'] as String?,
      topic: json['topic'] as String?,
      meeting_id: json['meeting_id'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      start_time: json['start_time'] as String?,
      description: json['description'] as String?,
      pdf_url: json['pdf_url'] as String?,
      mobileAppUrl: json['mobileAppUrl'] as String?,
    );

Map<String, dynamic> _$ZoomLiveModelToJson(ZoomLiveModel instance) =>
    <String, dynamic>{
      'status': instance.status,
      'join_url': instance.join_url,
      'password': instance.password,
      'topic': instance.topic,
      'meeting_id': instance.meeting_id,
      'start_time': instance.start_time,
      'description': instance.description,
      'pdf_url': instance.pdf_url,
      'mobileAppUrl': instance.mobileAppUrl,
      'duration': instance.duration,
    };
