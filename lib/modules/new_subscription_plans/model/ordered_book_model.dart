import 'package:json_annotation/json_annotation.dart';

part 'ordered_book_model.g.dart';

@JsonSerializable()
class OrderedBookModel {
  @JsonKey(name: 'id')
  final String? id;
  
  @JsonKey(name: 'bookName')
  final String? bookName;
  
  @JsonKey(name: 'description')
  final String? description;
  
  @JsonKey(name: 'bookType')
  final String? bookType;
  
  @JsonKey(name: 'price')
  final int? price;
  
  @JsonKey(name: 'discountPrice')
  final int? discountPrice;
  
  @JsonKey(name: 'deliveryCharge')
  final int? deliveryCharge;
  
  @JsonKey(name: 'quantity')
  final int? quantity;
  
  @JsonKey(name: 'orderId')
  final String? orderId;

  OrderedBookModel({
    this.id,
    this.bookName,
    this.description,
    this.bookType,
    this.price,
    this.discountPrice,
    this.deliveryCharge,
    this.quantity,
    this.orderId,
  });

  factory OrderedBookModel.fromJson(Map<String, dynamic> json) => _$OrderedBookModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderedBookModelToJson(this);
} 