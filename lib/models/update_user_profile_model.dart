import 'package:json_annotation/json_annotation.dart';

part 'update_user_profile_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UpdateUserProfileModel{
  UpdateUserProfileModel({
    this.msg,
    this.data,
    this.err,
  });
  factory UpdateUserProfileModel.fromJson(Map<String, dynamic> json) => _$UpdateUserProfileModelFromJson(json);

  String? msg;
  UserProfile? data;
  ErrorModel? err;
}

@JsonSerializable(explicitToJson: true)
class UserProfile{
  UserProfile({
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
    this.email,
    this.dateOfBirth,
    this.phone,
    this.created_at,
    this.sid
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

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
  String? email;
  @JsonKey(name: 'date_of_birth')
  String? dateOfBirth;
  String? phone;
  String? created_at;
  String? sid;

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
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
