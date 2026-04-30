class TrackOrderActivity {
  final String date;
  final String status;
  final String activity;
  final String location;
  final dynamic srStatus;
  final String srStatusLabel;

  TrackOrderActivity({
    required this.date,
    required this.status,
    required this.activity,
    required this.location,
    required this.srStatus,
    required this.srStatusLabel,
  });

  factory TrackOrderActivity.fromJson(Map<String, dynamic> json) {
    return TrackOrderActivity(
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      activity: json['activity'] ?? '',
      location: json['location'] ?? '',
      srStatus: json['sr-status'] ?? '',
      srStatusLabel: json['sr-status-label'] ?? '',
    );
  }
}

class TrackOrderShipment {
  final String awbCode;
  final int courierCompanyId;
  final String currentStatus;
  final String deliveredTo;
  final String destination;
  final String consigneeName;
  final String origin;
  final String courierName;
  final String edd;

  TrackOrderShipment({
    required this.awbCode,
    required this.courierCompanyId,
    required this.currentStatus, 
    required this.deliveredTo,
    required this.destination,
    required this.consigneeName,
    required this.origin,
    required this.courierName,
    required this.edd,
  });

  factory TrackOrderShipment.fromJson(Map<String, dynamic> json) {
    return TrackOrderShipment(
      awbCode: json['awb_code'] ?? '',
      courierCompanyId: json['courier_company_id'] ?? 0,
      currentStatus: json['current_status'] ?? '',
      deliveredTo: json['delivered_to'] ?? '', 
      destination: json['destination'] ?? '',
      consigneeName: json['consignee_name'] ?? '',
      origin: json['origin'] ?? '',
      courierName: json['courier_name'] ?? '',
      edd: json['edd'] ?? '',
    );
  }
}

class TrackOrderData {
  final int trackStatus;
  final int shipmentStatus;
  final List<TrackOrderShipment> shipmentTrack;
  final List<TrackOrderActivity> shipmentTrackActivities;
  final String trackUrl;
  final String etd;
  final bool isReturn;

  TrackOrderData({
    required this.trackStatus,
    required this.shipmentStatus,
    required this.shipmentTrack,
    required this.shipmentTrackActivities,
    required this.trackUrl,
    required this.etd,
    required this.isReturn,
  });

  factory TrackOrderData.fromJson(Map<String, dynamic> json) {
    return TrackOrderData(
      trackStatus: json['track_status'] ?? 0,
      shipmentStatus: json['shipment_status'] ?? 0,
      shipmentTrack: (json['shipment_track'] as List<dynamic>?)
          ?.map((x) => TrackOrderShipment.fromJson(x as Map<String, dynamic>))
          .toList() ?? [],
      shipmentTrackActivities: (json['shipment_track_activities'] as List<dynamic>?)
          ?.map((x) => TrackOrderActivity.fromJson(x as Map<String, dynamic>))
          .toList() ?? [],
      trackUrl: json['track_url'] ?? '',
      etd: json['etd'] ?? '',
      isReturn: json['is_return'] ?? false,
    );
  }
}

class TrackOrderResponse {
  final TrackOrderData trackingData;

  TrackOrderResponse({
    required this.trackingData,
  });

  factory TrackOrderResponse.fromJson(Map<String, dynamic> json) {
    return TrackOrderResponse(
      trackingData: TrackOrderData.fromJson(json['tracking_data'] as Map<String, dynamic>),
    );
  }
} 