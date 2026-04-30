import 'package:json_annotation/json_annotation.dart';
part 'zoom_meeting_live_model.g.dart';

@JsonSerializable()
class ZoomLiveModel {
  ZoomLiveModel({
    this.status,
    this.join_url,
    this.password,
    this.topic,
    this.meeting_id,
    this.duration,
    this.start_time,
    this.description,
    this.pdf_url,
    this.mobileAppUrl,
  });
  factory ZoomLiveModel.fromJson(Map<String, dynamic> data) =>
      _$ZoomLiveModelFromJson(data);
  String? status,
      join_url,
      password,
      topic,
      meeting_id,
      start_time,
      description,
      pdf_url,
      mobileAppUrl;
  int? duration;
  Map<String, dynamic> toJson() => _$ZoomLiveModelToJson(this);
}
