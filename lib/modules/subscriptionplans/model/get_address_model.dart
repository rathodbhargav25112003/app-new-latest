import 'package:json_annotation/json_annotation.dart';

part 'get_address_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetAddressModel {
  GetAddressModel({
    this.id,
    this.created_at,
    this.updated_at,
    this.sId,
    this.iV,
    this.name,
    this.email,
    this.phone,
    this.buildingNumber,
    this.city,
    this.landMark,
    this.pincode,
    this.state,
    this.user_id
  });

  factory GetAddressModel.fromJson(Map<String, dynamic> json) => _$GetAddressModelFromJson(json);

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
  String? email;
  String? name;
  @JsonKey(name: 'Pincode')
  int? pincode;
  int? phone;
  @JsonKey(name: 'user_id')
  String? user_id;
  String? created_at;
  String? updated_at;

  Map<String, dynamic> toJson() => _$GetAddressModelToJson(this);
}
