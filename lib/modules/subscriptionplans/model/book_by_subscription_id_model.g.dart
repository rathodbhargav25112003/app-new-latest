// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_by_subscription_id_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookBySubscriptionIdModel _$BookBySubscriptionIdModelFromJson(
        Map<String, dynamic> json) =>
    BookBySubscriptionIdModel(
      sId: json['_id'] as String?,
      price: json['price'] as num?,
      description: json['description'] as String?,
      bookImg: json['bookImg'] as String?,
      bookName: json['bookName'] as String?,
      bookType: json['bookType'] as String?,
      comboPrice: json['comboPrice'] as num?,
      notesOverview: (json['notesOverview'] as List<dynamic>?)
          ?.map((e) => NotesOverviewModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      subscriptionId: (json['subscription_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      volume: (json['volume'] as num?)?.toInt(),
      iV: (json['__v'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BookBySubscriptionIdModelToJson(
        BookBySubscriptionIdModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'bookName': instance.bookName,
      'description': instance.description,
      'bookType': instance.bookType,
      'bookImg': instance.bookImg,
      'subscription_id': instance.subscriptionId,
      'volume': instance.volume,
      'price': instance.price,
      'comboPrice': instance.comboPrice,
      'notesOverview': instance.notesOverview?.map((e) => e.toJson()).toList(),
      '__v': instance.iV,
    };

NotesOverviewModel _$NotesOverviewModelFromJson(Map<String, dynamic> json) =>
    NotesOverviewModel(
      sId: json['_id'] as String?,
      chapter: (json['chapter'] as num?)?.toInt(),
      chapterName: json['chapterName'] as String?,
      pageNumber: json['pageNumber'] as String?,
    );

Map<String, dynamic> _$NotesOverviewModelToJson(NotesOverviewModel instance) =>
    <String, dynamic>{
      '_id': instance.sId,
      'chapterName': instance.chapterName,
      'chapter': instance.chapter,
      'pageNumber': instance.pageNumber,
    };
