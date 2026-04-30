class StandardModel {
  StandardModel({
    this.mongoId,
    this.standerdFor,
    this.preparingId,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.id,
  });

  factory StandardModel.fromJson(Map<String, dynamic> json) {
    return StandardModel(
      mongoId: json['_id'] as String?,
      standerdFor: json['standerd_for'] as String?,
      preparingId: json['preparing_id'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
    );
  }

  final String? mongoId;
  final String? standerdFor;
  final String? preparingId;
  final String? description;
  final String? createdAt;
  final String? updatedAt;
  final int? id;

  Map<String, dynamic> toJson() => <String, dynamic>{
        '_id': mongoId,
        'standerd_for': standerdFor,
        'preparing_id': preparingId,
        'description': description,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'id': id,
      };
}


