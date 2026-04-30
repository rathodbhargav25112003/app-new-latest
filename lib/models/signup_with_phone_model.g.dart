// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_with_phone_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignupWithPhoneModel _$SignupWithPhoneModelFromJson(
        Map<String, dynamic> json) =>
    SignupWithPhoneModel(
      created: json['created'] as bool?,
      err: json['err'] == null
          ? null
          : ErrorModel.fromJson(json['err'] as Map<String, dynamic>),
      data: json['data'] == null
          ? null
          : UserDataModel.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SignupWithPhoneModelToJson(
        SignupWithPhoneModel instance) =>
    <String, dynamic>{
      'created': instance.created,
      'err': instance.err?.toJson(),
      'data': instance.data?.toJson(),
    };

UserDataModel _$UserDataModelFromJson(Map<String, dynamic> json) =>
    UserDataModel(
      user: json['user'] == null
          ? null
          : UsersModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String?,
    );

Map<String, dynamic> _$UserDataModelToJson(UserDataModel instance) =>
    <String, dynamic>{
      'user': instance.user?.toJson(),
      'token': instance.token,
    };

UsersModel _$UsersModelFromJson(Map<String, dynamic> json) => UsersModel(
      resetPasswordOtp: json['resetPasswordOtp'] as String?,
      exams:
          (json['exams'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isActive: json['isActive'] as bool?,
      Image: json['Image'] as String?,
      id: json['_id'] as String?,
      currentData: json['current_data'] as String?,
      fullname: json['fullname'] as String?,
      username: json['username'] as String?,
      preparing_for: json['preparing_for'] as String?,
      email: json['email'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      phone: json['phone'] as String?,
      created_at: json['created_at'] as String?,
    );

Map<String, dynamic> _$UsersModelToJson(UsersModel instance) =>
    <String, dynamic>{
      'resetPasswordOtp': instance.resetPasswordOtp,
      'exams': instance.exams,
      'isActive': instance.isActive,
      'Image': instance.Image,
      '_id': instance.id,
      'current_data': instance.currentData,
      'fullname': instance.fullname,
      'username': instance.username,
      'preparing_for': instance.preparing_for,
      'email': instance.email,
      'date_of_birth': instance.dateOfBirth,
      'phone': instance.phone,
      'created_at': instance.created_at,
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
