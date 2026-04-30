// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_all_testimonial_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetTestimonialListModel _$GetTestimonialListModelFromJson(
        Map<String, dynamic> json) =>
    GetTestimonialListModel(
      id: (json['id'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toInt(),
      sId: json['_id'] as String?,
      description: json['description'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$GetTestimonialListModelToJson(
        GetTestimonialListModel instance) =>
    <String, dynamic>{
      'rating': instance.rating,
      '_id': instance.sId,
      'name': instance.name,
      'description': instance.description,
      'id': instance.id,
    };
