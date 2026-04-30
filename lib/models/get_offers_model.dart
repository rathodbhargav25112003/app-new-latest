import 'package:json_annotation/json_annotation.dart';

part 'get_offers_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetOffersModel{

  GetOffersModel({
    this.upperbanner,
    this.lowerbanner,
    this.id,
    this.offer,
    this.offerUrl,
    this.created_at,
    this.err,
  });

  factory GetOffersModel.fromJson(Map<String, dynamic> json) => _$GetOffersModelFromJson(json);

  List<UpperBanner>? upperbanner;
  List<LowerBanner>? lowerbanner;
  @JsonKey(name: '_id')
  String? id;
  String? offer;
  String? offerUrl;
  String? created_at;
  ErrorModel? err;

  Map<String, dynamic> toJson() => _$GetOffersModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class UpperBanner {
  UpperBanner({
    this.upperbanner_url,
    this.upperbanner_img,
    this.uid,
  });

  factory UpperBanner.fromJson(Map<String, dynamic> json) =>
      _$UpperBannerFromJson(json);

  final String? upperbanner_url;
  final String? upperbanner_img;
  @JsonKey(name: '_id')
  final String? uid;

  Map<String, dynamic> toJson() => _$UpperBannerToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LowerBanner {
  LowerBanner({
    this.lowerbanner_url,
    this.lowerbanner_img,
    this.lid,
  });

  factory LowerBanner.fromJson(Map<String, dynamic> json) =>
      _$LowerBannerFromJson(json);

  final String? lowerbanner_url;
  final String? lowerbanner_img;
  @JsonKey(name: '_id')
  final String? lid;

  Map<String, dynamic> toJson() => _$LowerBannerToJson(this);
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
