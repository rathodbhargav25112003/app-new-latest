// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_user_details_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetUserDetailsModel _$GetUserDetailsModelFromJson(Map<String, dynamic> json) =>
    GetUserDetailsModel(
      resetPasswordOtp: json['resetPasswordOtp'] as String?,
      exams:
          (json['exams'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isSignInGoogle: json['isSignInGoogle'] as bool?,
      isActive: json['isActive'] as bool?,
      Image: json['Image'] as String?,
      id: json['_id'] as String?,
      currentData: json['current_data'] as String?,
      fullname: json['fullname'] as String?,
      username: json['username'] as String?,
      preparingFor: json['preparing_for'] as String?,
      standerdFor: json['standerd_for'] as String?,
      standerd_id: json['standerd_id'] as String?,
      preparing_id: json['preparing_id'] as String?,
      state: json['state'] as String?,
      email: json['email'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      phone: json['phone'] as String?,
      created_at: json['created_at'] as String?,
      sid: json['sid'] as String?,
      err: json['err'] == null
          ? null
          : ErrorModel.fromJson(json['err'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetUserDetailsModelToJson(
        GetUserDetailsModel instance) =>
    <String, dynamic>{
      'resetPasswordOtp': instance.resetPasswordOtp,
      'exams': instance.exams,
      'isSignInGoogle': instance.isSignInGoogle,
      'isActive': instance.isActive,
      'Image': instance.Image,
      '_id': instance.id,
      'current_data': instance.currentData,
      'fullname': instance.fullname,
      'username': instance.username,
      'preparing_for': instance.preparingFor,
      'standerd_for': instance.standerdFor,
      'standerd_id': instance.standerd_id,
      'preparing_id': instance.preparing_id,
      'state': instance.state,
      'email': instance.email,
      'date_of_birth': instance.dateOfBirth,
      'phone': instance.phone,
      'created_at': instance.created_at,
      'sid': instance.sid,
      'err': instance.err?.toJson(),
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
