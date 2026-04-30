import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

part 'delete_account_model.g.dart';

@JsonSerializable(explicitToJson: true)
class DeleteAccountModel{
  DeleteAccountModel({
    this.msg,
  });

  factory DeleteAccountModel.fromJson(Map<String, dynamic> json) =>
      _$DeleteAccountModelFromJson(json);

  final String? msg;
  Map<String, dynamic> toJson() => _$DeleteAccountModelToJson(this);
}
