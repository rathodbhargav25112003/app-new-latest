import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/model/all_plans_model.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/model/coupon_model.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/model/offer_model.dart';

import '../../../helpers/constants.dart';

part 'subscription_plan_store.g.dart';

class SubscriptionPlanStore = _SubscriptionPlanStore with _$SubscriptionPlanStore;

abstract class _SubscriptionPlanStore extends InternetStore with Store {
  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  ObservableList<AllPlansResponseModel> allPlans = ObservableList<AllPlansResponseModel>();

  @observable
  int currentMonthIndex = 0;
  
  @observable
  ObservableList<Map<String, dynamic>> selectedPlans = ObservableList<Map<String, dynamic>>();
  
  @observable
  ObservableList<Map<String, dynamic>> selectedBooks = ObservableList<Map<String, dynamic>>();
  
  @observable
  bool showAddedPlansContainer = false;
  
  @observable
  CouponModel? appliedCoupon;
  
  @observable
  OfferModel? appliedOffer;
  
  @observable
  double discountAmount = 0.0;
  
  @observable
  bool isCouponLoading = false;
  
  @observable
  String? couponError;

  @observable
  ObservableMap<String, int> bookQuantities = ObservableMap<String, int>();
  
  @observable
  bool isIAPEnabled = false;

  @action
  void setCurrentMonthIndex(int index) {
    currentMonthIndex = index;
  }
  
  @action
  void setIAPEnabled(bool enabled) {
    isIAPEnabled = enabled;
  }

  @computed
  List<String> get availableMonths {
    return allPlans.map((plan) => plan.month ?? '').toList();
  }
  
  @computed
  int get totalPrice {
    int total = 0;
    
    // Add prices from plans
    for (var plan in selectedPlans) {
      total += (plan['price'] as int? ?? 0);
    }
    
    // Add prices from books
    for (var book in selectedBooks) {
      total += (book['price'] as int? ?? 0);
    }
    
    // Apply discount if available
    if (discountAmount > 0) {
      total = (total - discountAmount).round();
      // Ensure total doesn't go below 0
      if (total < 0) total = 0;
    }
    
    return total;
  }
  
  @action
  void addPlan(Map<String, dynamic> plan) {
    // Check if plan already exists
    final isPlanExists = selectedPlans.any((selectedPlan) => 
      selectedPlan['id'] == plan['id'] && 
      selectedPlan['durationId'] == plan['durationId']);
      
    if (!isPlanExists) {
      selectedPlans.add(plan);
      _updateAddedPlansContainerVisibility();
    }
  }
  
  @action
  void removePlan(String planId, String durationId) {
    selectedPlans.removeWhere((plan) => 
      plan['id'] == planId && plan['durationId'] == durationId);
    _updateAddedPlansContainerVisibility();
  }
  
  @action
  void addBook(Map<String, dynamic> book) {
    // Check if book already exists
    final isBookExists = selectedBooks.any((selectedBook) => 
      selectedBook['id'] == book['id']);
      
    if (!isBookExists) {
      selectedBooks.add(book);
      // Initialize quantity to 1 by default
      bookQuantities[book['id'].toString()] = 1;
      _updateAddedPlansContainerVisibility();
      // Recalculate discount
      _recalculateDiscount();
    }
  }
  
  @action
  void removeBook(String bookId) {
    selectedBooks.removeWhere((book) => book['id'] == bookId);
    // Remove quantity
    bookQuantities.remove(bookId);
    _updateAddedPlansContainerVisibility();
    // Recalculate discount
    _recalculateDiscount();
  }
  
  @action
  void _updateAddedPlansContainerVisibility() {
    showAddedPlansContainer = selectedPlans.isNotEmpty || selectedBooks.isNotEmpty;
  }
  
  @action
  void clearSelections() {
    selectedPlans.clear();
    selectedBooks.clear();
    bookQuantities.clear();
    appliedCoupon = null;
    appliedOffer = null;
    discountAmount = 0.0;
    _updateAddedPlansContainerVisibility();
  }
  
  @action
  void updateBookQuantity(String bookId, int quantity) {
    if (quantity <= 0) {
      bookQuantities.remove(bookId);
    } else {
      bookQuantities[bookId] = quantity;
    }
    
    // Recalculate discount if an offer or coupon is applied
    _recalculateDiscount();
  }
  
