import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';

import '../../../api_service/api_service.dart';
import '../../../app/routes.dart';
import '../../../models/create_subscription_order_model.dart';
import '../../../models/get_all_coupon_user_model.dart';
import '../../../models/payment_method_details_model.dart';
import '../../../models/subscribed_plan_model.dart';
import '../../../models/subscription_model.dart';
import '../../hardcopyNotes/model/get_all_book_model.dart';
import '../model/book_by_subscription_id_model.dart';
import '../model/book_offer_model.dart';
import '../model/create_address_model.dart';
import '../model/create_book_order_model.dart';
import '../model/create_user_offer_model.dart';
import '../model/get_address_model.dart';
import 'dart:io';
import '../model/get_all_user_order_model.dart';
import '../model/get_offer_model.dart';

part 'subscription_store.g.dart';

class SubscriptionStore =  _SubscriptionStore with _$SubscriptionStore;

abstract class _SubscriptionStore extends InternetStore with Store {
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  ObservableList<SubscriptionModel?> subscription = ObservableList<SubscriptionModel>();

  @observable
  Observable<CreateSubscriptionOrderModel?> purchaseSubscription = Observable<CreateSubscriptionOrderModel?>(null);

  @observable
  Observable<CreateSubscriptionOrderModel?> purchaseFixedSubscription = Observable<CreateSubscriptionOrderModel?>(null);

  @observable
  Observable<CreateUserOfferModel?> purchaseUserOffer = Observable<CreateUserOfferModel?>(null);

  @observable
  ObservableList<SubscribedPlanModel?> subscribedPlan = ObservableList<SubscribedPlanModel?>();

  @observable
  ObservableList<GetAllUserOrderModel?> orderUserHistory = ObservableList<GetAllUserOrderModel?>();

  @observable
  ObservableList<CreateBookOrderModel?> purchaseBooks = ObservableList<CreateBookOrderModel?>();

  @observable
  ObservableList<GetAllCouponUserModel?> getAllCouponUser = ObservableList<GetAllCouponUserModel?>();

  @observable
  ObservableList<GetAllOfferUserModel?> getAllOfferUser = ObservableList<GetAllOfferUserModel?>();

  @observable
  ObservableList<BookBySubscriptionIdModel?> getAllBookBySub = ObservableList<BookBySubscriptionIdModel?>();

  @observable
  ObservableList<GetAllBookModel?> getAllhardCopy = ObservableList<GetAllBookModel?>();

  @observable
  ObservableList<GetAddressModel?> getAllUserAddress = ObservableList<GetAddressModel?>();

  @observable
  Observable<PaymentMethodDetailsModel?> paymentDetails = Observable<PaymentMethodDetailsModel?>(null);

  @observable
  Observable<BookOfferModel?> bookOffer = Observable<BookOfferModel?>(null);

  @observable
  Observable<CreateAddressModel?> addAddress = Observable<CreateAddressModel?>(null);

  @observable
  Observable<CreateAddressModel?> updateAddress = Observable<CreateAddressModel?>(null);

