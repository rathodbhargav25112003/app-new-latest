// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_blog_details_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetBlogDetailsModel _$GetBlogDetailsModelFromJson(Map<String, dynamic> json) =>
    GetBlogDetailsModel(
      id: (json['id'] as num?)?.toInt(),
      sId: json['_id'] as String?,
      title: json['title'] as String?,
      image: json['Image'] as String?,
      alias: json['alias'] as String?,
      blogCategoryId: json['blogCategory_id'] as String?,
      blogCategoryName: json['blogCategoryName'] as String?,
      content: json['content'] as String?,
    );

Map<String, dynamic> _$GetBlogDetailsModelToJson(
        GetBlogDetailsModel instance) =>
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
