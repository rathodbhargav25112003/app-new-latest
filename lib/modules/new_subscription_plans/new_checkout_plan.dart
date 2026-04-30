// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, library_private_types_in_public_api, use_build_context_synchronously, avoid_print, unused_local_variable, unnecessary_to_list_in_spreads, prefer_interpolation_to_compose_strings, unused_element

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:http/http.dart' as http;
import 'package:shusruta_lms/modules/new_subscription_plans/select_delivery_type.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/new_subscription_store.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/widget/custom_info_card.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/widget/exam_goal_dialog.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/new_select_offers_plan.dart';
import 'package:shusruta_lms/modules/subscriptionplans/razorpay_payment.dart';
import 'package:shusruta_lms/modules/subscriptionplans/web_payment_page.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';
import 'package:shusruta_lms/modules/subscriptionplans/macos_in_app_purchase.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';
import 'package:shusruta_lms/modules/widgets/subscription_dialog.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/responsive_helper.dart';
import '../../helpers/styles.dart';
import '../notes/sharedhelper.dart';
import '../widgets/bottom_toast.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/select_address.dart';

class NewCheckoutPlan extends StatefulWidget {
  final List<Map<String, dynamic>> plans;
  final List<Map<String, dynamic>> books;
  final int totalPrice;
  final bool isUpgrade;
  final String? subscriptionId;

  const NewCheckoutPlan(
      {super.key,
      required this.plans,
      this.books = const [],
      required this.totalPrice,
      this.isUpgrade = false,
      this.subscriptionId});

  @override
  State<NewCheckoutPlan> createState() => _NewCheckoutPlanState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>?;
    return CupertinoPageRoute(
      builder: (_) => Provider<NewSubscriptionStore>(
        create: (_) => NewSubscriptionStore(),
        child: NewCheckoutPlan(
          plans: List<Map<String, dynamic>>.from(args?['plans'] ?? []),
          books: List<Map<String, dynamic>>.from(args?['books'] ?? []),
          totalPrice: args?['totalPrice'] ?? 0,
          isUpgrade: args?['isUpgrade'] ?? false,
          subscriptionId: args?['subscriptionId'],
        ),
      ),
    );
  }
}

class _NewCheckoutPlanState extends State<NewCheckoutPlan> {
  late List<Map<String, dynamic>> plans;
  late List<Map<String, dynamic>> books;
  late NewSubscriptionStore _store;
  late SubscriptionStore _subscriptionStore;
  late LoginStore _loginStore;
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  // Standard book dimensions in cm
  final double _defaultBookHeight = 24.0;
  final double _defaultBookWidth = 16.0;
  final double _defaultBookLength = 4.0;

  // Standard weight for books in kg
  final double _bookWeight = 2.0;

  // Track quantity for each book by id
  Map<int, int> bookQuantities = {};

  int get totalPrice {
    // Calculate plans subtotal
    final double plansSubtotal = plans.fold(
        0.0,
        (sum, plan) =>
            sum + (double.tryParse(plan['price'].toString()) ?? 0.0));
    // Calculate books subtotal based on selected quantity
    final double booksSubtotal = books.fold(0.0, (sum, book) {
      int bookId = int.tryParse(book['id'].toString()) ?? 0;
      int qty = bookQuantities[bookId] ?? 1;
      double price = double.tryParse(book['price'].toString()) ?? 0.0;
      return sum + (price * qty);
    });
    return (plansSubtotal + booksSubtotal).round();
  }

