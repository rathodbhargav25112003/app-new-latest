// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'all_plans_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllPlansResponseModel _$AllPlansResponseModelFromJson(
        Map<String, dynamic> json) =>
    AllPlansResponseModel(
      month: json['month'] as String?,
      subscription: (json['subscription'] as List<dynamic>?)
          ?.map(
              (e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AllPlansResponseModelToJson(
        AllPlansResponseModel instance) =>
    <String, dynamic>{
      'month': instance.month,
      'subscription': instance.subscription?.map((e) => e.toJson()).toList(),
    };

SubscriptionPlanModel _$SubscriptionPlanModelFromJson(
        Map<String, dynamic> json) =>
    SubscriptionPlanModel(
      id: json['_id'] as String?,
      fixedValidityPlan: json['fixedValidityPlan'] == null
          ? null
          : FixedValidityPlan.fromJson(
              json['fixedValidityPlan'] as Map<String, dynamic>),
      freetrail: json['freetrail'] as bool?,
      benifit:
          (json['benifit'] as List<dynamic>?)?.map((e) => e as String).toList(),
      tempUIDataTopic: json['tempUIDataTopic'] as List<dynamic>?,
      tempUIDataExam: json['tempUIDataExam'] as List<dynamic>?,
      tempUIDataNotes: json['tempUIDataNotes'] as List<dynamic>?,
      tempUIDataVideos: (json['tempUIDataVideos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      order: (json['order'] as num?)?.toInt(),
      addFixedValidity: json['addFixedValidity'] as bool?,
      isSubscriber: json['isSubscriber'] as bool?,
      categoryId: (json['category_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      subcategoryId: (json['subcategory_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isSubOffer: (json['isSubOffer'] as num?)?.toInt(),
      deletedAt: json['deleted_at'],
      planName: json['plan_name'] as String?,
      description: json['description'] as String?,
      duration: (json['duration'] as List<dynamic>?)
          ?.map((e) => DurationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      planId:
          (json['plan_id'] as List<dynamic>?)?.map((e) => e as String).toList(),
      v: (json['__v'] as num?)?.toInt(),
      hardCopyBooks: (json['hardCopyBooks'] as List<dynamic>?)
          ?.map((e) => HardCopyBookModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SubscriptionPlanModelToJson(
        SubscriptionPlanModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'fixedValidityPlan': instance.fixedValidityPlan?.toJson(),
      'freetrail': instance.freetrail,
      'benifit': instance.benifit,
      'tempUIDataTopic': instance.tempUIDataTopic,
      'tempUIDataExam': instance.tempUIDataExam,
      'tempUIDataNotes': instance.tempUIDataNotes,
      'tempUIDataVideos': instance.tempUIDataVideos,
      'order': instance.order,
      'addFixedValidity': instance.addFixedValidity,
      'isSubscriber': instance.isSubscriber,
      'category_id': instance.categoryId,
      'subcategory_id': instance.subcategoryId,
      'isSubOffer': instance.isSubOffer,
      'deleted_at': instance.deletedAt,
      'plan_name': instance.planName,
      'description': instance.description,
      'duration': instance.duration?.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'plan_id': instance.planId,
      '__v': instance.v,
      'hardCopyBooks': instance.hardCopyBooks?.map((e) => e.toJson()).toList(),
    };

FixedValidityPlan _$FixedValidityPlanFromJson(Map<String, dynamic> json) =>
    FixedValidityPlan(
      price: (json['price'] as num?)?.toInt(),
      offer: json['offer'] as String?,
      totime: json['totime'],
      text: json['text'] as String?,
    );

Map<String, dynamic> _$FixedValidityPlanToJson(FixedValidityPlan instance) =>
    <String, dynamic>{
      'price': instance.price,
      'offer': instance.offer,
      'totime': instance.totime,
      'text': instance.text,
    };

DurationModel _$DurationModelFromJson(Map<String, dynamic> json) =>
    DurationModel(
      id: json['_id'] as String?,
      price: (json['price'] as num?)?.toInt(),
      day: json['day'] as String?,
      offer: json['offer'] as String?,
    );

Map<String, dynamic> _$DurationModelToJson(DurationModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'price': instance.price,
      'day': instance.day,
      'offer': instance.offer,
    };

HardCopyBookModel _$HardCopyBookModelFromJson(Map<String, dynamic> json) =>
    HardCopyBookModel(
      id: json['_id'] as String?,
      bookName: json['bookName'] as String?,
      description: json['description'] as String?,
      bookType: json['bookType'] as String?,
      bookImg: json['bookImg'] as String?,
      preparingFor: (json['preparing_for'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      subscriptionId: (json['subscription_id'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      planId:
          (json['plan_id'] as List<dynamic>?)?.map((e) => e as String).toList(),
      neetSS: json['Neet_SS'] as bool?,
      inissET: json['INISS_ET'] as bool?,
      deletedAt: json['deleted_at'],
      volume: (json['volume'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toInt(),
      comboPrice: (json['comboPrice'] as num?)?.toInt(),
      notesOverview: (json['notesOverview'] as List<dynamic>?)
          ?.map((e) => NotesOverviewModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      v: (json['__v'] as num?)?.toInt(),
      length: (json['length'] as num?)?.toDouble(),
      breadth: (json['breadth'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$HardCopyBookModelToJson(HardCopyBookModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'bookName': instance.bookName,
      'description': instance.description,
      'bookType': instance.bookType,
      'bookImg': instance.bookImg,
      'preparing_for': instance.preparingFor,
      'subscription_id': instance.subscriptionId,
      'plan_id': instance.planId,
      'Neet_SS': instance.neetSS,
      'INISS_ET': instance.inissET,
      'deleted_at': instance.deletedAt,
      'volume': instance.volume,
      'price': instance.price,
      'comboPrice': instance.comboPrice,
      'notesOverview': instance.notesOverview?.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      '__v': instance.v,
      'length': instance.length,
      'breadth': instance.breadth,
      'height': instance.height,
      'weight': instance.weight,
    };

NotesOverviewModel _$NotesOverviewModelFromJson(Map<String, dynamic> json) =>
    NotesOverviewModel(
      id: json['_id'] as String?,
      chapterName: json['chapterName'] as String?,
      chapter: (json['chapter'] as num?)?.toInt(),
      pageNumber: json['pageNumber'] as String?,
    );

Map<String, dynamic> _$NotesOverviewModelToJson(NotesOverviewModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'chapterName': instance.chapterName,
      'chapter': instance.chapter,
      'pageNumber': instance.pageNumber,
    };
