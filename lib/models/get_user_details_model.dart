import 'package:json_annotation/json_annotation.dart';

part 'get_user_details_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetUserDetailsModel{

  GetUserDetailsModel({
    this.resetPasswordOtp,
    this.exams,
    this.isSignInGoogle,
    this.isActive,
    this.Image,
    this.id,
    this.currentData,
    this.fullname,
    this.username,
    this.preparingFor,
    this.standerdFor,
    this.standerd_id,
    this.preparing_id,
    this.state,
    this.email,
    this.dateOfBirth,
    this.phone,
    this.created_at,
    this.sid,
    this.err,
  });

  factory GetUserDetailsModel.fromJson(Map<String, dynamic> json) => _$GetUserDetailsModelFromJson(json);

  String? resetPasswordOtp;
  List<String>? exams;
  bool? isSignInGoogle;
  bool? isActive;
  String? Image;
  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'current_data')
  String? currentData;
  String? fullname;
  String? username;
  @JsonKey(name: 'preparing_for')
  String? preparingFor;
  @JsonKey(name: 'standerd_for')
  String? standerdFor;
  String? standerd_id;
  String? preparing_id;
  String? state;
  String? email;
  @JsonKey(name: 'date_of_birth')
  String? dateOfBirth;
  String? phone;
  String? created_at;
  String? sid;
  ErrorModel? err;

  Map<String, dynamic> toJson() => _$GetUserDetailsModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ErrorModel {
  ErrorModel({
    this.code,
    this.message,
    this.params,
  });

  factory ErrorModel.fromJson(Map<String, dynamic> json) =>
      _$ErrorModelFromJson(json);

  final dynamic code;
  final String? message;
  final Map<String, dynamic>? params;

  Map<String, dynamic> toJson() => _$ErrorModelToJson(this);
}
