import 'package:json_annotation/json_annotation.dart';

part 'create_custom_test_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CustomTestModel {
  CustomTestModel({
    this.sId,
    this.timeDuration,
    this.testName,
    this.numberOfQuestions,
    this.description,
    this.questionId,
    this.exam,
    this.topic,
    this.subcategory,
    this.category,
    this.marksDeducted,
    this.marksAwarded,
    this.attempt,
    this.userId
  });

  factory CustomTestModel.fromJson(Map<String, dynamic> json) => _$CustomTestModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  int? attempt;
  @JsonKey(name: 'marks_deducted')
  int? marksDeducted;
  @JsonKey(name: 'marks_awarded')
  int? marksAwarded;
  @JsonKey(name: 'user_id')
  String? userId;
  String? testName;
  @JsonKey(name: 'Description')
  String? description;
  @JsonKey(name: 'NumberOfQuestions')
  int? numberOfQuestions;
  @JsonKey(name: 'time_duration')
  String? timeDuration;
  List<CategoryModel>? category;
  List<SubcategoryModel>? subcategory;
  List<TopicModel>? topic;
  List<ExamModel>? exam;
  @JsonKey(name: 'question_id')
  List<String>? questionId;

  Map<String, dynamic> toJson() => _$CustomTestModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CategoryModel {
  CategoryModel({
    this.sId,
    this.categoryId,
    this.categoryName
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => _$CategoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'category_id')
  String? categoryId;
  @JsonKey(name: 'category_name')
  String? categoryName;

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SubcategoryModel {
  SubcategoryModel({
    this.sId,
    this.subcategoryName,
    this.subcategoryId,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) => _$SubcategoryModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'subcategory_id')
  String? subcategoryId;
  @JsonKey(name: 'subcategory_name')
  String? subcategoryName;

  Map<String, dynamic> toJson() => _$SubcategoryModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TopicModel {
  TopicModel({
    this.sId,
    this.topicId,
    this.topicName,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) => _$TopicModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'topic_id')
  String? topicId;
  @JsonKey(name: 'topic_name')
  String? topicName;

  Map<String, dynamic> toJson() => _$TopicModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ExamModel {
  ExamModel({
    this.sId,
    this.examName,
    this.examId,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) => _$ExamModelFromJson(json);

  @JsonKey(name: '_id')
  String? sId;
  @JsonKey(name: 'exam_id')
  String? examId;
  @JsonKey(name: 'exam_name')
  String? examName;

  Map<String, dynamic> toJson() => _$ExamModelToJson(this);
}