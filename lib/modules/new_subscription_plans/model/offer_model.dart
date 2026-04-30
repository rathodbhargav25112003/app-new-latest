import 'package:flutter/foundation.dart';

class OfferModel {
  final List<String>? subscriptionId;
  final double? discountPrize;
  final double? discountPercentage;
  final bool? isSingleUse;
  final bool? isMultipleUse;
  final String? title;
  final String? description;
  final bool? isFixPrice;
  final bool? isPercentage;
  final String? id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? numericId;
  final int? version;

  OfferModel({
    this.subscriptionId,
    this.discountPrize,
    this.discountPercentage,
    this.isSingleUse,
    this.isMultipleUse,
    this.title,
    this.description,
    this.isFixPrice,
    this.isPercentage,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.numericId,
    this.version,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    List<String>? subscriptionIds;
    if (json['subscription_id'] != null) {
      subscriptionIds = List<String>.from(json['subscription_id']);
    }

    return OfferModel(
      subscriptionId: subscriptionIds,
      discountPrize: json['discountPrize']?.toDouble() ?? 0.0,
      discountPercentage: json['discountPercentage']?.toDouble() ?? 0.0,
      isSingleUse: json['isSingleUse'] ?? false,
      isMultipleUse: json['isMultipleUse'] ?? false,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isFixPrice: json['isFixPrice'] ?? false,
      isPercentage: json['isPercentage'] ?? false,
      id: json['_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      numericId: json['id'],
      version: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscription_id': subscriptionId,
      'discountPrize': discountPrize,
      'discountPercentage': discountPercentage,
      'isSingleUse': isSingleUse,
      'isMultipleUse': isMultipleUse,
      'title': title,
      'description': description,
      'isFixPrice': isFixPrice,
      'isPercentage': isPercentage,
      '_id': id,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'id': numericId,
      '__v': version,
    };
  }
} 