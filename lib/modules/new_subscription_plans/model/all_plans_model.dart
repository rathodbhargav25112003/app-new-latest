import 'package:json_annotation/json_annotation.dart';

part 'all_plans_model.g.dart';

@JsonSerializable(explicitToJson: true)
class AllPlansResponseModel {
  AllPlansResponseModel({
    this.month,
    this.subscription,
  });

  factory AllPlansResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AllPlansResponseModelFromJson(json);

  String? month;
  List<SubscriptionPlanModel>? subscription;

  Map<String, dynamic> toJson() => _$AllPlansResponseModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SubscriptionPlanModel {
  SubscriptionPlanModel({
    this.id,
    this.fixedValidityPlan,
    this.freetrail,
    this.benifit,
    this.tempUIDataTopic,
    this.tempUIDataExam,
    this.tempUIDataNotes,
    this.tempUIDataVideos,
    this.order,
    this.addFixedValidity,
    this.isSubscriber,
    this.categoryId,
    this.subcategoryId,
    this.isSubOffer,
    this.deletedAt,
    this.planName,
    this.description,
    this.duration,
    this.createdAt,
    this.updatedAt,
    this.planId,
    this.v,
    this.hardCopyBooks,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  FixedValidityPlan? fixedValidityPlan;
  bool? freetrail;
  List<String>? benifit;
  List<dynamic>? tempUIDataTopic;
  List<dynamic>? tempUIDataExam;
  List<dynamic>? tempUIDataNotes;
  List<String>? tempUIDataVideos;
  int? order;
  bool? addFixedValidity;
  bool? isSubscriber;
  @JsonKey(name: 'category_id')
  List<String>? categoryId;
  @JsonKey(name: 'subcategory_id')
  List<String>? subcategoryId;
  int? isSubOffer;
  @JsonKey(name: 'deleted_at')
  dynamic deletedAt;
  @JsonKey(name: 'plan_name')
  String? planName;
  String? description;
  List<DurationModel>? duration;
  @JsonKey(name: 'created_at')
  String? createdAt;
  @JsonKey(name: 'updated_at')
  String? updatedAt;
  @JsonKey(name: 'plan_id')
  List<String>? planId;
  @JsonKey(name: '__v')
  int? v;
  @JsonKey(name: 'hardCopyBooks')
  List<HardCopyBookModel>? hardCopyBooks;

  Map<String, dynamic> toJson() => _$SubscriptionPlanModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FixedValidityPlan {
  FixedValidityPlan({
    this.price,
    this.offer,
    this.totime,
    this.text,
  });

  factory FixedValidityPlan.fromJson(Map<String, dynamic> json) =>
      _$FixedValidityPlanFromJson(json);

  int? price;
  String? offer;
  dynamic totime;
  String? text;

  Map<String, dynamic> toJson() => _$FixedValidityPlanToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DurationModel {
  DurationModel({
    this.id,
    this.price,
    this.day,
    this.offer,
  });

  factory DurationModel.fromJson(Map<String, dynamic> json) =>
      _$DurationModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  int? price;
  String? day;
  String? offer;

  Map<String, dynamic> toJson() => _$DurationModelToJson(this);
}

class AllPlansModel {
  final List<MonthlySubscriptionPlan> plans;

  AllPlansModel({required this.plans});

  factory AllPlansModel.fromJson(Map<String, dynamic> json) {
    return AllPlansModel(
      plans: (json['data'] as List).map((e) => MonthlySubscriptionPlan.fromJson(e)).toList(),
    );
  }
}

class MonthlySubscriptionPlan {
  final String label;
  final List<SubscriptionPlanModel>? subscription;

  MonthlySubscriptionPlan({
    required this.label,
    this.subscription,
  });

  factory MonthlySubscriptionPlan.fromJson(Map<String, dynamic> json) {
    List<SubscriptionPlanModel>? subscriptionPlans;
    
    if (json['subscription'] != null) {
      subscriptionPlans = (json['subscription'] as List)
          .map((e) => SubscriptionPlanModel.fromJson(e))
          .toList();
    }

    return MonthlySubscriptionPlan(
      label: json['label'] ?? '',
      subscription: subscriptionPlans,
    );
  }
}

class SubscriptionDuration {
  final String? id;
  final int price;
  final String? offer;
  final int? day;

  SubscriptionDuration({
    this.id,
    required this.price,
    this.offer,
    this.day,
  });

  factory SubscriptionDuration.fromJson(Map<String, dynamic> json) {
    return SubscriptionDuration(
      id: json['_id'],
      price: json['price'] ?? 0,
      offer: json['offer'],
      day: json['day'],
    );
  }
}

@JsonSerializable(explicitToJson: true)
class HardCopyBookModel {
  HardCopyBookModel({
    this.id,
    this.bookName,
    this.description,
    this.bookType,
    this.bookImg,
    this.preparingFor,
    this.subscriptionId,
    this.planId,
    this.neetSS,
    this.inissET,
    this.deletedAt,
    this.volume,
    this.price,
    this.comboPrice,
    this.notesOverview,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.length,
    this.breadth,
    this.height,
    this.weight,
  });

  factory HardCopyBookModel.fromJson(Map<String, dynamic> json) =>
      _$HardCopyBookModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  String? bookName;
  String? description;
  String? bookType;
  String? bookImg;
  @JsonKey(name: 'preparing_for')
  List<String>? preparingFor;
  @JsonKey(name: 'subscription_id')
  List<String>? subscriptionId;
  @JsonKey(name: 'plan_id')
  List<String>? planId;
  @JsonKey(name: 'Neet_SS')
  bool? neetSS;
  @JsonKey(name: 'INISS_ET')
  bool? inissET;
  @JsonKey(name: 'deleted_at')
  dynamic deletedAt;
  int? volume;
  int? price;
  int? comboPrice;
  List<NotesOverviewModel>? notesOverview;
  @JsonKey(name: 'created_at')
  String? createdAt;
  @JsonKey(name: 'updated_at')
  String? updatedAt;
  @JsonKey(name: '__v')
  int? v;
  double? length;
  double? breadth;
  double? height;
  double? weight;

  Map<String, dynamic> toJson() => _$HardCopyBookModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NotesOverviewModel {
  NotesOverviewModel({
    this.id,
    this.chapterName,
    this.chapter,
    this.pageNumber,
  });

  factory NotesOverviewModel.fromJson(Map<String, dynamic> json) =>
      _$NotesOverviewModelFromJson(json);

  @JsonKey(name: '_id')
  String? id;
  String? chapterName;
  int? chapter;
  String? pageNumber;

  Map<String, dynamic> toJson() => _$NotesOverviewModelToJson(this);
} 