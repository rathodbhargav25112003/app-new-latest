import 'package:json_annotation/json_annotation.dart';

part 'notification_list_model.g.dart';

@JsonSerializable(explicitToJson: true)
class NotificationListModel {
  NotificationListModel({
    this.id,
    this.notificationType,
    this.notification,
    this.createdAt,
    this.updatedAt,
    this.title,
  });

  factory NotificationListModel.fromJson(Map<String, dynamic> json) => _$NotificationListModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  @JsonKey(name: 'notification_type')
  String? notificationType;
  @JsonKey(name: 'notification')
  String? notification;
  String? createdAt;
  String? updatedAt;
  String? title;

  Map<String, dynamic> toJson() => _$NotificationListModelToJson(this);
}
