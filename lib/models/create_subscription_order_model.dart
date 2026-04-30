import 'package:json_annotation/json_annotation.dart';

part 'create_subscription_order_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateSubscriptionOrderModel{
  CreateSubscriptionOrderModel({
    this.deleted_at,
    this.subId,
    this.amount,
    this.razorpay_order_id,
    this.subscription_id,
    this.start_date,
    this.expiration_date,
    this.razorpay_payment_id,
    this.razorpay_signature,
    this.user_id,
    this.created_at,
    this.updated_at,
    this.id,
  });

  factory CreateSubscriptionOrderModel.fromJson(Map<String, dynamic> json) =>
      _$CreateSubscriptionOrderModelFromJson(json);

  dynamic deleted_at;
  @JsonKey(name: '_id')
  String? subId;
  int? amount;
  String? razorpay_order_id;
  String? subscription_id;
  String? start_date;
  String? expiration_date;
  String? razorpay_payment_id;
  String? razorpay_signature;
  String? user_id;
  String? created_at;
  String? updated_at;
  int? id;

  Map<String, dynamic> toJson() => _$CreateSubscriptionOrderModelToJson(this);
}
