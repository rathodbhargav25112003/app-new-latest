import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';
import 'package:shusruta_lms/modules/orders/model/track_order_model.dart';

import '../../../api_service/api_service.dart';
import '../../../helpers/colors.dart';
import '../../../modules/widgets/bottom_toast.dart';

// TODO: Run build_runner to generate this file
part 'order_store.g.dart';

class OrderStore = _OrderStore with _$OrderStore;

abstract class _OrderStore extends InternetStore with Store {
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  ObservableList<TrackOrderActivity> activities = ObservableList<TrackOrderActivity>();

  @computed
  List<TrackOrderActivity> get shipmentActivities => activities;

  @action
  Future<void> trackOrder(String orderId, String token, BuildContext context) async {
    await checkConnectionStatus();
    if (!isConnected) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "No Internet Connection!",
        backgroundColor: ThemeManager.redAlert,
      );
      return;
    }

    isLoading = true;
    error = null;
    
    try {
      // We don't use the token parameter anymore but keep it for compatibility
      final result = await _apiService.trackOrder(orderId);
      
      // Parse the list response directly
      activities.clear();
      activities.addAll(
        result.map((item) => TrackOrderActivity.fromJson(item as Map<String, dynamic>)).toList()
      );
    } catch (e) {
      error = e.toString();
      debugPrint('Error tracking order: $e');
    } finally {
      isLoading = false;
    }
  }

  @computed
  bool get hasShipmentDetails {
    return activities.isNotEmpty;
  }

  @computed
  String get currentStatus {
    return activities.isNotEmpty ? activities.first.status : 'Pending';
  }

  @computed
  String get estimatedDeliveryDate {
    // Try to find the first "Delivered" status or return "Not available"
    final deliveredActivity = activities.firstWhere(
      (activity) => activity.status == "Delivered",
      orElse: () => TrackOrderActivity(
        date: '',
        status: '',
        activity: '',
        location: '',
        srStatus: '',
        srStatusLabel: '',
      ),
    );
    
    return deliveredActivity.date.isNotEmpty ? deliveredActivity.date : 'Not available';
  }
  
  TrackOrderShipment? get shipmentDetails {
    // This property is kept for backward compatibility
    // but should not be used with the new API response format
    return null;
  }
} 