  @action
  void _recalculateDiscount() {
    // Reset discount amount
    discountAmount = 0.0;
    
    // If no coupon or offer is applied, nothing to do
    if (appliedCoupon == null && appliedOffer == null) {
      return;
    }
    
    // Calculate base price from plans and books with quantities
    double basePrice = 0.0;
    
    // Add prices from plans
    for (var plan in selectedPlans) {
      if (plan.containsKey('price')) {
        basePrice += (plan['price'] as int).toDouble();
      }
    }
    
    // Add prices from books with quantities
    for (var book in selectedBooks) {
      if (book.containsKey('price') && book.containsKey('id')) {
        String bookId = book['id'].toString();
        int quantity = bookQuantities[bookId] ?? 1;
        basePrice += (book['price'] as int).toDouble() * quantity;
      }
    }
    
    // Apply discount based on what's active
    if (appliedCoupon != null) {
      // Calculate percentage discount
      if (appliedCoupon!.isPercentage == true && appliedCoupon!.discountPercentage != null) {
        discountAmount = (basePrice * appliedCoupon!.discountPercentage! / 100);
      } 
      // Calculate fixed discount
      else if (appliedCoupon!.isFixPrice == true && appliedCoupon!.discountPrize != null) {
        discountAmount = appliedCoupon!.discountPrize!;
      }
    } else if (appliedOffer != null) {
      // Calculate percentage discount
      if (appliedOffer!.isPercentage == true && appliedOffer!.discountPercentage != null) {
        discountAmount = (basePrice * appliedOffer!.discountPercentage! / 100);
      } 
      // Calculate fixed discount
      else if (appliedOffer!.isFixPrice == true && appliedOffer!.discountPrize != null) {
        discountAmount = appliedOffer!.discountPrize!;
      }
    }
  }
  
  @action
  Future<bool> applyCoupon(String code, List<Map<String, dynamic>> selectedPlans, {List<Map<String, dynamic>>? selectedBooks}) async {
    // If an offer is already applied, don't allow applying a coupon
    if (appliedOffer != null) {
      couponError = 'Please remove applied offer before using a coupon';
      return false;
    }
    
    isCouponLoading = true;
    couponError = null;
    
    try {
      // Call API to validate and get coupon details
      // For now, we'll simulate a successful response
      // In a real implementation, you would call your API here
      
      // Mock successful coupon application
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Example coupon logic
      final coupon = CouponModel(
        code: code,
        isPercentage: true,
        discountPercentage: 10.0,
        isActive: true,
      );
      
      // Apply the coupon
      appliedCoupon = coupon;
      
      // Calculate discount using the new method
      _recalculateDiscount();
      
      return true;
    } catch (e) {
      debugPrint('Error applying coupon: $e');
      couponError = e.toString();
      return false;
    } finally {
      isCouponLoading = false;
    }
  }
  
  @action
  bool applyOffer(OfferModel offer, List<Map<String, dynamic>> selectedPlans, {List<Map<String, dynamic>>? selectedBooks}) {
    // If a coupon is already applied, don't allow applying an offer
    if (appliedCoupon != null) {
      return false;
    }
    
    // Apply the offer
    appliedOffer = offer;
    
    // Calculate discount using the new method
    _recalculateDiscount();
    
    return true;
  }
  
  @action
  void removeAppliedCoupon() {
    appliedCoupon = null;
    discountAmount = 0.0;
  }
  
  @action
  void removeAppliedOffer() {
    appliedOffer = null;
    discountAmount = 0.0;
  }

  @action
  Future<void> getAllPlansForUser(String categoryId, String subcategoryId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      error = "No internet connection";
      return;
    }

    isLoading = true;
    error = null;
    
    try {
      // Get token from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      // Decide endpoint based on in-app purchases toggle. When enabled, use getStaticsPlan; otherwise keep existing endpoint.
      final String endpoint = (isIAPEnabled && (Platform.isMacOS || Platform.isIOS))
          ? '$getStaticsPlan?category_id=68962e69978cff04d4932983&subcategory_id=6896309c978cff04d49339aa'
          : '$getAllSubsriptionPlan?category_id=$categoryId&subcategory_id=$subcategoryId';

      // Make API call
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json', 
          'Authorization': token,
        },
      );
      debugPrint("request getAllPlansForUser $endpoint");
      debugPrint("getAllPlansForUser response: ${response.body}");
      
      if (response.statusCode == 200) {
        try {
          final List<dynamic> jsonData = jsonDecode(response.body);
          allPlans.clear();
          allPlans.addAll(jsonData.map((item) => AllPlansResponseModel.fromJson(item)).toList());
          
          // Set default month index to 0 if plans are available
          if (allPlans.isNotEmpty) {
            currentMonthIndex = 0;
          }
        } catch (e) {
          log("Error parsing response: $e");
          error = 'Failed to parse subscription plans: $e';
        }
      } else if (response.statusCode == 500) {
        // Handle server error
        log("Server error: ${response.body}");
        error = 'Server error occurred';
      } else {
        // Handle other errors
        log("API error: ${response.statusCode} - ${response.body}");
        error = 'Failed to fetch subscription plans';
      }
    } catch (e) {
      debugPrint('Error fetching subscription plans: $e');
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }
} 