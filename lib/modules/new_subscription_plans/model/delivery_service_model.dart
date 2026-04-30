 class DeliveryServiceModel {
  final String courierName;
  final String estimatedDeliveryDate;
  final int estimatedDeliveryHours;
  final double rate;
  final int courier_id; // Added courier_id property

  DeliveryServiceModel({
    required this.courierName,
    required this.estimatedDeliveryDate,
    required this.estimatedDeliveryHours,
    required this.rate,
    required this.courier_id, // Added to constructor
  });

  factory DeliveryServiceModel.fromJson(Map<String, dynamic> json) {
    return DeliveryServiceModel(
      courierName: json['courier_name'] ?? '',
      estimatedDeliveryDate: json['etd'] ?? '',
      estimatedDeliveryHours: json['etd_hours'] ?? 0,
      rate: (json['rate'] ?? 0.0).toDouble(),
      courier_id: json['courier_id'] ?? '', // Added to fromJson
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courier_name': courierName,
      'etd': estimatedDeliveryDate,
      'etd_hours': estimatedDeliveryHours,
      'rate': rate,
      'courier_id': courier_id, // Added to toJson
    };
  }
}