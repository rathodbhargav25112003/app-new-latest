import 'package:json_annotation/json_annotation.dart';

part 'get_declaration.g.dart';

@JsonSerializable(explicitToJson: true)
class GetDeclaration {
  @JsonKey(name: 'exam_id')
  final String? examId;

  @JsonKey(name: 'category_id')
  final String? categoryId;

  @JsonKey(name: 'exam_name')
  final String? examName;

  @JsonKey(name: 'category_name')
  final String? categoryName;

  GetDeclaration({
    this.examId,
    this.categoryId,
    this.examName,
    this.categoryName,
  });

  factory GetDeclaration.fromJson(Map<String, dynamic> json) =>
      _$GetDeclarationFromJson(json);

  Map<String, dynamic> toJson() => _$GetDeclarationToJson(this);
}
