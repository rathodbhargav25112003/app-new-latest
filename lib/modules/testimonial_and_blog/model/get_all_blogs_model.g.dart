// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_all_blogs_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetBlogsListModel _$GetBlogsListModelFromJson(Map<String, dynamic> json) =>
    GetBlogsListModel(
      id: (json['id'] as num?)?.toInt(),
      sId: json['_id'] as String?,
      title: json['title'] as String?,
      image: json['Image'] as String?,
      alias: json['alias'] as String?,
      blogCategoryId: json['blogCategory_id'] as String?,
      blogCategoryName: json['blogCategoryName'] as String?,
      content: json['content'] as String?,
    );

Map<String, dynamic> _$GetBlogsListModelToJson(GetBlogsListModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'Image': instance.image,
      'content': instance.content,
      'title': instance.title,
      'alias': instance.alias,
      'blogCategory_id': instance.blogCategoryId,
      'blogCategoryName': instance.blogCategoryName,
      'id': instance.id,
    };
