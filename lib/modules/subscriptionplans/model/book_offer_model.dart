import 'package:json_annotation/json_annotation.dart';

part 'book_offer_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BookOfferModel{
  BookOfferModel({
    this.id,
    this.discount,
    this.created_at,
    this.updated_at
  });

  factory BookOfferModel.fromJson(Map<String, dynamic> json) =>
      _$BookOfferModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  String? discount;
  String? created_at;
  String? updated_at;

  Map<String, dynamic> toJson() => _$BookOfferModelToJson(this);
}