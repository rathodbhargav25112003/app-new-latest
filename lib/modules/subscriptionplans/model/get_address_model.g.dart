// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_address_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAddressModel _$GetAddressModelFromJson(Map<String, dynamic> json) =>
    GetAddressModel(
      id: (json['id'] as num?)?.toInt(),
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      sId: json['_id'] as String?,
      iV: (json['__v'] as num?)?.toInt(),
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: (json['phone'] as num?)?.toInt(),
      buildingNumber: json['buildingNumber'] as String?,
      city: json['City'] as String?,
      landMark: json['LandMark'] as String?,
      pincode: (json['Pincode'] as num?)?.toInt(),
      state: json['State'] as String?,
      user_id: json['user_id'] as String?,
    );

Map<String, dynamic> _$GetAddressModelToJson(GetAddressModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      '_id': instance.sId,
      '__v': instance.iV,
      'buildingNumber': instance.buildingNumber,
      'LandMark': instance.landMark,
      'City': instance.city,
      'State': instance.state,
      'email': instance.email,
      'name': instance.name,
      'Pincode': instance.pincode,
      'phone': instance.phone,
      'user_id': instance.user_id,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
    };
