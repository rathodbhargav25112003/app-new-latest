import 'package:mobx/mobx.dart';
import 'package:flutter/material.dart';
import '../../api_service/api_service.dart';
import '../../modules/new_subscription_plans/model/all_plans_model.dart';

part 'upgrade_plan_store.g.dart';

class UpgradePlanStore = _UpgradePlanStore with _$UpgradePlanStore;

abstract class _UpgradePlanStore with Store {
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  ObservableList<AllPlansResponseModel> plansList = ObservableList<AllPlansResponseModel>();

  /// Fetch upgrade plans for the given subscription and validity mode
  @action
  Future<void> fetchUpgradePlans({
    required String subscriptionId,
    bool? sameValidity, // Only pass if selected
    bool? isDiffValidity, // Only pass if selected
  }) async {
    isLoading = true;
    error = null;
    try {
      // Only the selected flag will be non-null
      final result = await _apiService.getUpgradePlanList(
        subscriptionId: subscriptionId,
        sameValidity: sameValidity,
        isDiffValidity: isDiffValidity,
      );
      plansList = ObservableList.of(result); // Assign the fetched list
    } catch (e) {
      debugPrint('Error fetching upgrade plans: $e');
      error = e.toString();
      plansList.clear();
    } finally {
      isLoading = false;
    }
  }
} 