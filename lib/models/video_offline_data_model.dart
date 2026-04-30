class VideoOfflineDataModel {
  final String? title;
  final String? categoryName;
  final String? subCategoryName;
  final String? titleId;
  final String? categoryId;
  final String? subCategoryId;
  final String? topicId;
  final String? videoPath;

  VideoOfflineDataModel({
    this.title,
    this.categoryName,
    this.subCategoryName,
    this.titleId,
    this.categoryId,
    this.subCategoryId,
    this.topicId,
    this.videoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'categoryName': categoryName,
      'subCategoryName': subCategoryName,
      'titleId': titleId,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'topicId': topicId,
      'videoPath': videoPath,
    };
  }

  factory VideoOfflineDataModel.fromMap(Map<String, dynamic> map) {
    return VideoOfflineDataModel(
      title: map['title'],
      categoryName: map['categoryName'],
      subCategoryName: map['subCategoryName'],
      titleId: map['titleId'],
      categoryId: map['categoryId'],
      subCategoryId: map['subCategoryId'],
      topicId: map['topicId'],
      videoPath: map['videoPath'],
    );
  }
}