  @override
  void initState() {
    super.initState();
    plans = widget.plans;
    books = widget.books;
    // Initialize book quantities to 1
    for (var book in books) {
      int bookId = int.tryParse(book['id'].toString()) ?? 0;
      bookQuantities[bookId] = 1;
    }

    // Initialize Razorpay
    RazorpayPayment.initialize(_handlePaymentSuccess, _handlePaymentFailure);

    // Add a listener to refresh the UI when coming back to this screen
      WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load settings data to get InAppPurchase setting
      final loginStore = Provider.of<LoginStore>(context, listen: false);
      if (loginStore.settingsData.value == null) {
        await loginStore.onGetSettingsData();
      }
      
      // This will be called after the initial build
      if (mounted) {
        setState(() {
          // Trigger a rebuild to reflect any changes in address or delivery service
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store = Provider.of<NewSubscriptionStore>(context);
    _subscriptionStore = Provider.of<SubscriptionStore>(context);
    _loginStore = Provider.of<LoginStore>(context, listen: false);
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    _couponController.dispose();
    RazorpayPayment.dispose();
    super.dispose();
  }

  void navigateToSelectDeliveryType(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => Provider<NewSubscriptionStore>.value(
          value: _store,
          child: SelectDeliveryType(
            deliveryServices: _store.deliveryServices,
            pincode: _store.pincode,
          ),
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = MediaQuery.of(context).size.width > 600;
    final isTablet = screenWidth > 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    final contentWidth = isDesktop ? 600.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTokens.brand, AppTokens.brand2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // HEADER BAR
            Padding(
              padding: (Platform.isWindows || Platform.isMacOS)
                  ? const EdgeInsets.symmetric(
                      vertical: Dimensions.PADDING_SIZE_LARGE * 1.2,
                      horizontal: Dimensions.PADDING_SIZE_LARGE * 1.2)
                  : const EdgeInsets.only(
                      top: Dimensions.PADDING_SIZE_LARGE * 2,
                      left: Dimensions.PADDING_SIZE_LARGE * 1,
                      right: Dimensions.PADDING_SIZE_LARGE * 1.2,
                      bottom: Dimensions.PADDING_SIZE_SMALL * 1.3),
              child: Row(
                children: [
                  IconButton(
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
                  Text(
                    "Checkout",
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),

            // MAIN CONTENT
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.PADDING_SIZE_SMALL,
                  vertical: Dimensions.PADDING_SIZE_SMALL,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: (Platform.isWindows || Platform.isMacOS)
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plans section - iterate through the plans received
                      ...plans
                          .map((plan) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildPlanCard(plan),
                              ))
                          .toList(),

                      // If there's no plans, show a fallback card
                      if (plans.isEmpty && books.isEmpty) _buildPlanCard(),

                      // HardCopy Books section - iterate through the books received
                      if (books.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...books.map((book) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildBookCard(book),
                            )),
                      ],

                      const SizedBox(height: 8),

                      // Add Address
                      if (books.isNotEmpty)
                        _optionTile(
                          icon: Icons.location_on_outlined,
                          title: _store.selectedAddress != null
                              ? _formatAddress(_store.selectedAddress!)
                              : "Select delivery type & Add address",
                          onTap: () => _store.selectedAddress != null
                              ? _showAddressDetails(context)
                              : showCheckDeliveryBottomSheet(context),
                        ),
                      if (books.isNotEmpty) const SizedBox(height: 8),

                      // Display selected delivery service if available
                      Observer(
                        builder: (_) {
                          if (_store.selectedDeliveryService != null) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: ThemeManager.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.white.withOpacity(0.3),
                                  width: 0.86,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery Service',
                                    style: interBold.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Courier: ${_store.selectedDeliveryService!.courierName}',
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: AppColors.grey4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Est. Delivery: ${_store.selectedDeliveryService!.estimatedDeliveryDate}',
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: AppColors.grey4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rate: ₹${_store.selectedDeliveryService!.rate.toStringAsFixed(2)}',
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: AppColors.grey4,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 12),

                      // // Delivery Type
                      // _optionTile(
                      //   icon: Icons.local_shipping_outlined,
                      //   title: "Select delivery type",
                      //   onTap: () {
                      //     Navigator.of(context).pushNamed(Routes.selectDeliveryType);
                      //   },
                      // ),
                      // const SizedBox(height: 8),
                      _buildCouponRow(),
                      const SizedBox(height: 8),
                      Observer(
                        builder: (_) {
                          // Check InAppPurchase setting
                          final bool isIAPEnabled = _loginStore.settingsData.value?.isInAPurchases == true;
                          
                          // If InAppPurchase is enabled, show empty container
                          if (isIAPEnabled && (Platform.isMacOS || Platform.isIOS)) {
                            return const SizedBox.shrink();
                          }
                          
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (context) =>
                                      Provider<NewSubscriptionStore>.value(
                                    value: _store,
                                    child: NewSelectOffersPlan(
                                      plans: plans,
                                      books: books,
                                      bookQuantities: bookQuantities,
                                    ),
                                  ),
                                ))
                                    .then((result) {
                                  if (result != null &&
                                      result is Map<String, dynamic>) {
                                    if (result['applied'] == true) {
                                      // Refresh UI
                                      setState(() {});
                                    }
                                  }
                                });
                              },
                              child: Text(
                                "View all offers",
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.blueFinal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentInfoCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showCheckDeliveryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeManager.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Observer(
                builder: (_) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Check Delivery Availability',
                        style: interSemiBold.copyWith(
                          fontSize: Dimensions.fontSizeSmallLarge,
                          fontWeight: FontWeight.w700,
                          color: ThemeManager.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your PIN code to check if delivery is\npossible in your area.',
                        textAlign: TextAlign.center,
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grey4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          fontWeight: FontWeight.w400,
                          color: ThemeManager.black,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: "Enter PIN",
                          hintStyle: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            fontWeight: FontWeight.w400,
                            color: AppColors.grey4,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.grey.shade400, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.blueFinal, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status message
                      if (_store.showServiceabilityMessage) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _store.deliveryServices.isNotEmpty
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _store.deliveryServices.isNotEmpty
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _store.deliveryServices.isNotEmpty
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _store.deliveryServices.isNotEmpty
                                      ? "Delivery available in your area!"
                                      : "Sorry, we don't deliver to this pincode yet.",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: _store.deliveryServices.isNotEmpty
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Center(
                        child: SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blueFinal,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _store.isServiceabilityLoading
                              ? null
                              : () async {
                                  final pincode =
                                      _pincodeController.text.trim();
                                  if (pincode.length == 6) {
                                    // First check if there are existing addresses for this pincode
                                    try {
                                      _store.isPincodeAddressLoading = true;
                                      await _store.getPincodeAddresses(pincode);
                                      _store.isPincodeAddressLoading = false;
                                      
                                      // Set the pincode for later use
                                      _store.setPincode(pincode);
                                      
                                      // Close bottom sheet
                                      Navigator.of(context).pop();
                                      
                                      if (_store.pincodeAddresses.isNotEmpty) {
                                        // If addresses exist, show address selection screen
                                        // Add quantity information to books before passing to SelectAddress
                                        List<Map<String, dynamic>> booksWithQuantities = books.map((book) {
                                          int bookId = int.tryParse(book['id'].toString()) ?? 0;
                                          int quantity = bookQuantities[bookId] ?? 1;
                                          return {
                                            ...book,
                                            'quantity': quantity,
                                          };
                                        }).toList();
                                        
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => Provider<NewSubscriptionStore>.value(
                                              value: _store,
                                              child: SelectAddress(pincode: pincode, books: booksWithQuantities),
                                            ),
                                          ),
                                        );
                                      } else {
                                        // If no addresses, check serviceability and proceed as before
                                        await _checkServiceabilityWithDimensions(pincode);
                                        
                                        if (_store.deliveryServices.isNotEmpty) {
                                          navigateToSelectDeliveryType(context);
                                        }
                                      }
                                    } catch (e) {
                                      // If there's an error fetching addresses, fall back to regular flow
                                      await _checkServiceabilityWithDimensions(pincode);
                                      
                                      if (_store.deliveryServices.isNotEmpty) {
                                        Navigator.of(context).pop();
                                        navigateToSelectDeliveryType(context);
                                      }
                                    }
                                  }
                                },
                            child: _store.isServiceabilityLoading || _store.isPincodeAddressLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                "Check availability",
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  fontWeight: FontWeight.w400,
                                  color: ThemeManager.white,
                                ),
                              ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: ThemeManager.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.white.withOpacity(0.3),
            width: 0.86,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: AppColors.grey4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: interRegular.copyWith(
                  fontSize: 14,
                  color: ThemeManager.black,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.grey4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard([Map<String, dynamic>? plan]) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeManager.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white.withOpacity(0.3),
          width: 0.86,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan?['name'] ?? "First Plan",
                  style: interBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Inclusions",
            style: interSemiBold.copyWith(
              fontSize: Dimensions.fontSizeSmallLarge,
              fontWeight: FontWeight.w500,
              color: ThemeManager.black,
            ),
          ),
          const SizedBox(height: 12),
          // Get default example benefits if none provided
          ...(_getPlanBenefits(plan)).map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check, size: 20, color: ThemeManager.blueFinal),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                    e.toString(),
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey4,
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Validity: ${plan?['day'] != null ? '${plan?['day']} days' : "25th Nov to 25th Dec 2024"}",
                style: interRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  fontWeight: FontWeight.w400,
                  color: ThemeManager.black,
                ),
              ),
              Text(
                "₹${plan?['price'] ?? "8,500"}",
                style: interBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  color: ThemeManager.blueFinal,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  List<String> _getPlanBenefits(Map<String, dynamic>? plan) {
    if (plan == null) {
      return [
        "Lorem ipsum doler sit amet this is a dummy text",
        "This is a dummy texts lorem ipsum",
        "We write anything here doler sit amet",
      ];
    }

    // Check for different possible keys for benefits
    if (plan.containsKey('benifit') && plan['benifit'] is List) {
      return (plan['benifit'] as List).map((e) => e.toString()).toList();
    } else if (plan.containsKey('benefits') && plan['benefits'] is List) {
      return (plan['benefits'] as List).map((e) => e.toString()).toList();
    } else {
      // Default fallback text
      return [
        "Lorem ipsum doler sit amet this is a dummy text",
        "This is a dummy texts lorem ipsum",
        "We write anything here doler sit amet",
      ];
    }
  }

  Widget _buildCouponRow() {
    return Observer(builder: (_) {
      final hasOffer = _store.appliedOffer != null;
      
      // Check InAppPurchase setting
      final bool isIAPEnabled = _loginStore.settingsData.value?.isInAPurchases == true;
      
      // If InAppPurchase is enabled, show empty container for macOS and iOS
      if (isIAPEnabled && (Platform.isMacOS || Platform.isIOS)) {
        return const SizedBox.shrink();
      }

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: ThemeManager.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasOffer
                    ? Colors.green.shade200
                    : AppColors.white.withOpacity(0.3),
                width: 0.86,
              ),
            ),
            child: Row(
              children: [
                if (hasOffer)
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: hasOffer
                      ? Text(
                          "Offer applied: ${_store.appliedOffer!.title}",
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            fontWeight: FontWeight.w400,
                            color: Colors.green.shade700,
                          ),
                        )
                      : TextField(
                          controller: _couponController,
                          enabled: !hasOffer,
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: ThemeManager.black,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter Coupon code',
                            hintStyle: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              fontWeight: FontWeight.w400,
                              color: AppColors.grey4,
                            ),
                          ),
                        ),
                ),
                if (hasOffer)
                  TextButton(
                    onPressed: () {
                      _store.clearOffer();
                      setState(() {});
                    },
                    child: Text(
                      "Remove",
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: AppColors.blueFinal,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _store.isCouponLoading
                        ? null
                        : () {
                            if (_couponController.text.isNotEmpty) {
                              _applyCoupon();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      backgroundColor: AppColors.blueFinal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _store.isCouponLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "Apply",
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              fontWeight: FontWeight.w400,
                              color: ThemeManager.white,
                            ),
                          ),
                  )
              ],
            ),
          ),

          // Show error or success message for coupons
          if (!hasOffer) ...[
            if (_store.couponError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _store.couponError!,
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_store.appliedCoupon != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Coupon applied: ₹${_store.discountAmount.toStringAsFixed(2)} discount",
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _store.clearCoupon();
                        _couponController.clear();
                      },
                      child: Text(
                        "Remove",
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: AppColors.blueFinal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // Show discount amount for applied offer
          if (hasOffer)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _store.appliedOffer!.isPercentage == true
                          ? "${_store.appliedOffer!.discountPercentage?.toStringAsFixed(0)}% discount (₹${_store.discountAmount.toStringAsFixed(2)})"
                          : "₹${_store.discountAmount.toStringAsFixed(2)} discount",
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  void _applyCoupon() async {
    await _store.verifyCoupon(_couponController.text.trim(), plans);
  }

  Widget _buildPaymentInfoCard() {
    return Observer(builder: (_) {
      // Calculate subtotal for plans
      final double plansSubtotal = plans.fold(
          0.0,
          (sum, plan) =>
              sum + (double.tryParse(plan['price'].toString()) ?? 0.0));
      // Calculate subtotal for books based on selected quantity
      final double booksSubtotal = books.fold(0.0, (sum, book) {
        int bookId = int.tryParse(book['id'].toString()) ?? 0;
        int qty = bookQuantities[bookId] ?? 1;
        double price = double.tryParse(book['price'].toString()) ?? 0.0;
        return sum + (price * qty);
      });
      final double originalPrice = plansSubtotal + booksSubtotal;
      final double discountValue = _store.discountAmount;
      // Get delivery charges if a delivery service is selected
      final double deliveryCharges = _store.selectedDeliveryService != null
          ? _store.selectedDeliveryService!.rate
          : 0.0;
      // Debug output to verify discount amount
      debugPrint('Payment card - discount amount: $discountValue');
      debugPrint('Applied coupon: ${_store.appliedCoupon?.code}');
      debugPrint('Applied offer: ${_store.appliedOffer?.title}');
      debugPrint('Delivery charges: $deliveryCharges');
      final double orderTotal = originalPrice - discountValue + deliveryCharges;

      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeManager.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.white.withOpacity(0.3),
            width: 0.86,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payment Information",
              style: interBold.copyWith(
                fontSize: Dimensions.fontSizeExtraLarge,
                fontWeight: FontWeight.w600,
                color: ThemeManager.black,
              ),
            ),
            const SizedBox(height: 16),

            // List individual plans if available
            if (plans.isNotEmpty) ...[
              ...plans.map((plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildRow(plan['name'] ?? "Subscription Plan",
                        "₹${plan['price'] ?? 0}"),
                  )),
            ],

            // List individual books if available
            if (books.isNotEmpty) ...[
              ...books.map((book) {
                int bookId = int.tryParse(book['id'].toString()) ?? 0;
                int qty = bookQuantities[bookId] ?? 1;
                double price = double.tryParse(book['price'].toString()) ?? 0.0;
                double totalBookPrice = price * qty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildRow("Book: ${book['name'] ?? 'Hardcopy Book'}",
                      "₹${totalBookPrice.toInt()}"),
                );
              }),
              // Add divider only if there are plans or books
              if (plans.isNotEmpty || books.isNotEmpty)
                const Divider(height: 16, thickness: 1),
            ],

            _buildRow("Subtotal", "₹$originalPrice"),

            // Show coupon discount if applied
            if (_store.appliedCoupon != null && _store.discountAmount > 0) ...[
              const SizedBox(height: 8),
              _buildRow(
                "Coupon Discount (${_store.appliedCoupon!.code ?? 'APPLIED'})",
                "-₹${_store.discountAmount.toStringAsFixed(2)}",
                color: Colors.green.shade700,
              ),
            ]
            // Show offer discount if applied
            else if (_store.appliedOffer != null &&
                _store.discountAmount > 0) ...[
              const SizedBox(height: 8),
              _buildRow(
                "Offer Discount (${_store.appliedOffer!.title ?? 'APPLIED'})",
                "-₹${_store.discountAmount.toStringAsFixed(2)}",
                color: Colors.green.shade700,
              ),
            ]
            // Show default discount if no coupon or offer
            else if (discountValue > 0) ...[
              const SizedBox(height: 8),
              _buildRow("Discount", "-₹${discountValue.toStringAsFixed(2)}",
                  color: Colors.grey.shade700),
            ],

            // Show delivery charges if a delivery service is selected
            if (_store.selectedDeliveryService != null) ...[
              const SizedBox(height: 8),
              _buildRow(
                "Delivery Charges (${_store.selectedDeliveryService!.courierName})",
                "₹${deliveryCharges.toStringAsFixed(2)}",
                color: AppColors.blueFinal,
              ),
            ],

            const SizedBox(height: 8),
            _buildRow("Order Total", "₹${orderTotal.toStringAsFixed(2)}",
                isBold: true),
            const SizedBox(height: 24),

            Center(
              child: SizedBox(
                height: 40,
                width: 280,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueFinal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _startPayment,
                  // onPressed: _startPayment2,
                  child: Text(
                    "Make Payment",
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      fontWeight: FontWeight.w400,
                      color: ThemeManager.white,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      );
    });
  }

  Widget _buildRow(String label, String value,
      {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: interRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isBold ? ThemeManager.black : AppColors.grey4,
          ),
        ),
        Text(
          value,
          style: interRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isBold ? ThemeManager.black : AppColors.grey4,
          ),
        ),
      ],
    );
  }

  void _showAddressDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeManager.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Delivery Address',
                style: interBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: ThemeManager.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildAddressDetailRow('Name', _store.selectedAddress!['name']),
              _buildAddressDetailRow(
                  'Phone', '+91 ${_store.selectedAddress!['phone']}'),
              if (_store.selectedAddress!['email'] != null)
                _buildAddressDetailRow(
                    'Email', _store.selectedAddress!['email']),
              _buildAddressDetailRow(
                  'Address', _store.selectedAddress!['address']),
              if (_store.selectedAddress!['buildingNumber'] != null &&
                  _store.selectedAddress!['buildingNumber']
                      .toString()
                      .isNotEmpty)
                _buildAddressDetailRow(
                    'Building', _store.selectedAddress!['buildingNumber']),
              _buildAddressDetailRow('City', _store.selectedAddress!['City']),
              _buildAddressDetailRow('State', _store.selectedAddress!['State']),
              _buildAddressDetailRow(
                  'Pincode', _store.selectedAddress!['Pincode'].toString()),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueFinal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    showCheckDeliveryBottomSheet(context);
                  },
                  child: Text(
                    "Change Address",
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      fontWeight: FontWeight.w400,
                      color: ThemeManager.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddressDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title + ":",
              style: interMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: AppColors.grey4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: interRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: ThemeManager.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    String formattedAddress = "${address['name']}";

    // Add the address line
    if (address['address'] != null &&
        address['address'].toString().isNotEmpty) {
      formattedAddress += "\n${address['address']}";

      // Add building/apartment if available
      if (address['buildingNumber'] != null &&
          address['buildingNumber'].toString().isNotEmpty) {
        formattedAddress += ", ${address['buildingNumber']}";
      }
    }

    // Add city, state and pincode
    String locationPart = "";
    if (address['City'] != null && address['City'].toString().isNotEmpty) {
      locationPart += address['City'];
    }

    if (address['State'] != null && address['State'].toString().isNotEmpty) {
      if (locationPart.isNotEmpty) locationPart += ", ";
      locationPart += address['State'];
    }

    if (address['Pincode'] != null) {
      if (locationPart.isNotEmpty) locationPart += " - ";
      locationPart += address['Pincode'].toString();
    }

    if (locationPart.isNotEmpty) {
      formattedAddress += "\n$locationPart";
    }

    return formattedAddress;
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    bool isWide =
        ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isTab(context);
    final originalPrice = book['originalPrice'] != null
        ? double.tryParse(book['originalPrice'].toString())
        : null;
    final price = double.tryParse(book['price'].toString()) ?? 0.0;
    int bookId = int.tryParse(book['id'].toString()) ?? 0;
    final int quantity = bookQuantities[bookId] ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: ThemeManager.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white.withOpacity(0.3),
          width: 0.86,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            child: book['imageUrl'] != null &&
                    book['imageUrl'].toString().isNotEmpty
                ? Image.network(
                    book['imageUrl'],
                    width: isWide ? 100 : 120,
                    height: isWide ? 110 : 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: isWide ? 100 : 120,
                      height: isWide ? 110 : 110,
                      color: Colors.grey[300],
                      child:
                          const Icon(Icons.book, size: 40, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: isWide ? 100 : 120,
                    height: isWide ? 110 : 110,
                    color: Colors.grey[300],
                    child: Image.asset("assets/image/bookCover.png",
                      fit: BoxFit.fitWidth,
                      width: 180,
                      height: 120,),
                    // const Icon(Icons.book, size: 40, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),

          /// Main Content Column with Expanded to prevent overflow
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 5, right: 15, top: 10, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['name'] ?? "Unknown Book",
                    style: interMedium.copyWith(
                      fontSize: isWide
                          ? Dimensions.fontSizeDefault
                          : Dimensions.fontSizeDefault,
                      color: ThemeManager.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book['type'] ?? "Hardcopy Book",
                    style: interRegular.copyWith(
                      fontSize: isWide
                          ? Dimensions.fontSizeSmall
                          : Dimensions.fontSizeSmall,
                      color: AppColors.grey4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cart-style quantity selector
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.blueFinal,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if ((bookQuantities[bookId] ?? 1) > 1) {
                                    bookQuantities[bookId] =
                                        (bookQuantities[bookId] ?? 1) - 1;
                                    _recalculateDiscountIfNeeded();
                                  }
                                });
                              },
                              child: Text(
                                '-',
                                style: interBold.copyWith(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$quantity',
                              style: interBold.copyWith(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  bookQuantities[bookId] =
                                      (bookQuantities[bookId] ?? 1) + 1;
                                  _recalculateDiscountIfNeeded();
                                });
                              },
                              child: Text(
                                '+',
                                style: interBold.copyWith(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Price
                      Flexible(
                        child: RichText(
                          textAlign: TextAlign.end,
                          text: TextSpan(
                            children: [
                              if (originalPrice != null &&
                                  originalPrice > price)
                                TextSpan(
                                  text: '₹${originalPrice.toInt()}  ',
                                  style: interRegular.copyWith(
                                    fontSize: 14,
                                    color: AppColors.grey4,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              TextSpan(
                                text: "₹${price.toInt()}",
                                style: interBold.copyWith(
                                  fontSize: 16,
                                  color: AppColors.blueFinal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startPayment() async {
    // Load remote settings to decide how to proceed on desktop/mobile
    final loginStore = Provider.of<LoginStore>(context, listen: false);
    if (loginStore.settingsData.value == null) {
      await loginStore.onGetSettingsData();
    }
    final bool isIAPEnabled = loginStore.settingsData.value?.isInAPurchases == true;
    
    debugPrint('In-App Purchases enabled: $isIAPEnabled');

    // If platform is macOS or Windows and remote In-App Purchases are
    // disabled, show the subscription dialog prompting users to use the
    // mobile app for subscriptions (existing mobile app popup dialog).
    if ((Platform.isMacOS || Platform.isWindows) && !isIAPEnabled) {
      await showDialog(
        context: context,
        builder: (context) => SubscriptionDialog(),
      );
      return;
    }

    // iOS/macOS: if remote settings enable Apple IAP, use Apple flow for
    // subscription-only carts. If Apple IAP is disabled on iOS, fall through
    // and allow the normal Razorpay/web flow (so subscriptions can be
    // processed via the gateway on iOS when IAP is turned off).
    if (Platform.isIOS || Platform.isMacOS) {
      if (isIAPEnabled) {
        if (plans.isNotEmpty && books.isEmpty) {
          await _startAppleSubscriptionPurchase();
          return;
        } else if (books.isNotEmpty) {
          _showApplePurchaseError('Book purchases cannot be completed using Apple In-App Purchase on iOS/macOS. Please remove books from the cart or purchase on a supported platform.');
          return;
        }
      }
    }
    // Get delivery charges if a delivery service is selected
    final double deliveryCharges = _store.selectedDeliveryService != null
        ? _store.selectedDeliveryService!.rate
        : 0.0;

    // Calculate final amount including delivery charges
    final double finalAmount =
        totalPrice.toDouble() - _store.discountAmount + deliveryCharges;

    // Get payment details from store
    await _subscriptionStore.onGetPaymentDetails(context);

    // Get API keys from store
    String apiKey = _subscriptionStore.paymentDetails.value?.razorpayKey ?? "";
    String apiSecret =
        _subscriptionStore.paymentDetails.value?.razorpaySecretKey ?? "";

    // String apiKey = 'rzp_test_mV7hVxiuC3ljvo';
    // String apiSecret = 'sFN1bvTqaGVSPpA2kVfTk2q5';

    debugPrint('razorapikey$apiKey');
    debugPrint('razorapikey$apiSecret');  

    if (apiKey.isEmpty || apiSecret.isEmpty) {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Payment configuration error. Please try again later.",
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    Map<String, dynamic> paymentData = {
      'amount': (finalAmount * 100).toInt(), // Convert to paise
      'currency': 'INR',
      'receipt': 'order_receipt',
      'payment_capture': '1',
    };

    String apiUrl = 'https://api.razorpay.com/v1/orders';
    http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$apiKey:$apiSecret'))}',
      },
      body: jsonEncode(paymentData),
    );

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      if (Platform.isWindows) {
        // For desktop platforms, use web payment
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PaymentPage(
              apiKey: apiKey,
              orderId: responseData['id'],
            ),
          ),
        );
      } else {
        // For mobile platforms, use native Razorpay SDK
        RazorpayPayment.openCheckout(
          apiKey: apiKey,
          amount: paymentData['amount'],
          orderId: responseData['id'],
        );
      }
    } else {
      debugPrint('Error creating order: ${response.body}');
      // Show error message to user
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Payment failed: ${response.body}",
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<void> _startPayment2() async {
    // Get delivery charges if a delivery service is selected
    final double deliveryCharges = _store.selectedDeliveryService != null
        ? _store.selectedDeliveryService!.rate
        : 0.0;

    // Calculate final amount including delivery charges and convert to integer
    final int finalAmount =
        (totalPrice.toDouble() - _store.discountAmount + deliveryCharges)
            .round();

    try {
      if (plans.isNotEmpty && books.isEmpty) {
        final List<Map<String, dynamic>> orderRequests = plans.map((plan) {
          // Calculate the discount amount for this plan
          double planDiscountAmount = 0;
          if (_store.appliedOffer != null &&
              _store.appliedOffer!.isPercentage == true) {
            // If it's a percentage discount, calculate based on the plan's price
            planDiscountAmount = plan['price'] *
                (_store.appliedOffer!.discountPercentage! / 100);
          } else {
            // If it's a fixed discount, distribute it equally among plans
            planDiscountAmount = _store.discountAmount / plans.length;
          }

          Map<String, dynamic> orderRequest = {
            "plan_id": plan['id'],
            "amount": plan['price'],
            "discountPrice": planDiscountAmount,
            "day": int.parse(plan['day'].toString()),
            "duration_id": plan['durationId'],
            "razorpay_payment_id": "123214",
            "razorpay_order_id": "123214",
            "razorpay_signature": "123214",
            "coupon_id": _store.appliedCoupon?.id ?? "",
          };

          // Add upgrade parameters if this is an upgrade flow
          if (widget.isUpgrade && widget.subscriptionId != null) {
            orderRequest["isUpgrade"] = true;
            orderRequest["subscriptionId"] = widget.subscriptionId;
          }

          return orderRequest;
        }).toList();

        await _subscriptionStore
            .onPurchaseMultipleSubscriptionPlans(orderRequests);
      } else if (books.isNotEmpty && plans.isEmpty) {
        if (_store.selectedAddress == null ||
            _store.selectedDeliveryService == null) {
          throw Exception("Delivery address or courier service not selected");
        }

        final List<Map<String, dynamic>> bookOrderRequest = books.map((book) {
          // Calculate the discount amount for this book
          double bookDiscountAmount = 0;
          if (_store.appliedOffer != null &&
              _store.appliedOffer!.isPercentage == true) {
            // If it's a percentage discount, calculate based on the book's price and current quantity
            int bookId = int.tryParse(book['id'].toString()) ?? 0;
            int qty = bookQuantities[bookId] ?? 1;
            double price = double.tryParse(book['price'].toString()) ?? 0.0;
            bookDiscountAmount =
                price * qty * (_store.appliedOffer!.discountPercentage! / 100);
          } else {
            // If it's a fixed discount, distribute it equally among books
            bookDiscountAmount = _store.discountAmount / books.length;
          }

          int bookId = int.tryParse(book['id'].toString()) ?? 0;
          int qty = bookQuantities[bookId] ?? 1;
          double price = double.tryParse(book['price'].toString()) ?? 0.0;
          double totalBookPrice = price * qty;
          return {
            "Book_id": book['id'],
            "Address_id": _store.selectedAddress!['_id'],
            "Price": totalBookPrice,
            "discountPrice": bookDiscountAmount,
            "courier_id": _store.selectedDeliveryService!.courier_id.toString(),
            "courier_name": _store.selectedDeliveryService!.courierName,
            "deliveryCharge": _store.selectedDeliveryService!.rate,
            "order_items": [
              {
                "name": book['name'],
                "sku": book['sku'] ?? "BOOK${book['id']}",
                "units": qty,
                "selling_price": price
              }
            ]
          };
        }).toList();

        await _subscriptionStore.onPurchaseBooks(bookOrderRequest);
      } else if (plans.isNotEmpty && books.isNotEmpty) {
        if (_store.selectedAddress == null ||
            _store.selectedDeliveryService == null) {
          throw Exception("Delivery address or courier service not selected");
        }

        final List<Map<String, dynamic>> orderRequests = plans.map((plan) {
          // Calculate the discount amount for this plan
          double planDiscountAmount = 0;
          if (_store.appliedOffer != null &&
              _store.appliedOffer!.isPercentage == true) {
            // If it's a percentage discount, calculate based on the plan's price
            planDiscountAmount = plan['price'] *
                (_store.appliedOffer!.discountPercentage! / 100);
          } else {
            // If it's a fixed discount, distribute it equally among plans
            planDiscountAmount = _store.discountAmount / plans.length;
          }

          Map<String, dynamic> orderRequest = {
            "plan_id": plan['id'],
            "amount": plan['price'],
            "discountPrice": planDiscountAmount,
            "day": int.parse(plan['day'].toString()),
            "duration_id": plan['durationId'],
            "razorpay_payment_id": "123214",
            "razorpay_order_id": "123214",
            "razorpay_signature": "123214",
            "coupon_id": _store.appliedCoupon?.id ?? "",
          };

          // Add upgrade parameters if this is an upgrade flow
          if (widget.isUpgrade && widget.subscriptionId != null) {
            orderRequest["isUpgrade"] = true;
            orderRequest["subscriptionId"] = widget.subscriptionId;
          }

          return orderRequest;
        }).toList();

        await _subscriptionStore
            .onPurchaseMultipleSubscriptionPlans(orderRequests);

        final List<Map<String, dynamic>> bookOrderRequest = books.map((book) {
          // Calculate the discount amount for this book
          double bookDiscountAmount = 0;
          if (_store.appliedOffer != null &&
              _store.appliedOffer!.isPercentage == true) {
            // If it's a percentage discount, calculate based on the book's price and current quantity
            int bookId = int.tryParse(book['id'].toString()) ?? 0;
            int qty = bookQuantities[bookId] ?? 1;
            double price = double.tryParse(book['price'].toString()) ?? 0.0;
            bookDiscountAmount =
                price * qty * (_store.appliedOffer!.discountPercentage! / 100);
          } else {
            // If it's a fixed discount, distribute it equally among books
            bookDiscountAmount = _store.discountAmount / books.length;
          }

          int bookId = int.tryParse(book['id'].toString()) ?? 0;
          int qty = bookQuantities[bookId] ?? 1;
          double price = double.tryParse(book['price'].toString()) ?? 0.0;
          double totalBookPrice = price * qty;
          return {
            "Book_id": book['id'],
            "Address_id": _store.selectedAddress!['_id'],
            "Price": totalBookPrice,
            "discountPrice": bookDiscountAmount,
            "courier_id": _store.selectedDeliveryService!.courier_id.toString(),
            "courier_name": _store.selectedDeliveryService!.courierName,
            "deliveryCharge": _store.selectedDeliveryService!.rate,
            "order_items": [
              {
                "name": book['name'],
                "sku": book['sku'] ?? "BOOK${book['id']}",
                "units": qty,
                "selling_price": price
              }
            ]
          };
        }).toList();

        await _subscriptionStore.onPurchaseBooks(bookOrderRequest);
      }

      // Navigate to success screen
      Navigator.of(context).pushNamed(
        Routes.newPaymentSuccess,
        arguments: {
          'amount': finalAmount.toString(),
          'dateTime': DateTime.now(),
          'paymentId': "123214",
          'planName': plans.isNotEmpty
              ? (plans.length > 1
                  ? "${plans[0]['name']} + ${plans.length - 1} more"
                  : plans[0]['name'])
              : books.isNotEmpty
                  ? "Hardcopy Books"
                  : 'First Plan',
          'hardcopyBookName': books.isNotEmpty ? books[0]['name'] : null,
        },
      );
    } catch (e) {
      debugPrint('Error processing order: $e');
      String errorMsg = e
              .toString()
              .contains('Delivery address or courier service not selected')
          ? 'Delivery address or courier service not selected'
          : e.toString();
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: errorMsg,
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Get delivery charges if a delivery service is selected
    final double deliveryCharges = _store.selectedDeliveryService != null
        ? _store.selectedDeliveryService!.rate
        : 0.0;

    // Calculate final amount including delivery charges and convert to integer
    final int finalAmount =
        (totalPrice.toDouble() - _store.discountAmount + deliveryCharges)
            .round();

    try {
      // Case 1: Only subscription plans purchased
      if (plans.isNotEmpty && books.isEmpty) {
        final List<Map<String, dynamic>> orderRequests = plans.map((plan) {
          // Calculate the discount amount for this plan
          double planDiscountAmount = 0;
          if (_store.appliedOffer != null &&
              _store.appliedOffer!.isPercentage == true) {
            // If it's a percentage discount, calculate based on the plan's price
            planDiscountAmount = plan['price'] *
                (_store.appliedOffer!.discountPercentage! / 100);
          } else {
            // If it's a fixed discount, distribute it equally among plans
            planDiscountAmount = _store.discountAmount / plans.length;
          }

          Map<String, dynamic> orderRequest = {
            "plan_id": plan['id'],
            "amount": plan['price'],
            "discountPrice": planDiscountAmount,
            "day": int.parse(plan['day'].toString()),
            "duration_id": plan['durationId'],
            "razorpay_payment_id": response.paymentId,
            "razorpay_order_id": response.orderId,
            "razorpay_signature": response.signature,
            "coupon_id": _store.appliedCoupon?.id ?? "",
          };

          // Add upgrade parameters if this is an upgrade flow
          if (widget.isUpgrade && widget.subscriptionId != null) {
            orderRequest["isUpgrade"] = true;
            orderRequest["order_id"] = widget.subscriptionId;
          }

          return orderRequest;
        }).toList();

        await _subscriptionStore
            .onPurchaseMultipleSubscriptionPlans(orderRequests);
      }

      // Case 2: Only books purchased
      else if (books.isNotEmpty && plans.isEmpty) {
        if (_store.selectedAddress == null ||
            _store.selectedDeliveryService == null) {
          throw Exception("Delivery address or courier service not selected");
        }

        // Format the book order request according to the API format
        final List<Map<String, dynamic>> bookOrderRequest = books.map((book) {
          // Calculate the discount amount for this book
          double bookDiscountAmount = 0;
          if (_store.appliedOffer != null &&
              _store.appliedOffer!.isPercentage == true) {
            // If it's a percentage discount, calculate based on the book's price and current quantity
            int bookId = int.tryParse(book['id'].toString()) ?? 0;
            int qty = bookQuantities[bookId] ?? 1;
            double price = double.tryParse(book['price'].toString()) ?? 0.0;
            bookDiscountAmount =
                price * qty * (_store.appliedOffer!.discountPercentage! / 100);
          } else {
            // If it's a fixed discount, distribute it equally among books
            bookDiscountAmount = _store.discountAmount / books.length;
          }

          int bookId = int.tryParse(book['id'].toString()) ?? 0;
          int qty = bookQuantities[bookId] ?? 1;
          double price = double.tryParse(book['price'].toString()) ?? 0.0;
          double totalBookPrice = price * qty;
          return {
            "Book_id": book['id'],
            "Address_id": _store.selectedAddress!['_id'],
            "Price": totalBookPrice,
            "discountPrice":
                bookDiscountAmount, // Pass the calculated discount amount
            "courier_id": _store.selectedDeliveryService!.courier_id.toString(),
            "courier_name": _store.selectedDeliveryService!.courierName,
            "deliveryCharge": _store.selectedDeliveryService!.rate,
            "order_items": [
              {
                "name": book['name'],
                "sku": book['sku'] ?? "BOOK${book['id']}",
                "units": qty,
                "selling_price": price
              }
            ]
          };
        }).toList();

        await _subscriptionStore.onPurchaseBooks(bookOrderRequest);
      }

      // Case 3: Both subscription plans and books purchased
      else if (plans.isNotEmpty && books.isNotEmpty) {
        if (_store.selectedAddress == null ||
            _store.selectedDeliveryService == null) {
          throw Exception("Delivery address or courier service not selected");
        }

        // First create subscription orders
        final List<Map<String, dynamic>> subscriptionRequests =
            plans.map((plan) {
          // Calculate the discount amount for this plan
          double planDiscountAmount = 0;
          if (_store.appliedOffer != null &&
              _store.appliedOffer!.isPercentage == true) {
            // If it's a percentage discount, calculate based on the plan's price
            planDiscountAmount = plan['price'] *
                (_store.appliedOffer!.discountPercentage! / 100);
          } else {
            // If it's a fixed discount, distribute it equally among plans
            planDiscountAmount = _store.discountAmount / plans.length;
          }

          Map<String, dynamic> orderRequest = {
            "plan_id": plan['id'],
            "amount": plan['price'],
            "discountPrice":
                planDiscountAmount, // Pass the calculated discount amount
            "day": int.parse(plan['day'].toString()),
            "duration_id": plan['durationId'],
            "razorpay_payment_id": response.paymentId,
            "razorpay_order_id": response.orderId,
            "razorpay_signature": response.signature,
            "coupon_id": _store.appliedCoupon?.id ?? "",
          };

          // Add upgrade parameters if this is an upgrade flow
          if (widget.isUpgrade && widget.subscriptionId != null) {
            orderRequest["isUpgrade"] = true;
            orderRequest["order_id"] = widget.subscriptionId;
          }

          return orderRequest;
        }).toList();

        await _subscriptionStore
            .onPurchaseMultipleSubscriptionPlans(subscriptionRequests);

        // Then create book order
        final List<Map<String, dynamic>> bookOrderRequest = books.map((book) {
          // Calculate the discount amount for this book
          double bookDiscountAmount = 0;
          if (_store.appliedOffer != null &&
              _store.appliedOffer!.isPercentage == true) {
            // If it's a percentage discount, calculate based on the book's price and current quantity
            int bookId = int.tryParse(book['id'].toString()) ?? 0;
            int qty = bookQuantities[bookId] ?? 1;
            double price = double.tryParse(book['price'].toString()) ?? 0.0;
            bookDiscountAmount =
                price * qty * (_store.appliedOffer!.discountPercentage! / 100);
          } else {
            // If it's a fixed discount, distribute it equally among books
            bookDiscountAmount = _store.discountAmount / books.length;
          }

          int bookId = int.tryParse(book['id'].toString()) ?? 0;
          int qty = bookQuantities[bookId] ?? 1;
          double price = double.tryParse(book['price'].toString()) ?? 0.0;
          double totalBookPrice = price * qty;
          return {
            "Book_id": book['id'],
            "Address_id": _store.selectedAddress!['_id'],
            "Price": totalBookPrice,
            "discountPrice": bookDiscountAmount, // Pass the calculated discount amount
            "courier_id": _store.selectedDeliveryService!.courier_id.toString(),
            "courier_name": _store.selectedDeliveryService!.courierName,
            "deliveryCharge": _store.selectedDeliveryService!.rate,
            "order_items": [
              {
                "name": book['name'],
                "sku": book['sku'] ?? "BOOK${book['id']}",
                "units": qty,
                "selling_price": price
              }
            ]
          };
        }).toList();

        await _subscriptionStore.onPurchaseBooks(bookOrderRequest);
      }

      // Navigate to success screen
      Navigator.of(context).pushNamed(
        Routes.newPaymentSuccess,
        arguments: {
          'amount': finalAmount.toString(),
          'dateTime': DateTime.now(),
          'paymentId': response.paymentId,
          'planName': plans.isNotEmpty
              ? (plans.length > 1
                  ? "${plans[0]['name']} + ${plans.length - 1} more"
                  : plans[0]['name'])
              : books.isNotEmpty
                  ? "Hardcopy Books"
                  : 'First Plan',
          'hardcopyBookName': books.isNotEmpty ? books[0]['name'] : null,
        },
      );
    } catch (e) {
      debugPrint('Error processing order: $e');
      String errorMsg = e
              .toString()
              .contains('Delivery address or courier service not selected')
          ? 'Delivery address or courier service not selected'
          : e.toString();
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: errorMsg,
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    // Navigate to failure screen
    Navigator.of(context).pushNamed(
      Routes.paymentFailed,
      arguments: {
        'amount': totalPrice,
        'dateTime': DateTime.now(),
      },
    );
  }

  // ===== Apple In-App Purchase helpers (iOS/macOS) =====
  Future<void> _startAppleSubscriptionPurchase() async {
    try {
      final bool available = await AppleInAppPurchase.initialize();
      if (!available) {
        _showApplePurchaseError('In-App Purchases are not available. Please try again later.');
        return;
      }
      if (plans.isEmpty) {
        _showApplePurchaseError('No subscription plan selected.');
        return;
      }
      final Map<String, dynamic> plan = plans.first;
      final String productId = _getProductIdForPlan(plan);
      final products = AppleInAppPurchase.products;
      final matching = products.where((p) => p.id == productId).toList();
      if (matching.isEmpty) {
        _showApplePurchaseError('Product not found for id: $productId');
        return;
      }
      final product = matching.first;
      final started = await AppleInAppPurchase.purchaseProduct(
        product,
        onSuccess: (purchaseDetails) async {
          await _handleApplePurchaseSuccess(purchaseDetails);
        },
        onError: (message) {
          _showApplePurchaseError('Purchase failed: $message');
        },
      );
      if (!started) {
        _showApplePurchaseError('Unable to start purchase. Please try again.');
      }
    } catch (e) {
      debugPrint('Error in Apple IAP purchase: $e');
      _showApplePurchaseError('Purchase failed to start. Please try again later.');
    }
  }

  String _getProductIdForPlan(Map<String, dynamic> plan) {
    // Return the actual product ID from App Store Connect
    if (Platform.isIOS) {
      return '6751168008'; // iOS product ID
    } else if (Platform.isMacOS) {
      return '6751168007'; // macOS product ID
    }
    return '6751168007'; // fallback
  }

  void _showApplePurchaseError(String message) {
    // showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: const Text('Purchase Unavailable'),
    //     content: Text(message),
    //     actions: [
    //       TextButton(
    //         onPressed: () => Navigator.pop(context),
    //         child: const Text('OK'),
    //       ),
    //     ],
    //   ),
    // );
  }

  Future<void> _handleApplePurchaseSuccess(PurchaseDetails details) async {
    try {
      // Only subscriptions are supported for Apple IAP in this flow
      if (plans.isNotEmpty && books.isEmpty) {
        // Create Apple IAP subscription orders for each plan
        for (final plan in plans) {
          await _subscriptionStore.onCreateAppleInAppPurchaseOrder(
            planId: plan['id'],
            amount: plan['price'],
            day: int.parse(plan['day'].toString()),
            durationId: plan['durationId'],
          );
        }

        // Compute final amount similar to other payment success flows
        final double deliveryCharges = _store.selectedDeliveryService != null
            ? _store.selectedDeliveryService!.rate
            : 0.0;
        final int finalAmount = (totalPrice.toDouble() - _store.discountAmount + deliveryCharges).round();

        Navigator.of(context).pushNamed(
          Routes.newPaymentSuccess,
          arguments: {
            'amount': finalAmount.toString(),
            'dateTime': DateTime.now(),
            'paymentId': details.purchaseID ?? details.productID,
            'planName': plans.isNotEmpty
                ? (plans.length > 1
                    ? "${plans[0]['name']} + ${plans.length - 1} more"
                    : plans[0]['name'])
                : 'First Plan',
            'hardcopyBookName': null,
          },
        );
      } else {
        _showApplePurchaseError('Unsupported cart for Apple In-App Purchase.');
      }
    } catch (e) {
      debugPrint('Error processing Apple in-app purchase: $e');
      _showApplePurchaseError('Unable to complete purchase. Please contact support.');
    }
  }

  // Function to recalculate discount when book quantities change
  void _recalculateDiscountIfNeeded() {
    // Only recalculate if a percentage-based offer is applied
    if (_store.appliedOffer != null &&
        _store.appliedOffer!.isPercentage == true) {
      // First make sure we have the right offer object
      final offer = _store.appliedOffer!;

      // For percentage-based discounts, recalculate based on current total price
      double basePrice = 0.0;

      // Add prices from plans
      if (plans.isNotEmpty) {
        for (var plan in plans) {
          if (plan.containsKey('price')) {
            basePrice += double.tryParse(plan['price'].toString()) ?? 0.0;
          }
        }
      }

      // Add prices from books with CURRENT quantities
      if (books.isNotEmpty) {
        for (var book in books) {
          if (book.containsKey('price')) {
            int bookId = int.tryParse(book['id'].toString()) ?? 0;
            int qty = bookQuantities[bookId] ?? 1;
            double price = double.tryParse(book['price'].toString()) ?? 0.0;
            basePrice += price * qty;
          }
        }
      }

      // Calculate percentage discount
      final percentage = offer.discountPercentage ?? 0.0;
      _store.discountAmount = (basePrice * percentage / 100);
      debugPrint(
          'Recalculated percentage discount: $percentage% of $basePrice = ${_store.discountAmount}');
    }
  }

  // Calculate max dimensions of all books
  Map<String, double> _calculateMaxBookDimensions() {
    double maxHeight = 0.0;
    double maxWidth = 0.0;
    double maxLength = 0.0;
    double totalWeight = 0.0;

    // If no books, return default values
    if (books.isEmpty) {
      return {
        'height': _defaultBookHeight,
        'width': _defaultBookWidth,
        'length': _defaultBookLength,
        'weight': _bookWeight,
      };
    }

    for (var book in books) {
      int bookId = int.tryParse(book['id'].toString()) ?? 0;
      int qty = bookQuantities[bookId] ?? 1;

      // Get dimensions from book data or use defaults
      double height = double.tryParse(book['height']?.toString() ?? '') ??
          _defaultBookHeight;
      double width =
          double.tryParse(book['width']?.toString() ?? '') ?? _defaultBookWidth;
      double length = double.tryParse(book['length']?.toString() ?? '') ??
          _defaultBookLength;
      double weight =
          double.tryParse(book['weight']?.toString() ?? '') ?? _bookWeight;

      // Update maximums
      if (height > maxHeight) maxHeight = height;
      if (width > maxWidth) maxWidth = width;
      if (length > maxLength) maxLength = length;

      // Sum up weight for all books
      totalWeight += weight * qty;
    }

    return {
      'height': maxHeight,
      'width': maxWidth,
      'length': maxLength,
      'weight': totalWeight,
    };
  }

  // Method to check serviceability with book dimensions
  Future<void> _checkServiceabilityWithDimensions(String pincode) async {
    try {
      // Calculate book dimensions
      final dimensions = _calculateMaxBookDimensions();

      // Update query parameters for the API
      const baseUrl = '/checkServiceability';
      final queryParams = {
        'delivery_postcode': pincode,
        'weight': (dimensions['weight'] ?? _bookWeight).toString(),
      };

      // Add dimensions when available
      if (dimensions.containsKey('height')) {
        queryParams['height'] = dimensions['height'].toString();
      }
      if (dimensions.containsKey('width')) {
        queryParams['width'] = dimensions['width'].toString();
        // Use width as breadth if not specified
        queryParams['breadth'] = dimensions['width'].toString();
      }
      if (dimensions.containsKey('length')) {
        queryParams['length'] = dimensions['length'].toString();
      }

      // Save the dimensions to the store
      _store.bookDimensions.clear();
      dimensions.forEach((key, value) {
        _store.bookDimensions[key] = value;
      });

      // Set the pincode in the store
      _store.setPincode(pincode);

      // Call the standard serviceability check for now
      await _store.checkServiceability(
          pincode, dimensions['weight'] ?? _bookWeight);

      if (_store.deliveryServices.isNotEmpty) {
        navigateToSelectDeliveryType(context);
      }
    } catch (e) {
      debugPrint('Error checking serviceability: $e');
    }
  }
}
