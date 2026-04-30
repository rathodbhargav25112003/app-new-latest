import 'package:json_annotation/json_annotation.dart';

part 'create_address_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateAddressModel {
  CreateAddressModel({
    this.id,
    this.created_at,
    this.updated_at,
    this.sId,
    this.iV,
    this.name,
    this.phone,
    this.buildingNumber,
    this.city,
    this.landMark,
    this.pincode,
    this.state,
    this.user_id
  });

  factory CreateAddressModel.fromJson(Map<String, dynamic> json) => _$CreateAddressModelFromJson(json);

  int? id;
  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: '__v')
  int? iV;
  String? buildingNumber;
  @JsonKey(name: 'LandMark')
  String? landMark;
  @JsonKey(name: 'City')
  String? city;
  @JsonKey(name: 'State')
  String? state;
  String? name;
  @JsonKey(name: 'Pincode')
  int? pincode;
  int? phone;
  @JsonKey(name: 'user_id')
  String? user_id;
  String? created_at;
  String? updated_at;

  Map<String, dynamic> toJson() => _$CreateAddressModelToJson(this);
}
