// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_testimonial_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateTestimonialModel _$CreateTestimonialModelFromJson(
        Map<String, dynamic> json) =>
    CreateTestimonialModel(
      id: (json['id'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toInt(),
      sId: json['_id'] as String?,
      description: json['description'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$CreateTestimonialModelToJson(
        CreateTestimonialModel instance) =>
    <String, dynamic>{
      'rating': instance.rating,
      '_id': instance.sId,
      'name': instance.name,
      'description': instance.description,
      'id': instance.id,
    };
