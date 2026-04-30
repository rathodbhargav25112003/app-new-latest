// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ordered_book_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderedBookModel _$OrderedBookModelFromJson(Map<String, dynamic> json) =>
    OrderedBookModel(
      id: json['id'] as String?,
      bookName: json['bookName'] as String?,
      description: json['description'] as String?,
      bookType: json['bookType'] as String?,
      price: (json['price'] as num?)?.toInt(),
      discountPrice: (json['discountPrice'] as num?)?.toInt(),
      deliveryCharge: (json['deliveryCharge'] as num?)?.toInt(),
      quantity: (json['quantity'] as num?)?.toInt(),
      orderId: json['orderId'] as String?,
    );

Map<String, dynamic> _$OrderedBookModelToJson(OrderedBookModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookName': instance.bookName,
      'description': instance.description,
      'bookType': instance.bookType,
      'price': instance.price,
      'discountPrice': instance.discountPrice,
      'deliveryCharge': instance.deliveryCharge,
      'quantity': instance.quantity,
      'orderId': instance.orderId,
    };
