// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_exam_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookMarkExamListModel _$BookMarkExamListModelFromJson(
        Map<String, dynamic> json) =>
    BookMarkExamListModel(
      userExamId: json['userExam_id'] as String?,
      isAttemptcount: json['isAttemptcount'] as num?,
      examName: json['exam_name'] as String?,
      bookmarksCount: (json['bookmarksCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BookMarkExamListModelToJson(
        BookMarkExamListModel instance) =>
    <String, dynamic>{
      'userExam_id': instance.userExamId,
      'isAttemptcount': instance.isAttemptcount,
      'exam_name': instance.examName,
      'bookmarksCount': instance.bookmarksCount,
    };
