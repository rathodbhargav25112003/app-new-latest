import 'package:json_annotation/json_annotation.dart';

part 'create_book_order_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateBookOrderModel{
  CreateBookOrderModel({
    this.deleted_at,
    this.userId,
    this.status,
    this.addressId,
    this.bookId,
    this.bookOrderId,
    this.prize,
    this.created_at,
    this.updated_at,
  });

  factory CreateBookOrderModel.fromJson(Map<String, dynamic> json) =>
      _$CreateBookOrderModelFromJson(json);

  dynamic deleted_at;
  @JsonKey(name: '_id')
  String? bookOrderId;
  int? prize;
  String? status;
  @JsonKey(name: 'Book_id')
  String? bookId;
  @JsonKey(name: 'Address_id')
  String? addressId;
  @JsonKey(name: 'user_id')
  String? userId;
  String? created_at;
  String? updated_at;

  Map<String, dynamic> toJson() => _$CreateBookOrderModelToJson(this);
}
