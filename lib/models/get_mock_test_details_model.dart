import 'package:json_annotation/json_annotation.dart';

part 'get_mock_test_details_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GetMockTestDetailsModel{

  GetMockTestDetailsModel({
    this.examCounts,
  });

  factory GetMockTestDetailsModel.fromJson(Map<String, dynamic> json) => _$GetMockTestDetailsModelFromJson(json);

  int? examCounts;

  Map<String, dynamic> toJson() => _$GetMockTestDetailsModelToJson(this);
}
