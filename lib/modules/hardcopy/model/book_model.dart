import 'package:flutter/material.dart';

class VolumeDetails {
  final String volumeName;
  final String id;
  final List<ChapterOverview> notesOverview;

  VolumeDetails({
    required this.volumeName,
    required this.id,
    required this.notesOverview,
  });

  factory VolumeDetails.fromJson(Map<String, dynamic> json) {
    return VolumeDetails(
      volumeName: json['volumeName'] ?? '',
      id: json['_id'] ?? '',
      notesOverview: (json['notesOverview'] as List?)
          ?.map((e) => ChapterOverview.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'volumeName': volumeName,
      '_id': id,
      'notesOverview': notesOverview.map((e) => e.toJson()).toList(),
    };
  }
}

class ChapterOverview {
  final String chapterFile;
  final String id;
  final String chapterName;
  final int chapter;
  final String pageNumber;

  ChapterOverview({
    required this.chapterFile,
    required this.id,
    required this.chapterName,
    required this.chapter,
    required this.pageNumber,
  });

  factory ChapterOverview.fromJson(Map<String, dynamic> json) {
    return ChapterOverview(
      chapterFile: json['chapterFile'] ?? '',
      id: json['_id'] ?? '',
      chapterName: json['chapterName'] ?? '',
      chapter: json['chapter'] ?? 0,
      pageNumber: json['pageNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterFile': chapterFile,
      '_id': id,
      'chapterName': chapterName,
      'chapter': chapter,
      'pageNumber': pageNumber,
    };
  }
}

class BookModel {
  final String bookName;
  final String description;
  final String bookType;
  final String bookImg;
  final int volume;
  final int totalPage;
  final List<String> preparingFor;
  final List<String> subscriptionId;
  final List<String> planId;
  final double length;
  final double breadth;
  final double height;
  final double weight;
  final bool neetSS;
  final bool inissET;
  final String? deletedAt;
  final String id;
  final int price;
  final int? comboPrice;
  final List<ChapterOverview> notesOverview;
  final List<VolumeDetails> volumeDetails;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  BookModel({
    required this.bookName,
    required this.description,
    required this.bookType,
    required this.bookImg,
    required this.volume,
    required this.totalPage,
    required this.preparingFor,
    required this.subscriptionId,
    required this.planId,
    required this.length,
    required this.breadth,
    required this.height,
    required this.weight,
    required this.neetSS,
    required this.inissET,
    this.deletedAt,
    required this.id,
    required this.price,
    this.comboPrice,
    required this.notesOverview,
    required this.volumeDetails,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      bookName: json['bookName'] ?? '',
      description: json['description'] ?? '',
      bookType: json['bookType'] ?? '',
      bookImg: json['bookImg'] ?? '',
      volume: json['volume'] ?? 0,
      totalPage: json['totalPage'] ?? 0,
      preparingFor: List<String>.from(json['preparing_for'] ?? []),
      subscriptionId: List<String>.from(json['subscription_id'] ?? []),
      planId: List<String>.from(json['plan_id'] ?? []),
      length: (json['length'] ?? 0).toDouble(),
      breadth: (json['breadth'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      neetSS: json['Neet_SS'] ?? false,
      inissET: json['INISS_ET'] ?? false,
      deletedAt: json['deleted_at'],
      id: json['_id'] ?? '',
      price: json['price'] ?? 0,
      comboPrice: json['comboPrice'],
      notesOverview: (json['notesOverview'] as List?)
          ?.map((e) => ChapterOverview.fromJson(e))
          .toList() ?? [],
      volumeDetails: (json['volumedetails'] as List?)
          ?.map((e) => VolumeDetails.fromJson(e))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookName': bookName,
      'description': description,
      'bookType': bookType,
      'bookImg': bookImg,
      'volume': volume,
      'totalPage': totalPage,
      'preparing_for': preparingFor,
      'subscription_id': subscriptionId,
      'plan_id': planId,
      'length': length,
      'breadth': breadth,
      'height': height,
      'weight': weight,
      'Neet_SS': neetSS,
      'INISS_ET': inissET,
      'deleted_at': deletedAt,
      '_id': id,
      'price': price,
      'comboPrice': comboPrice,
      'notesOverview': notesOverview.map((e) => e.toJson()).toList(),
      'volumedetails': volumeDetails.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
} 