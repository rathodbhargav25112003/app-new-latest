// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pincode_address_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PincodeAddressModel _$PincodeAddressModelFromJson(Map<String, dynamic> json) =>
    PincodeAddressModel(
      buildingNumber: json['buildingNumber'] as String?,
      landMark: json['LandMark'] as String?,
      city: json['City'] as String?,
      state: json['State'] as String?,
      name: json['name'] as String?,
      address: json['address'] as String?,
      email: json['email'] as String?,
      deletedAt: json['deleted_at'] as String?,
      id: json['_id'] as String?,
      pincode: (json['Pincode'] as num?)?.toInt(),
      phone: (json['phone'] as num?)?.toInt(),
      userId: json['user_id'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      v: (json['__v'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PincodeAddressModelToJson(
        PincodeAddressModel instance) =>
    <String, dynamic>{
      'buildingNumber': instance.buildingNumber,
      'LandMark': instance.landMark,
      'City': instance.city,
      'State': instance.state,
      'name': instance.name,
      'address': instance.address,
      'email': instance.email,
      'deleted_at': instance.deletedAt,
      '_id': instance.id,
      'Pincode': instance.pincode,
      'phone': instance.phone,
      'user_id': instance.userId,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      '__v': instance.v,
    };
