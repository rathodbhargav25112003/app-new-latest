# macOS In-App Purchase Implementation Guide

## Overview
This document outlines the implementation of Apple's In-App Purchase system for the macOS desktop app to comply with App Store Guideline 3.1.1.

## What Has Been Implemented

### 1. Package Dependencies
- Added `in_app_purchase: ^3.1.13` to `pubspec.yaml`
- This package provides the necessary APIs to interact with Apple's StoreKit

### 2. macOS Configuration
- **DebugProfile.entitlements**: Added `com.apple.developer.in-app-payments` entitlement
- **Release.entitlements**: Added the same entitlement for production builds
- **Merchant ID**: Configured as `merchant.com.sushruta.app`

### 3. Core In-App Purchase Handler
- **File**: `lib/modules/subscriptionplans/macos_in_app_purchase.dart`
- **Features**:
  - Platform detection (macOS only)
  - Product loading from App Store Connect
  - Purchase flow management
  - Purchase status handling
  - Error handling and fallbacks

### 4. Integration with Existing Subscription Screens
- **Modified**: `subscription_detail_screen.dart`
- **Modified**: `select_book_and_subscription_screen.dart`
- **Changes**:
  - Added macOS-specific payment flow
  - Maintained existing Razorpay flow for other platforms
  - Added product mapping logic
  - Added error handling and user feedback

### 5. Subscription Store Updates
- **Modified**: `subscription_store.dart`
- **Added**: macOS subscription validation methods
- **Added**: Receipt validation placeholder methods

## Product ID Mapping

The implementation maps subscription plans to Apple product IDs:

```dart
String _getProductIdForSubscription() {
  if (selectedPlanMonth == "1") {
    return 'com.sushruta.subscription.monthly';
  } else if (selectedPlanMonth == "3") {
    return 'com.sushruta.subscription.quarterly';
  } else if (selectedPlanMonth == "12") {
    return 'com.sushruta.subscription.yearly';
  } else {
    return 'com.sushruta.subscription.lifetime';
  }
}
```

## How It Works

### 1. Platform Detection
- When a user initiates a purchase, the app checks if they're on macOS
- macOS users are directed to the in-app purchase flow
- Other platforms continue using the existing Razorpay system

### 2. In-App Purchase Flow
1. **Initialization**: Checks if in-app purchase is available
2. **Product Loading**: Fetches available products from App Store Connect
3. **Product Matching**: Maps the selected subscription to an Apple product ID
4. **Purchase**: Initiates the purchase through Apple's system
5. **Validation**: Handles purchase success/failure and validates receipts

### 3. Fallback Handling
- If in-app purchase is unavailable, shows an error dialog
- Users can retry or use alternative payment methods

## What Needs to Be Done Next

### 1. App Store Connect Configuration
- **Create In-App Purchase Products**:
  - `com.sushruta.subscription.monthly`
  - `com.sushruta.subscription.quarterly`
  - `com.sushruta.subscription.yearly`
  - `com.sushruta.subscription.lifetime`
- **Set Pricing**: Configure prices in your target currencies
- **Set Availability**: Make products available in your target regions

### 2. Receipt Validation Implementation
- **Backend Integration**: Implement receipt validation with Apple's servers
- **Subscription Sync**: Update user subscription status after successful validation
- **Error Handling**: Handle validation failures gracefully

### 3. Testing
- **Sandbox Testing**: Test purchases using Apple's sandbox environment
- **Receipt Validation**: Test receipt validation with your backend
- **User Experience**: Ensure smooth flow from purchase to content access

### 4. Production Deployment
- **App Review**: Submit the app with in-app purchase capability
- **Monitoring**: Monitor purchase success rates and user feedback
- **Analytics**: Track in-app purchase metrics

## Code Structure

```
lib/modules/subscriptionplans/
├── macos_in_app_purchase.dart          # Core in-app purchase logic
├── subscription_detail_screen.dart      # Modified for macOS support
├── select_book_and_subscription_screen.dart  # Modified for macOS support
└── store/
    └── subscription_store.dart          # Added macOS validation methods
```

## Key Benefits

1. **App Store Compliance**: Meets Guideline 3.1.1 requirements
2. **User Experience**: Native macOS payment flow
3. **Revenue**: Direct integration with Apple's payment system
4. **Maintenance**: Reduced dependency on third-party payment gateways
5. **Security**: Apple's secure payment processing

## Important Notes

- **No Breaking Changes**: Existing functionality for other platforms remains intact
- **macOS Only**: Changes only affect macOS desktop app
- **Fallback Support**: Graceful degradation if in-app purchase fails
- **User Data**: Maintains existing user subscription and content access

## Next Steps

1. Configure products in App Store Connect
2. Implement receipt validation backend
3. Test in sandbox environment
4. Submit for App Store review
5. Monitor and optimize based on user feedback

## Support

For questions or issues with this implementation:
1. Check Apple's StoreKit documentation
2. Review the in_app_purchase package documentation
3. Test thoroughly in sandbox mode before production
4. Ensure proper error handling and user feedback


