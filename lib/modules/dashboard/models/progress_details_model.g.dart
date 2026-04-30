// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_details_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgressDetailsModel _$ProgressDetailsModelFromJson(
        Map<String, dynamic> json) =>
    ProgressDetailsModel(
      isSubscribed: json['isSubscribed'] as bool?,
      McqExamCount: (json['McqExamCount'] as num?)?.toInt(),
      McqAttemptExamCount: (json['McqAttemptExamCount'] as num?)?.toInt(),
      mcqQuestion: (json['mcqQuestion'] as num?)?.toInt(),
      mcqAttemtQuestion: (json['mcqAttemtQuestion'] as num?)?.toInt(),
      neetSsExamCount: (json['Neet_SSExamCount'] as num?)?.toInt(),
      neetSUserExamCount: (json['Neet_SSUserExamCount'] as num?)?.toInt(),
      inissETExamCount: (json['INISS_ETExamCount'] as num?)?.toInt(),
      innissETUserExamCount: (json['INISS_ETUserExamCount'] as num?)?.toInt(),
      videoCount: (json['videoCount'] as num?)?.toInt(),
      completedVideoCount: (json['completedVideoCount'] as num?)?.toInt(),
      totalVideoDuration: (json['totalVideoDuration'] as num?)?.toInt(),
      completedVideoDuration: (json['completedVideoDuration'] as num?)?.toInt(),
      pdfCount: (json['pdfCount'] as num?)?.toInt(),
      completedPdfCount: (json['completedPdfCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProgressDetailsModelToJson(
        ProgressDetailsModel instance) =>
    <String, dynamic>{
      'isSubscribed': instance.isSubscribed,
      'McqExamCount': instance.McqExamCount,
      'McqAttemptExamCount': instance.McqAttemptExamCount,
      'mcqQuestion': instance.mcqQuestion,
      'mcqAttemtQuestion': instance.mcqAttemtQuestion,
      'Neet_SSExamCount': instance.neetSsExamCount,
      'Neet_SSUserExamCount': instance.neetSUserExamCount,
      'INISS_ETExamCount': instance.inissETExamCount,
      'INISS_ETUserExamCount': instance.innissETUserExamCount,
      'videoCount': instance.videoCount,
      'completedVideoCount': instance.completedVideoCount,
      'totalVideoDuration': instance.totalVideoDuration,
      'completedVideoDuration': instance.completedVideoDuration,
      'pdfCount': instance.pdfCount,
      'completedPdfCount': instance.completedPdfCount,
    };
