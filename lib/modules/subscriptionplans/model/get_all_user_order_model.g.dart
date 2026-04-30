// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_all_user_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAllUserOrderModel _$GetAllUserOrderModelFromJson(
        Map<String, dynamic> json) =>
    GetAllUserOrderModel(
      created_at: json['created_at'] as String?,
      status: json['status'] as String?,
      price: (json['Price'] as num?)?.toInt(),
      volume: (json['volume'] as num?)?.toInt(),
      bookType: json['bookType'] as String?,
      bookName: json['bookName'] as String?,
      bookImg: json['bookImg'] as String?,
      state: json['State'] as String?,
      city: json['City'] as String?,
      landMark: json['LandMark'] as String?,
      buildingNumber: json['buildingNumber'] as String?,
      deliverDate: json['deliverDate'] as String?,
      pinCode: (json['Pincode'] as num?)?.toInt(),
    );

Map<String, dynamic> _$GetAllUserOrderModelToJson(
        GetAllUserOrderModel instance) =>
    <String, dynamic>{
      'created_at': instance.created_at,
      'deliverDate': instance.deliverDate,
      'status': instance.status,
      'bookName': instance.bookName,
      'bookType': instance.bookType,
      'bookImg': instance.bookImg,
      'volume': instance.volume,
      'buildingNumber': instance.buildingNumber,
      'LandMark': instance.landMark,
      'City': instance.city,
      'State': instance.state,
      'Pincode': instance.pinCode,
      'Price': instance.price,
    };
