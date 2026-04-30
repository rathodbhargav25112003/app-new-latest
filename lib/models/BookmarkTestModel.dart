import 'package:json_annotation/json_annotation.dart';

part 'BookmarkTestModel.g.dart';

@JsonSerializable()
class BookmarkTestModel {
  final bool isSubscribe;
  final int bookmarkQCount;
  final List<TestData> data;

  BookmarkTestModel({
    required this.isSubscribe,
    required this.bookmarkQCount,
    required this.data,
  });

  factory BookmarkTestModel.fromJson(Map<String, dynamic> json) =>
      _$BookmarkTestModelFromJson(json);
  Map<String, dynamic> toJson() => _$BookmarkTestModelToJson(this);
}

@JsonSerializable()
class TestData {
  @JsonKey(name: '_id')
  final String id;
  final String testName;
  final String Description;
  final String time_duration;
  final int questionCount;

  TestData({
    required this.id,
    required this.testName,
    required this.time_duration,
    required this.Description,
    required this.questionCount,
  });

  factory TestData.fromJson(Map<String, dynamic> json) =>
      _$TestDataFromJson(json);
  Map<String, dynamic> toJson() => _$TestDataToJson(this);
}
