class BookModel {
  final String id;
  final String bookName;
  final String description;
  final String bookType;
  final String bookImg;
  final List<String> preparingFor;
  final List<String> subscriptionId;
  final int volume;
  final int price;
  final int comboPrice;
  final List<ChapterOverview> notesOverview;
  final bool neetSS;
  final bool inissET;

  BookModel({
    required this.id,
    required this.bookName,
    required this.description,
    required this.bookType,
    required this.bookImg,
    required this.preparingFor,
    required this.subscriptionId,
    required this.volume,
    required this.price,
    required this.comboPrice,
    required this.notesOverview,
    required this.neetSS,
    required this.inissET,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['_id'] ?? '',
      bookName: json['bookName'] ?? '',
      description: json['description'] ?? '',
      bookType: json['bookType'] ?? '',
      bookImg: json['bookImg'] ?? '',
      preparingFor: List<String>.from(json['preparing_for'] ?? []),
      subscriptionId: List<String>.from(json['subscription_id'] ?? []),
      volume: json['volume'] ?? 0,
      price: json['price'] ?? 0,
      comboPrice: json['comboPrice'] ?? 0,
      notesOverview: (json['notesOverview'] as List<dynamic>?)
          ?.map((chapter) => ChapterOverview.fromJson(chapter))
          .toList() ??
          [],
      neetSS: json['Neet_SS'] ?? false,
      inissET: json['INISS_ET'] ?? false,
    );
  }
}

class ChapterOverview {
  final String id;
  final String chapterName;
  final int chapter;
  final String pageNumber;
  final String chapterFile;

  ChapterOverview({
    required this.id,
    required this.chapterName,
    required this.chapter,
    required this.pageNumber,
    required this.chapterFile,
  });

  factory ChapterOverview.fromJson(Map<String, dynamic> json) {
    return ChapterOverview(
      id: json['_id'] ?? '',
      chapterName: json['chapterName'] ?? '',
      chapter: json['chapter'] ?? 0,
      pageNumber: json['pageNumber'] ?? '',
      chapterFile: json['chapterFile'] ?? '',
    );
  }
} 