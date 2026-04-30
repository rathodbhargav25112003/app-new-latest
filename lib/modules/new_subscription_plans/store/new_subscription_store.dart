import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/model/plan_category_model.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/model/plan_subcategory_model.dart';
import '../model/delivery_service_model.dart';
import '../model/coupon_model.dart';
import '../model/offer_model.dart';
import '../model/pincode_address_model.dart';

import '../../../api_service/api_service.dart';

part 'new_subscription_store.g.dart';

class NewSubscriptionStore = _NewSubscriptionStore with _$NewSubscriptionStore;

abstract class _NewSubscriptionStore extends InternetStore with Store {
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  bool isSubcategoryLoading = false;

  @observable
  ObservableList<PlanCategoryModel> planCategories = ObservableList<PlanCategoryModel>();

  @observable
  ObservableList<PlanSubcategoryModel> planSubcategories = ObservableList<PlanSubcategoryModel>();

  @observable
  PlanCategoryModel? selectedCategory;

  @observable
  String? error;

  @observable
  ObservableList<DeliveryServiceModel> deliveryServices = ObservableList<DeliveryServiceModel>();

  @observable
  bool isServiceabilityLoading = false;

  @observable
  String? serviceabilityError;

  @observable
  bool showServiceabilityMessage = false;

  @observable
  String pincode = '';

  @observable
  Map<String, dynamic>? selectedAddress;

  @observable
  DeliveryServiceModel? selectedDeliveryService;

  @observable
  bool isAddressLoading = false;

  @observable
  String? addressError;

  @observable
  bool isCouponLoading = false;

  @observable
  String? couponError;

  @observable
  CouponModel? appliedCoupon;

  @observable
  bool isOfferLoading = false;

  @observable
  String? offerError;

  @observable
  OfferModel? appliedOffer;

  @observable
  ObservableList<OfferModel> availableOffers = ObservableList<OfferModel>();

  @observable
  double discountAmount = 0.0;
  
  // Books dimensions for serviceability check 
  @observable 
  ObservableMap<String, double> bookDimensions = ObservableMap<String, double>();

  // Book dimensions to use for serviceability check
  @observable
  double? bookHeight;
  
  @observable
  double? bookWidth;
  
  @observable
  double? bookLength;
  
  @observable
  double? bookBreadth;

  @observable
  ObservableList<PincodeAddressModel> pincodeAddresses = ObservableList<PincodeAddressModel>();

  @observable
  bool isPincodeAddressLoading = false;

  @observable
  String? pincodeAddressError;

  @action
  void setSelectedCategory(String categoryId) {
    selectedCategory = planCategories.firstWhere(
      (category) => category.sid == categoryId,
      orElse: () => PlanCategoryModel(),
    );
  }

