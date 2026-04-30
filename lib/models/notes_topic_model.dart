import 'package:json_annotation/json_annotation.dart';

part 'notes_topic_model.g.dart';

@JsonSerializable(explicitToJson: true)
class NotesTopicModel {
  NotesTopicModel({
    this.id,
    this.topicId,
    this.topicName,
    this.topic_name,
    this.subcategoryId,
    this.description,
    this.created_at,
    this.updated_at,
    this.sid,
    this.sId,
    this.contentUrl,
    this.videoUrl,
    this.subscriptionId,
    this.isfeatured,
    this.isAccess,
    this.bannerImg,
    this.contentType,
    this.categoryId,
    this.iV,
    this.title,
    this.category_name,
    this.subcategory_name,
    this.isCompleted,
    this.isBookmark,
    this.isPaused,
    this.notStart,
    this.pageNumber,
    this.annotation,
    this.plan_id,
    this.day,
    this.isfreeTrail,
    this.annotationData,
  });

  factory NotesTopicModel.fromJson(Map<String, dynamic> json) =>
      _$NotesTopicModelFromJson(json);

  int? id;
  @JsonKey(name: 'topic_id')
  String? topicId;
  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: "topic")
  String? topicName;
  String? category_name;
  String? subcategory_name;
  String? topic_name;
  @JsonKey(name: 'subcategory_id')
  String? subcategoryId;
  @JsonKey(name: 'subscription_id')
  List<String>? subscriptionId;
  @JsonKey(name: 'video_url')
  String? videoUrl;
  @JsonKey(name: 'content_url')
  String? contentUrl;
  @JsonKey(name: 'Banner_img')
  String? bannerImg;
  String? description;
  String? created_at;
  String? updated_at;
  String? sid;
  @JsonKey(name: 'is_access')
  bool? isAccess;
  bool? isfeatured;
  @JsonKey(name: 'content_type')
  String? contentType;
  @JsonKey(name: 'category_id')
  String? categoryId;
  @JsonKey(name: '__v')
  int? iV;
  int? pageNumber;
  String? title;
  bool? isCompleted;
  bool? isBookmark;
  bool? isPaused;
  bool? notStart;
  List<AnnotationData>? annotation;
  String? plan_id;
  String? day;
  bool? isfreeTrail;
  @JsonKey(name: 'notesAnnotation')
  Map<String, dynamic>? annotationData;

  Map<String, dynamic> toJson() => _$NotesTopicModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AnnotationData {
  AnnotationData({
    this.annotationType,
    this.bounds,
    this.pageNumber,
    this.text,
  });

  factory AnnotationData.fromJson(Map<String, dynamic> json) =>
      _$AnnotationDataFromJson(json);

  String? annotationType;
  String? bounds;
  int? pageNumber;
  String? text;

  Map<String, dynamic> toJson() => _$AnnotationDataToJson(this);
}

// class NotesTopicModel {
//   String? sId;
//   String? contentUrl;
//   String? videoUrl;
//   List<String>? subscriptionId;
//   bool? isAccess;
//   bool? isfeatured;
//   String? bannerImg;
//   Null? deletedAt;
//   String? contentType;
//   String? categoryId;
//   String? subcategoryId;
//   String? topicId;
//   String? createdAt;
//   String? updatedAt;
//   int? id;
//   int? iV;
//   Null? pdfId;
//   String? title;
//   String? sid;
//
//   NotesTopicModel(
//       {this.sId,
//         this.contentUrl,
//         this.videoUrl,
//         this.subscriptionId,
//         this.isAccess,
//         this.isfeatured,
//         this.bannerImg,
//         this.deletedAt,
//         this.contentType,
//         this.categoryId,
//         this.subcategoryId,
//         this.topicId,
//         this.createdAt,
//         this.updatedAt,
//         this.id,
//         this.iV,
//         this.pdfId,
//         this.title,
//         this.sid});
//
//   NotesTopicModel.fromJson(Map<String, dynamic> json) {
//     sId = json['_id'];
//     contentUrl = json['content_url'];
//     videoUrl = json['video_url'];
//     subscriptionId = json['subscription_id'].cast<String>();
//     isAccess = json['is_access'];
//     isfeatured = json['isfeatured'];
//     bannerImg = json['Banner_img'];
//     deletedAt = json['deleted_at'];
//     contentType = json['content_type'];
//     categoryId = json['category_id'];
//     subcategoryId = json['subcategory_id'];
//     topicId = json['topic_id'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//     id = json['id'];
//     iV = json['__v'];
//     pdfId = json['pdf_id'];
//     title = json['title'];
//     sid = json['sid'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['_id'] = this.sId;
//     data['content_url'] = this.contentUrl;
//     data['video_url'] = this.videoUrl;
//     data['subscription_id'] = this.subscriptionId;
//     data['is_access'] = this.isAccess;
//     data['isfeatured'] = this.isfeatured;
//     data['Banner_img'] = this.bannerImg;
//     data['deleted_at'] = this.deletedAt;
//     data['content_type'] = this.contentType;
//     data['category_id'] = this.categoryId;
//     data['subcategory_id'] = this.subcategoryId;
//     data['topic_id'] = this.topicId;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     data['id'] = this.id;
//     data['__v'] = this.iV;
//     data['pdf_id'] = this.pdfId;
//     data['title'] = this.title;
//     data['sid'] = this.sid;
//     return data;
//   }
// }
