// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'all_section_pallete_count_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllSectionQuestionPalleteCountModel
    _$AllSectionQuestionPalleteCountModelFromJson(Map<String, dynamic> json) =>
        AllSectionQuestionPalleteCountModel(
          section: json['section'] as String?,
          isAttempted: (json['attempted'] as num?)?.toInt(),
          isMarkedForReview: (json['marked_for_review'] as num?)?.toInt(),
          isAttemptedMarkedForReview:
              (json['attempted_marked_for_review'] as num?)?.toInt(),
          isSkipped: (json['skipped'] as num?)?.toInt(),
          notVisited: (json['not_visited'] as num?)?.toInt(),
          isGuess: (json['guess'] as num?)?.toInt(),
        );

Map<String, dynamic> _$AllSectionQuestionPalleteCountModelToJson(
        AllSectionQuestionPalleteCountModel instance) =>
    <String, dynamic>{
      'attempted': instance.isAttempted,
      'section': instance.section,
      'marked_for_review': instance.isMarkedForReview,
      'attempted_marked_for_review': instance.isAttemptedMarkedForReview,
      'skipped': instance.isSkipped,
      'not_visited': instance.notVisited,
      'guess': instance.isGuess,
    };
