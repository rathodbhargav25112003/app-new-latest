import 'dart:io';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class AppleInAppPurchase {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static bool _isAvailable = false;
  static List<ProductDetails> _products = [];

  // Optional callbacks for consumers to react to purchase outcomes
  static void Function(PurchaseDetails purchaseDetails)? _onSuccess;
  static void Function(String message)? _onError;

  static Future<bool> initialize() async {
    // Support both iOS and macOS
    if (!Platform.isIOS && !Platform.isMacOS) return false;

    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      print('[IAP][init] isAvailable: ${_isAvailable.toString()} on ${Platform.operatingSystem}');
      if (_isAvailable) {
        // Set up purchase stream
        final Stream<List<PurchaseDetails>> purchaseUpdated =
            _inAppPurchase.purchaseStream;

        purchaseUpdated.listen((purchaseDetailsList) {
          _handlePurchaseUpdates(purchaseDetailsList);
        });

        // Load products
        await loadProducts();
      }
    } catch (e) {
      print('Error initializing in-app purchase: $e');
    }

    return _isAvailable;
  }

  static Future<void> loadProducts() async {
    if (!_isAvailable) return;

    try {
      // Define your product IDs - these should match what you configure in App Store Connect
      const Set<String> productIds = {
        '6751168007', // macOS product ID
        '6751168008', // iOS product ID
      };

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      for (final p in _products) {
        print('[IAP][products] loaded: id=${p.id} title=${p.title} price=${p.price}');
      }
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  static Future<bool> purchaseProduct(
    ProductDetails product, {
    void Function(PurchaseDetails purchaseDetails)? onSuccess,
    void Function(String message)? onError,
  }) async {
    if (!_isAvailable) return false;

    // Assign callbacks for the current purchase attempt
    _onSuccess = onSuccess;
    _onError = onError;

    final startedAt = DateTime.now();
    print('[IAP][buy] start id=${product.id} at=${startedAt.toIso8601String()}');

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      print('[IAP][buy] requestIssued=${success}');
      return success;
    } on PlatformException catch (e) {
      // StoreKit can throw userCancelled or other StoreKitError
      final code = e.code;
      final details = e.details;
      final now = DateTime.now();
      final elapsedMs = now.difference(startedAt).inMilliseconds;
      final isCancelled = code == 'userCancelled' || code == 'storekit_usercancelled' ||
          (code.toLowerCase().contains('cancel'));
      
      // Handle specific sandbox authorization error
      final isSandboxAuthError = e.message?.contains('not authorised') == true ||
          e.message?.contains('Sandbox') == true ||
          code.toLowerCase().contains('unauthorized') ||
          code.toLowerCase().contains('sandbox');
      
      // Handle "purchase not found" error
      final isPurchaseNotFound = e.message?.contains('purchase not found') == true ||
          e.message?.contains('Purchase not found') == true ||
          code.toLowerCase().contains('not_found') ||
          code.toLowerCase().contains('purchase_not_found');
      
      String msg;
      if (isCancelled) {
        msg = 'Purchase cancelled by user.';
      } else if (isSandboxAuthError) {
        msg = 'Sandbox testing account required. Please sign in with a valid sandbox tester account in System Settings > Apple ID > Media & Purchases.';
      } else if (isPurchaseNotFound) {
        msg = 'Product not available for purchase. Please ensure the subscription product is properly configured in App Store Connect.';
      } else {
        msg = 'StoreKit error: ${e.message ?? e.code}';
      }
      
      print('[IAP][buy][PlatformException] code=$code elapsedMs=$elapsedMs message=${e.message} details=$details');
      _onError?.call(msg);
      return false;
    } catch (e) {
      print('Error purchasing product: $e');
      _onError?.call('Error purchasing product: $e');
      return false;
    }
  }

  static void _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchase
        print('Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Handle successful purchase
        _handleSuccessfulPurchase(purchaseDetails);
        // Fire external success callback once per flow
        _onSuccess?.call(purchaseDetails);
        _onSuccess = null; // reset to avoid duplicate invocations
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        final code = purchaseDetails.error?.code ?? '';
        final details = purchaseDetails.error?.details;
        final message = purchaseDetails.error?.message ?? '';
        final isCancelled = code == 'userCancelled' || code == 'storekit_usercancelled' ||
            code.toLowerCase().contains('cancel');
        
        // Handle specific sandbox authorization error
        final isSandboxAuthError = message.contains('not authorised') == true ||
            message.contains('Sandbox') == true ||
            code.toLowerCase().contains('unauthorized') ||
            code.toLowerCase().contains('sandbox');
        
        // Handle "purchase not found" error
        final isPurchaseNotFound = message.contains('purchase not found') == true ||
            message.contains('Purchase not found') == true ||
            code.toLowerCase().contains('not_found') ||
            code.toLowerCase().contains('purchase_not_found');
        
        String errMsg;
        if (isCancelled) {
          errMsg = 'Purchase cancelled by user.';
        } else if (isSandboxAuthError) {
          errMsg = 'Sandbox testing account required. Please sign in with a valid sandbox tester account in System Settings > Apple ID > Media & Purchases.';
        } else if (isPurchaseNotFound) {
          errMsg = 'Product not available for purchase. Please ensure the subscription product is properly configured in App Store Connect.';
        } else {
          errMsg = message.isNotEmpty ? message : 'Unknown error';
        }
        
        print('Purchase error: ${purchaseDetails.error} details=$details');
        _onError?.call(errMsg);
        _onError = null;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  static void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) {
    // Here you would:
    // 1. Validate the receipt with your backend
    // 2. Grant access to content
    // 3. Update local subscription status

    print('Purchase successful: ${purchaseDetails.productID}');

    // Call your existing subscription API to sync with backend
    // _syncSubscriptionWithBackend(purchaseDetails);
  }

  static List<ProductDetails> get products => _products;
  static bool get isAvailable => _isAvailable;
}
