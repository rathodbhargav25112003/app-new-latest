// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'BookmarkTestModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkTestModel _$BookmarkTestModelFromJson(Map<String, dynamic> json) =>
    BookmarkTestModel(
      isSubscribe: json['isSubscribe'] as bool,
      bookmarkQCount: (json['bookmarkQCount'] as num).toInt(),
      data: (json['data'] as List<dynamic>)
          .map((e) => TestData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BookmarkTestModelToJson(BookmarkTestModel instance) =>
    <String, dynamic>{
      'isSubscribe': instance.isSubscribe,
      'bookmarkQCount': instance.bookmarkQCount,
      'data': instance.data,
    };

TestData _$TestDataFromJson(Map<String, dynamic> json) => TestData(
      id: json['_id'] as String,
      testName: json['testName'] as String,
      time_duration: json['time_duration'] as String,
      Description: json['Description'] as String,
      questionCount: (json['questionCount'] as num).toInt(),
    );

Map<String, dynamic> _$TestDataToJson(TestData instance) => <String, dynamic>{
      '_id': instance.id,
      'testName': instance.testName,
      'Description': instance.Description,
      'time_duration': instance.time_duration,
      'questionCount': instance.questionCount,
    };
