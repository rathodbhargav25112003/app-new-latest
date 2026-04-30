import 'package:json_annotation/json_annotation.dart';

part 'get_all_user_order_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetAllUserOrderModel{
  GetAllUserOrderModel({
    this.created_at,
    this.status,
    this.price,
    this.volume,
    this.bookType,
    this.bookName,
    this.bookImg,
    this.state,
    this.city,
    this.landMark,
    this.buildingNumber,
    this.deliverDate,
    this.pinCode
  });

  factory GetAllUserOrderModel.fromJson(Map<String, dynamic> json) =>
      _$GetAllUserOrderModelFromJson(json);

  String? created_at;
  String? deliverDate;
  String? status;
  String? bookName;
  String? bookType;
  String? bookImg;
  int? volume;
  String? buildingNumber;
  @JsonKey(name: 'LandMark')
  String? landMark;
  @JsonKey(name: 'City')
  String? city;
  @JsonKey(name: 'State')
  String? state;
  @JsonKey(name: 'Pincode')
  int? pinCode;
  @JsonKey(name: 'Price')
  int? price;


  Map<String, dynamic> toJson() => _$GetAllUserOrderModelToJson(this);
}