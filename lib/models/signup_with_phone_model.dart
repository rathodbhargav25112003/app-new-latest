import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

part 'signup_with_phone_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SignupWithPhoneModel{

  SignupWithPhoneModel({
    this.created,
    this.err,
    this.data
  });

  factory SignupWithPhoneModel.fromJson(Map<String, dynamic> json) => _$SignupWithPhoneModelFromJson(json);

  final bool? created;
  final ErrorModel? err;
  final UserDataModel? data;
  Map<String, dynamic> toJson() => _$SignupWithPhoneModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class UserDataModel {
  UserDataModel({
    this.user,
    this.token,
  });

  factory UserDataModel.fromJson(Map<String, dynamic> json) => _$UserDataModelFromJson(json);

  final UsersModel? user;
  final String? token;

  Map<String, dynamic> toJson() => _$UserDataModelToJson(this);
}


@JsonSerializable(explicitToJson: true)
class UsersModel {
  UsersModel({
    this.resetPasswordOtp,
    this.exams,
    this.isActive,
    this.Image,
    this.id,
    this.currentData,
    this.fullname,
    this.username,
    this.preparing_for,
    this.email,
    this.dateOfBirth,
    this.phone,
    this.created_at,
  });

  factory UsersModel.fromJson(Map<String, dynamic> json) => _$UsersModelFromJson(json);

  final String? resetPasswordOtp;
  final List<String>? exams;
  final bool? isActive;
  final String? Image;
  @JsonKey(name: '_id')
  final String? id;
  @JsonKey(name: 'current_data')
  final String? currentData;
  final String? fullname;
  final String? username;
  final String? preparing_for;
  final String? email;
  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth;
  final String? phone;
  final String? created_at;

  Map<String, dynamic> toJson() => _$UsersModelToJson(this);
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
