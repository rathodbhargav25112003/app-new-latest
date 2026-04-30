import 'package:json_annotation/json_annotation.dart';

part 'subscribed_plan_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SubscribedPlanModel{
  SubscribedPlanModel({
    this.benifit,
    this.deleted_at,
    this.subscription_id,
    this.plan_id,
    this.order_id,
    this.plan_name,
    this.buyDuration,
    this.created_at,
    this.updated_at,
    this.expirationDate,
    this.description,
    this.pdf_topic_id,
    this.amount,
    this.isPreviousPlan,
  });

  factory SubscribedPlanModel.fromJson(Map<String, dynamic> json) =>
      _$SubscribedPlanModelFromJson(json);

  List<String>? benifit;
  String? deleted_at;
  String? subscription_id;
  @JsonKey(name: '_id')
  String? plan_id;
  String? order_id;
  String? plan_name;
  Durations? buyDuration;
  String? created_at;
  String? updated_at;
  int? id;
  num? amount;
  int? active_user;
  @JsonKey(name: 'expiration_date')
  String? expirationDate;
  String? description;
  @JsonKey(name: 'is_videos')
  bool? isVideosAccess;
  @JsonKey(name: 'is_notes')
  bool? isNotesAccess;
  @JsonKey(name: 'is_exams')
  bool? isExamsAccess;
  List<String>? pdf_topic_id;
  @JsonKey(name: 'isPrevious')
  bool? isPreviousPlan;

  Map<String, dynamic> toJson() => _$SubscribedPlanModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Durations {
  Durations({
    this.durationId,
    this.price,
    this.day,
    this.offer,
  });

  factory Durations.fromJson(Map<String, dynamic> json) =>
      _$DurationsFromJson(json);

  @JsonKey(name: '_id')
  String? durationId;
  int? price;
  String? day;
  String? offer;

  Map<String, dynamic> toJson() => _$DurationsToJson(this);
}