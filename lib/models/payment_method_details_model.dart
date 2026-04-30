import 'package:json_annotation/json_annotation.dart';

part 'payment_method_details_model.g.dart';

@JsonSerializable(explicitToJson: true)
class PaymentMethodDetailsModel{
  PaymentMethodDetailsModel({
    this.id,
    this.razorpayKey,
    this.razorpaySecretKey,
    this.created_at,
    this.updated_at,
  });

  factory PaymentMethodDetailsModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodDetailsModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  String? razorpayKey;
  String? razorpaySecretKey;
  String? created_at;
  String? updated_at;

  Map<String, dynamic> toJson() => _$PaymentMethodDetailsModelToJson(this);
}