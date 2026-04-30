import 'package:json_annotation/json_annotation.dart';

part 'get_video_quality_data_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetVideoQualityDataModel {
  GetVideoQualityDataModel({
    this.thumbnail,
    this.files,
    this.download
  });

  factory GetVideoQualityDataModel.fromJson(Map<String, dynamic> json) => _$GetVideoQualityDataModelFromJson(json);

  String? thumbnail;
  List<Files>? files;
  List<Download>? download;

  Map<String, dynamic> toJson() => _$GetVideoQualityDataModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Files {
  Files({
    this.quality,
    this.rendition,
    this.link,
    this.videoSize,
  });

  factory Files.fromJson(Map<String, dynamic> json) => _$FilesFromJson(json);

  String? quality;
  String? rendition;
  String? link;
  @JsonKey(name: 'size_short')
  String? videoSize;

  Map<String, dynamic> toJson() => _$FilesToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Download {
  Download({
    this.quality,
    this.rendition,
    this.link,
    this.videoSize,
  });

  factory Download.fromJson(Map<String, dynamic> json) => _$DownloadFromJson(json);

  String? quality;
  String? rendition;
  String? link;
  @JsonKey(name: 'size_short')
  String? videoSize;

  Map<String, dynamic> toJson() => _$DownloadToJson(this);
}
