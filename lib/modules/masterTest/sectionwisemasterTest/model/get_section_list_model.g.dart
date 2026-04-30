// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_section_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetSectionListModel _$GetSectionListModelFromJson(Map<String, dynamic> json) =>
    GetSectionListModel(
      sectionId: json['section_id'] as String?,
      isCompleteSection: json['isCompleteSection'] as bool?,
      section: json['section'] as String?,
      numberOfQuestions: (json['NumberOfQuestions'] as num?)?.toInt(),
      timeDuration: json['time_duration'] as String?,
      status: json['status'] as String?,
      isLocked: json['isLocked'] as bool?,
      attempted: (json['attempted'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
      markedforreview: (json['marked_for_review'] as num?)?.toInt() ?? 0,
      attemptedandmarkedforreview:
          (json['attempted_marked_for_review'] as num?)?.toInt() ?? 0,
      guess: (json['guess'] as num?)?.toInt() ?? 0,
    )..notVisited = (json['not_visited'] as num?)?.toInt();

Map<String, dynamic> _$GetSectionListModelToJson(
        GetSectionListModel instance) =>
    <String, dynamic>{
      'section_id': instance.sectionId,
      'isCompleteSection': instance.isCompleteSection,
      'time_duration': instance.timeDuration,
      'isLocked': instance.isLocked,
      'status': instance.status,
      'section': instance.section,
      'NumberOfQuestions': instance.numberOfQuestions,
      'attempted': instance.attempted,
      'skipped': instance.skipped,
      'marked_for_review': instance.markedforreview,
      'attempted_marked_for_review': instance.attemptedandmarkedforreview,
      'guess': instance.guess,
      'not_visited': instance.notVisited,
    };
