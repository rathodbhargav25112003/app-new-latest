import 'package:json_annotation/json_annotation.dart';

part 'get_settings_data_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetSettingsDataModel{
  GetSettingsDataModel({
    this.phone,
    this.email,
    this.id,
    this.attempt,
    this.err,
    this.showActiveUser,
    this.hardCopyOff,
    this.hardCopydes,
    this.isInAPurchases,
  });

  factory GetSettingsDataModel.fromJson(Map<String, dynamic> json) => _$GetSettingsDataModelFromJson(json);

  String? phone;
  String? email;
  @JsonKey(name: '_id')
  String? id;
  int? attempt;
  bool? showActiveUser;
  ErrorModel? err;
  String? hardCopyOff;
  String? hardCopydes;
  bool? isInAPurchases;

  Map<String, dynamic> toJson() => _$GetSettingsDataModelToJson(this);
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
