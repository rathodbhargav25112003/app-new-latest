import 'package:json_annotation/json_annotation.dart';

part 'subscription_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SubscriptionModel{
  SubscriptionModel({
     this.benifit,
     this.deleted_at,
     this.sid,
     this.plan_id,
     this.plan_name,
     this.duration,
     this.created_at,
     this.updated_at,
     this.id,
     this.active_user,
     this.description,
     this.order,
    this.pdf_topic_id,
    this.exam,
    this.freetrail,
    this.liveClass,
    this.mockExam,
    this.notes,
    this.videos,
    this.addFixedValidity,
    this.fixedValidityPlan
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);

  List<String>? benifit;
  dynamic deleted_at;
  @JsonKey(name:"_id")
  String? sid;
  String? plan_id;
  String? plan_name;
  List<Durations>? duration;
  String? created_at;
  String? updated_at;
  int? id;
  int? active_user;
  String? description;
  int? order;
  List<String>? pdf_topic_id;
  bool? liveClass;
  bool? exam;
  bool? mockExam;
  bool? videos;
  bool? notes;
  bool? freetrail;
  bool? addFixedValidity;
  FixedValidity? fixedValidityPlan;

  Map<String, dynamic> toJson() => _$SubscriptionModelToJson(this);
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

@JsonSerializable(explicitToJson: true)
class FixedValidity {
  FixedValidity({
    this.text,
    this.price,
    this.toTime,
    this.offer,
  });

  factory FixedValidity.fromJson(Map<String, dynamic> json) =>
      _$FixedValidityFromJson(json);

  String? text;
  int? price;
  @JsonKey(name:"totime")
  String? toTime;
  String? offer;

  Map<String, dynamic> toJson() => _$FixedValidityToJson(this);
}