  @action
  Future<void> getPlanCategories() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final List<PlanCategoryModel> result = await _apiService.getAllPlanCategory();
      planCategories.clear();
      planCategories.addAll(result);
    } catch (e) {
      debugPrint('Error fetching plan categories: $e');
      planCategories.clear();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> getPlanSubcategories(String categoryId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isSubcategoryLoading = true;
    try {
      final List<PlanSubcategoryModel> result = await _apiService.getSubByCatId(categoryId);
      planSubcategories.clear();
      planSubcategories.addAll(result);
    } catch (e) {
      debugPrint('Error fetching plan subcategories: $e');
      planSubcategories.clear();
    } finally {
      isSubcategoryLoading = false;
    }
  }

  @action
  void setPincode(String value) {
    pincode = value;
  }

  @action
  Future<void> checkServiceabilityWithDimensions(
    String pincode, 
    double weight, {
    double? height,
    double? width,
    double? length,
    double? breadth,
  }) async {
    // Set the book dimensions
    bookHeight = height;
    bookWidth = width;
    bookLength = length;
    bookBreadth = breadth;
    
    // Call the standard serviceability check
    await checkServiceability(
      pincode,
      weight,
      height: height,
      width: width,
      length: length,
      breadth: breadth,
    );
  }

  @action
  void clearDeliveryServices() {
    deliveryServices.clear();
    showServiceabilityMessage = false;
  }

  @action
  Future<bool> createAddress(Map<String, dynamic> addressData) async {
    isAddressLoading = true;
    addressError = null;

    try {
      final createdAddress = await _apiService.createNewAddress(addressData);
      selectedAddress = createdAddress;
      isAddressLoading = false;
      return true;
    } catch (e) {
      addressError = e.toString();
      isAddressLoading = false;
      return false;
    }
  }

  @action
  void setSelectedDeliveryService(DeliveryServiceModel service) {
    selectedDeliveryService = service;
  }

  @action
  Future<bool> verifyCoupon(String couponCode, List<Map<String, dynamic>> selectedPlans) async {
    // If an offer is already applied, don't allow applying a coupon
    if (appliedOffer != null) {
      couponError = "Please remove the applied offer before applying a coupon";
      return false;
    }
    
    isCouponLoading = true;
    couponError = null;
    appliedCoupon = null;
    discountAmount = 0.0;

    try {
      final result = await _apiService.verifyCouponCode(couponCode);
      
      if (result['success']) {
        if (result['coupon'] != null) {
          appliedCoupon = CouponModel.fromJson(result['coupon']);
          
          // Calculate discount amount based on coupon type
          if (appliedCoupon?.isPercentage == true) {
            // For percentage-based discounts, we need the total price to calculate
            double basePrice = 0.0;
            if (selectedPlans.isNotEmpty) {
              for (var plan in selectedPlans) {
                if (plan.containsKey('price')) {
                  basePrice += double.tryParse(plan['price'].toString()) ?? 0.0;
                }
              }
            }
            
            // Fallback to a default price if no plans or prices found
            if (basePrice <= 0) {
              basePrice = 8500.0;
            }
            
            // Calculate percentage discount
            final percentage = appliedCoupon?.discountPercentage ?? 0.0;
            discountAmount = (basePrice * percentage / 100);
          } else if (appliedCoupon?.isFixPrice == true) {
            // For fixed-price discounts, use the discount prize directly
            discountAmount = appliedCoupon?.discountPrize ?? 0.0;
          }
        }
        isCouponLoading = false;
        return true;
      } else {
        couponError = result['message'];
        isCouponLoading = false;
        return false;
      }
    } catch (e) {
      couponError = e.toString();
      debugPrint('Error verifying coupon: $e');
      isCouponLoading = false;
      return false;
    }
  }

  @action
  void clearCoupon() {
    appliedCoupon = null;
    couponError = null;
    discountAmount = 0.0;
    debugPrint('Cleared coupon, discount amount: $discountAmount');
  }
  
  @action
  Future<void> getAvailableOffers() async {
    isOfferLoading = true;
    offerError = null;
    
    try {
      final offers = await _apiService.getAllUserOffers();
      availableOffers.clear();
      availableOffers.addAll(offers);
    } catch (e) {
      offerError = e.toString();
      debugPrint('Error fetching offers: $e');
    } finally {
      isOfferLoading = false;
    }
  }
  
  @action
  bool applyOffer(OfferModel offer, List<Map<String, dynamic>> selectedPlans, {List<Map<String, dynamic>>? selectedBooks, Map<int, int>? bookQuantities}) {
    // If a coupon is already applied, don't allow applying an offer
    if (appliedCoupon != null) {
      offerError = "Please remove the applied coupon before applying an offer";
      return false;
    }
    
    appliedOffer = offer;
    discountAmount = 0.0; // Reset discount amount before calculating
    
    // Calculate discount amount based on offer type
    if (offer.isPercentage == true) {
      // For percentage-based discounts, we need the total price to calculate
      double basePrice = 0.0;
      
      // Add prices from plans
      if (selectedPlans.isNotEmpty) {
        for (var plan in selectedPlans) {
          if (plan.containsKey('price')) {
            basePrice += double.tryParse(plan['price'].toString()) ?? 0.0;
          }
        }
      }
      
      // Add prices from books if available, using current quantities
      if (selectedBooks != null && selectedBooks.isNotEmpty) {
        for (var book in selectedBooks) {
          if (book.containsKey('price')) {
            int bookId = int.tryParse(book['id'].toString()) ?? 0;
            // Always use the current quantity from bookQuantities
            int qty = bookQuantities?[bookId] ?? 1;
            double price = double.tryParse(book['price'].toString()) ?? 0.0;
            basePrice += price * qty;
          }
        }
      }
      
      // Calculate percentage discount
      final percentage = offer.discountPercentage ?? 0.0;
      discountAmount = (basePrice * percentage / 100);
      debugPrint('Applied percentage discount: $percentage% of $basePrice = $discountAmount');
    } else if (offer.isFixPrice == true) {
      // For fixed-price discounts, use the discount prize directly
      discountAmount = offer.discountPrize ?? 0.0;
      debugPrint('Applied fixed discount: $discountAmount');
    } else {
      // Fallback for undefined discount type
      discountAmount = offer.discountPrize ?? offer.discountPercentage ?? 0.0;
      debugPrint('Applied fallback discount: $discountAmount');
    }
    
    return true;
  }
  
  @action
  void clearOffer() {
    appliedOffer = null;
    offerError = null;
    discountAmount = 0.0;
    debugPrint('Cleared offer, discount amount: $discountAmount');
  }

  @action
  Future<void> checkServiceability(
    String pincode, 
    double weight, {
    double? height,
    double? width,
    double? length,
    double? breadth,
  }) async {
    isServiceabilityLoading = true;
    serviceabilityError = null;
    showServiceabilityMessage = false;
    deliveryServices.clear();

    try {
      // Build the URL with query parameters
      final queryParams = {
        'delivery_postcode': pincode,
        'weight': weight.toString(),
      };
      
      // Add dimensions if provided
      if (height != null) queryParams['height'] = height.toString();
      if (width != null) queryParams['width'] = width.toString();
      if (length != null) queryParams['length'] = length.toString();
      if (breadth != null) queryParams['breadth'] = breadth.toString();
      
      final services = await _apiService.checkServiceability(
        pincode, 
        weight,
        height: height,
        width: width,
        length: length,
        breadth: breadth,
      );
      
      if (services.isNotEmpty) {
        deliveryServices.addAll(
          services.map((service) => DeliveryServiceModel.fromJson(service)).toList()
        );
      }
      
      showServiceabilityMessage = true;
    } catch (e) {
      serviceabilityError = e.toString();
    } finally {
      isServiceabilityLoading = false;
    }
  }

  @action
  Future<void> getPincodeAddresses(String pincode) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isPincodeAddressLoading = true;
    pincodeAddressError = null;
    pincodeAddresses.clear();

    try {
      final result = await _apiService.getPincodeAddresses(pincode);
      pincodeAddresses.addAll(result);
    } catch (e) {
      debugPrint('Error fetching pincode addresses: $e');
      pincodeAddressError = e.toString();
    } finally {
      isPincodeAddressLoading = false;
    }
  }

  @action
  void selectAddress(Map<String, dynamic> address) {
    selectedAddress = address;
  }
} 