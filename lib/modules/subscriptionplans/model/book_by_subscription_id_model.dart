import 'package:json_annotation/json_annotation.dart';

part 'book_by_subscription_id_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BookBySubscriptionIdModel {
  BookBySubscriptionIdModel({
    this.sId,
    this.price,
    this.description,
    this.bookImg,
    this.bookName,
    this.bookType,
    this.comboPrice,
    this.notesOverview,
    this.subscriptionId,
    this.volume,
    this.iV,
  });

  factory BookBySubscriptionIdModel.fromJson(Map<String, dynamic> json) => _$BookBySubscriptionIdModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  String? bookName;
  String? description;
  String? bookType;
  String? bookImg;
  @JsonKey(name: 'subscription_id')
  List<String>? subscriptionId;
  int? volume;
  num? price;
  num? comboPrice;
  List<NotesOverviewModel>? notesOverview;
  @JsonKey(name: '__v')
  int? iV;

  Map<String, dynamic> toJson() => _$BookBySubscriptionIdModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NotesOverviewModel {
  NotesOverviewModel({
    this.sId,
    this.chapter,
    this.chapterName,
    this.pageNumber
  });

  factory NotesOverviewModel.fromJson(Map<String, dynamic> json) => _$NotesOverviewModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  String? chapterName;
  int? chapter;
  String? pageNumber;

  Map<String, dynamic> toJson() => _$NotesOverviewModelToJson(this);
}