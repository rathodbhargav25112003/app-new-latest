// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_book_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateBookOrderModel _$CreateBookOrderModelFromJson(
        Map<String, dynamic> json) =>
    CreateBookOrderModel(
      deleted_at: json['deleted_at'],
      userId: json['user_id'] as String?,
      status: json['status'] as String?,
      addressId: json['Address_id'] as String?,
      bookId: json['Book_id'] as String?,
      bookOrderId: json['_id'] as String?,
      prize: (json['prize'] as num?)?.toInt(),
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
    );

Map<String, dynamic> _$CreateBookOrderModelToJson(
        CreateBookOrderModel instance) =>
    <String, dynamic>{
      'deleted_at': instance.deleted_at,
      '_id': instance.bookOrderId,
      'prize': instance.prize,
      'status': instance.status,
      'Book_id': instance.bookId,
      'Address_id': instance.addressId,
      'user_id': instance.userId,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
    };
