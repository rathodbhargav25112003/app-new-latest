import 'package:json_annotation/json_annotation.dart';

part 'pincode_address_model.g.dart';

@JsonSerializable(explicitToJson: true)
class PincodeAddressModel {
  PincodeAddressModel({
    this.buildingNumber,
    this.landMark,
    this.city,
    this.state,
    this.name,
    this.address,
    this.email,
    this.deletedAt,
    this.id,
    this.pincode,
    this.phone,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory PincodeAddressModel.fromJson(Map<String, dynamic> json) => _$PincodeAddressModelFromJson(json);

  String? buildingNumber;
  @JsonKey(name: 'LandMark')
  String? landMark;
  @JsonKey(name: 'City')
  String? city;
  @JsonKey(name: 'State')
  String? state;
  String? name;
  String? address;
  String? email;
  @JsonKey(name: 'deleted_at')
  String? deletedAt;
  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'Pincode')
  int? pincode;
  int? phone;
  @JsonKey(name: 'user_id')
  String? userId;
  @JsonKey(name: 'created_at')
  String? createdAt;
  @JsonKey(name: 'updated_at')
  String? updatedAt;
  @JsonKey(name: '__v')
  int? v;

  Map<String, dynamic> toJson() => _$PincodeAddressModelToJson(this);
} 