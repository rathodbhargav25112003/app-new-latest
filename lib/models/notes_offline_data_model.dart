class NotesOfflineDataModel {
  final String? title;
  final String? topicName;
  final String? categoryName;
  final String? subCategoryName;
  final String? titleId;
  final String? categoryId;
  final String? subCategoryId;
  final String? topicId;
  final String? notePath;

  NotesOfflineDataModel({
    this.title,
    this.topicName,
    this.categoryName,
    this.subCategoryName,
    this.titleId,
    this.categoryId,
    this.subCategoryId,
    this.topicId,
    this.notePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'topicName': topicName,
      'title': title,
      'categoryName': categoryName,
      'subCategoryName': subCategoryName,
      'titleId': titleId,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'topicId': topicId,
      'notePath': notePath,
    };
  }

  factory NotesOfflineDataModel.fromMap(Map<String, dynamic> map) {
    return NotesOfflineDataModel(
      title: map['title'],
      topicName: map['topicName'],
      categoryName: map['categoryName'],
      subCategoryName: map['subCategoryName'],
      titleId: map['titleId'],
      categoryId: map['categoryId'],
      subCategoryId: map['subCategoryId'],
      topicId: map['topicId'],
      notePath: map['notePath'],
    );
  }
}
