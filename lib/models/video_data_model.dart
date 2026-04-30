import 'package:json_annotation/json_annotation.dart';

part 'video_data_model.g.dart';

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

@JsonSerializable(explicitToJson: true)
class AnnotationList {
  AnnotationList({
    this.annotationType,
    this.bounds,
    this.pageNumber,
    this.text,
  });

  factory AnnotationList.fromJson(Map<String, dynamic> json) => _$AnnotationListFromJson(json);

  String? annotationType;
  String? bounds;
  int? pageNumber;
  String? text;

  Map<String, dynamic> toJson() => _$AnnotationListToJson(this);
}