  Future<void> onRegisterApiCall(BuildContext context,bool neetSS,bool iniss) async {
    await checkConnectionStatus();
    if (!isConnected) {
      Navigator.of(context).pushNamed(Routes.downloadedNotesCategory);
      return;
    }

    isLoading = true;
    try {
      final List<SubscriptionModel> result = await _apiService.subscriptionPlan(neetSS,iniss);
      subscription.clear();
      subscription.addAll(result);
    } catch (e) {
      debugPrint('Error fetching list subscription: $e');
      subscription.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onPurcaseSubscriptionApiCall(String subscriptionId, int price, String day, String durationId, String paymentId,
      String razorpayOrderId, String razorpaySignature,String couponId,String offerId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final CreateSubscriptionOrderModel result = await _apiService.purchaseSubscriptionPlan(subscriptionId, price, day, durationId, paymentId,
      razorpayOrderId, razorpaySignature,couponId,offerId);
      purchaseSubscription.value = result;

    } catch (e) {
      debugPrint('Error fetching create subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onPurchaseFixedSubscriptionApiCall(String subscriptionId, int price, bool addFixedValidity, String paymentId,
      String razorpayOrderId, String razorpaySignature,String couponId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final CreateSubscriptionOrderModel result = await _apiService.purchaseFixedSubscriptionPlan(subscriptionId, price, addFixedValidity, paymentId,
          razorpayOrderId, razorpaySignature,couponId);
      purchaseFixedSubscription.value = result;

    } catch (e) {
      debugPrint('Error fetching create fixed subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onPurcaseUserOfferApiCall(String offerId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final CreateUserOfferModel result = await _apiService.createUserOffer(offerId);
      purchaseUserOffer.value = result;

    } catch (e) {
      debugPrint('Error fetching create subscription: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onPurcaseBookApiCall(String addressId,List prize,List bookId) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<CreateBookOrderModel> result = await _apiService.purchaseBookOrder(addressId, prize, bookId);
      purchaseBooks.clear();
      purchaseBooks.addAll(result);
    } catch (e) {
      debugPrint('Error fetching get purchaseBookOrder: $e');
      purchaseBooks.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetSubscribedUserPlan() async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<SubscribedPlanModel> result = await _apiService.getSubscribedUserPlan();
      subscribedPlan.clear();
      subscribedPlan.addAll(result);
    } catch (e) {
      debugPrint('Error fetching get user subscription: $e');
      subscribedPlan.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetUserAllOrderHistory() async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<GetAllUserOrderModel> result = await _apiService.getOrderHistory();
      orderUserHistory.clear();
      orderUserHistory.addAll(result);
    } catch (e) {
      debugPrint('Error fetching get order history: $e');
      orderUserHistory.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetAllCouponUserApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<GetAllCouponUserModel> result = await _apiService.getAllCouponUser(id);
      getAllCouponUser.clear();
      getAllCouponUser.addAll(result);
    } catch (e) {
      debugPrint('Error fetching get user subscription: $e');
      getAllCouponUser.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetAllOfferUserApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<GetAllOfferUserModel> result = await _apiService.getAllOfferUser(id);
      getAllOfferUser.clear();
      getAllOfferUser.addAll(result);
    } catch (e) {
      debugPrint('Error fetching get user offer: $e');
      getAllOfferUser.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetAllBookBySubscriptionApiCall(String id) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<BookBySubscriptionIdModel> result = await _apiService.getAllBookBySubscription(id);
      getAllBookBySub.clear();
      getAllBookBySub.addAll(result);
    } catch (e) {
      debugPrint('Error fetching get book by subscription: $e');
      getAllBookBySub.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetAllBookApiCall() async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<GetAllBookModel> result = await _apiService.getAllHardCopyBook();
      getAllhardCopy.clear();
      getAllhardCopy.addAll(result);
    } catch (e) {
      debugPrint('Error fetching get all book : $e');
      getAllhardCopy.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetAllUserAddressApiCall() async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final List<GetAddressModel> result = await _apiService.getAllUserAddress();
      getAllUserAddress.clear();
      getAllUserAddress.addAll(result);
    } catch (e) {
      debugPrint('Error fetching get book by subscription: $e');
      getAllUserAddress.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCreateAddress(BuildContext context,String buildingNumber,String landMark,int pinCode,String city,String state,int phone,String name,String email) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final CreateAddressModel result = await _apiService.postAddress(buildingNumber, landMark, pinCode, city, state, phone, name,email);
      await Future.delayed(const Duration(milliseconds: 1));
      _setAddress(result);
    } catch (e) {
      debugPrint('Error fetching address: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onUpdateAddress(BuildContext context,String addressId, buildingNumber,String landMark,int pinCode,String city,String state,int phone,String name,String email) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final CreateAddressModel result = await _apiService.updateUserAddress(addressId,buildingNumber, landMark, pinCode, city, state, phone, name,email);
      await Future.delayed(const Duration(milliseconds: 1));
      _setUpdateAddress(result);
    } catch (e) {
      debugPrint('Error fetching update address: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetBookOffer(BuildContext context) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final BookOfferModel result = await _apiService.getBooksOffer();
      await Future.delayed(const Duration(milliseconds: 1));
      _setBookOffer(result);
    } catch (e) {
      debugPrint('Error fetching offers: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetPaymentDetails(BuildContext context) async {
    await checkConnectionStatus();
    if (!isConnected) {
      // Navigator.of(context).pushNamed(Routes.downloadedNotes);
      return;
    }

    isLoading = true;
    try {
      final PaymentMethodDetailsModel result = await _apiService.getPaymentDetails();
      await Future.delayed(const Duration(milliseconds: 1));
      _setPaymentDetails(result);
    } catch (e) {
      debugPrint('Error fetching offers: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onPurchaseMultipleSubscriptionPlans(List<Map<String, dynamic>> orderRequests) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      await _apiService.purchaseMultipleSubscriptionPlans(orderRequests);
    } catch (e) {
      debugPrint('Error creating multiple subscription orders: $e');
      throw e;
    } finally {
      isLoading = false;
    }
  }

  Future<void> onPurchaseBooks(List<Map<String, dynamic>> orderRequests) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      await _apiService.purchaseBooks(orderRequests);
    } catch (e) {
      debugPrint('Error creating book order: $e');
      throw e;
    } finally {
      isLoading = false;
    }
  }

  // Apple (iOS/macOS): create subscription order via in-app purchase verification endpoint
  Future<void> onCreateAppleInAppPurchaseOrder({
    required String planId,
    required int amount,
    required int day,
    String? durationId,
  }) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      await _apiService.createAppleInAppPurchaseOrder(
        planId: planId,
        amount: amount,
        day: day,
        durationId: durationId,
      );
    } catch (e) {
      debugPrint('Error creating Apple IAP order: $e');
      throw e;
    } finally {
      isLoading = false;
    }
  }

  @action
  void _setPaymentDetails(PaymentMethodDetailsModel value) {
    paymentDetails.value = value;
  }
  @action
  void _setBookOffer(BookOfferModel value) {
    bookOffer.value = value;
  }
  @action
  void _setAddress(CreateAddressModel value) {
    addAddress.value = value;
  }
  @action
  void _setUpdateAddress(CreateAddressModel value) {
    updateAddress.value = value;
  }

  // Apple In-App Purchase validation methods (iOS/macOS)
  Future<void> validateAppleSubscription() async {
    if (!Platform.isIOS && !Platform.isMacOS) return;
    
    try {
      // Import the in_app_purchase package for receipt validation
      // This would be implemented when you're ready to validate receipts
      debugPrint('Validating Apple subscription on ${Platform.operatingSystem}...');
      
      // TODO: Implement receipt validation with Apple's servers
      // await _validateReceiptWithBackend(receiptData);
    } catch (e) {
      debugPrint('Error validating Apple subscription: $e');
    }
  }

  Future<void> _validateReceiptWithBackend(String receiptData) async {
    // TODO: Implement receipt validation with your backend
    // This should verify the receipt with Apple's servers
    // and update the user's subscription status
    
    debugPrint('Validating receipt with backend: ${receiptData.substring(0, 50)}...');
  }
}
