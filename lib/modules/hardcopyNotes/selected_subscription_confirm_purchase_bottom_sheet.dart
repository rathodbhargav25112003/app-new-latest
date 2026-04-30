// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/modules/subscriptionplans/web_payment_page.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/subscription_model.dart';
import '../subscriptionplans/model/get_address_model.dart';
import '../subscriptionplans/razorpay_payment.dart';
import '../subscriptionplans/store/subscription_store.dart';

/// Confirm-purchase bottom sheet for a subscription + hardcopy-books bundle
/// — redesigned with AppTokens. Keeps the full 11-field constructor,
/// Razorpay initialize/dispose lifecycle, SharedPreferences login check,
/// `_getUniqueBooks`, `_startPayment`, `_handlePaymentSuccess`, and
/// `_handlePaymentFailure` with all navigation side-effects
/// (Routes.paymentStatus / Routes.paymentFailed / Routes.login and the
/// PaymentPage web fallback on Windows/macOS).
class ConfirmSubscriptionAndHardCopyPurchaseBottomSheet extends StatefulWidget {
  final num totalAmount;
  final int subTotalAmount;
  final List<Map<String, dynamic>> selectedBooks;
  final SubscriptionModel subscription;
  final SubscriptionStore store;
  final String selectedPlanMonth;
  final String durationId;
  final String offerId;
  final String couponId;
  final bool isSingleUse;
  final GetAddressModel? address;

  const ConfirmSubscriptionAndHardCopyPurchaseBottomSheet({
    super.key,
    required this.totalAmount,
    required this.selectedBooks,
    required this.address,
    required this.store,
    required this.subscription,
    required this.selectedPlanMonth,
    required this.durationId,
    required this.subTotalAmount,
    required this.offerId,
    required this.couponId,
    required this.isSingleUse,
  });

  @override
  State<ConfirmSubscriptionAndHardCopyPurchaseBottomSheet> createState() =>
      _ConfirmSubscriptionAndHardCopyPurchaseBottomSheetState();
}

class _ConfirmSubscriptionAndHardCopyPurchaseBottomSheetState
    extends State<ConfirmSubscriptionAndHardCopyPurchaseBottomSheet> {
  Future<bool>? isLogged;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    RazorpayPayment.initialize(_handlePaymentSuccess, _handlePaymentFailure);
    isLogged = _checkIsLoggedIn();
    isLogged!.then((value) {
      setState(() {
        loggedIn = value;
      });
    });
  }

  Future<bool> _checkIsLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? loggedInEmail = prefs.getBool('isloggedInEmail');
    bool? signInGoogle = prefs.getBool('isSignInGoogle');
    bool? loggedInWt = prefs.getBool('isLoggedInWt');
    if (loggedInEmail == true || signInGoogle == true || loggedInWt == true) {
      return loggedIn = true;
    } else {
      return loggedIn = false;
    }
  }

  List<Map<String, dynamic>> _getUniqueBooks(List<Map<String, dynamic>> books) {
    Map<String, Map<String, dynamic>> uniqueBooksMap = {};

    for (var book in books) {
      String bookId = book['bookId'];
      if (uniqueBooksMap.containsKey(bookId)) {
        uniqueBooksMap[bookId]!['quantity'] =
            uniqueBooksMap[bookId]!['quantity'] + 1;
      } else {
        book['quantity'] = 1;
        uniqueBooksMap[bookId] = book;
      }
    }

    return uniqueBooksMap.values.toList();
  }

  @override
  void dispose() {
    RazorpayPayment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> uniqueBooks =
        _getUniqueBooks(widget.selectedBooks);
    final address = widget.address;
    final addressLine = [
      address?.buildingNumber,
      address?.landMark,
      address?.city,
      address?.state,
      address?.pincode,
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(", ");

    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTokens.r28),
          topRight: Radius.circular(AppTokens.r28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppTokens.s12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTokens.borderStrong(context),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Text(
            'Confirm Your Purchase',
            style: AppTokens.titleLg(context),
          ),
          const SizedBox(height: AppTokens.s16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                0,
                AppTokens.s16,
                AppTokens.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(text: 'Order details'),
                  const SizedBox(height: AppTokens.s12),
                  _OrderRow(
                    label: widget.subscription.plan_name ?? '',
                    amount: "₹ ${widget.subTotalAmount}",
                  ),
                  ...uniqueBooks.map((book) {
                    final qty = book['quantity'] as int;
                    final price = (book['price'] as num).toInt();
                    return Padding(
                      padding: const EdgeInsets.only(top: AppTokens.s8),
                      child: _OrderRow(
                        label: book['bookName'] as String,
                        amount: "₹ ${price * qty}",
                        qtyLabel: qty > 1 ? "× $qty" : null,
                      ),
                    );
                  }),
                  const SizedBox(height: AppTokens.s24),
                  _SectionHeader(text: 'Address details'),
                  const SizedBox(height: AppTokens.s12),
                  _AddressCard(
                    name: address?.name ?? '',
                    addressLine: addressLine,
                  ),
                  const SizedBox(height: AppTokens.s8),
                  _AddAddressBtn(
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
          _CheckoutBar(
            total: widget.totalAmount.toInt(),
            onPurchase: () {
              loggedIn == true
                  ? _startPayment(widget.store)
                  : Navigator.of(context).pushNamed(Routes.login);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _startPayment(SubscriptionStore store) async {
    await store.onGetPaymentDetails(context);
    String apiKey = store.paymentDetails.value?.razorpayKey ??
        "rzp_test_mV7hVxiuC3ljvo";
    String apiSecret = store.paymentDetails.value?.razorpaySecretKey ??
        "sFN1bvTqaGVSPpA2kVfTk2q5";
    debugPrint('razorapikey$apiKey');

    Map<String, dynamic> paymentData = {
      'amount': (widget.totalAmount.toInt()) * 100,
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
      if (Platform.isWindows || Platform.isMacOS) {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => PaymentPage(
                apiKey: store.paymentDetails.value?.razorpayKey ??
                    "rzp_test_mV7hVxiuC3ljvo",
                orderId: responseData['id'])));
      } else {
        RazorpayPayment.openCheckout(
          apiKey: store.paymentDetails.value?.razorpayKey ??
              "rzp_test_mV7hVxiuC3ljvo",
          amount: paymentData['amount'],
          orderId: responseData['id'],
        );
      }
    } else {
      debugPrint('Error creating order: ${response.body}');
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    SubscriptionStore store = widget.store;
    String month = widget.selectedPlanMonth;
    int amount = widget.totalAmount.toInt();
    String? subscriptionId = widget.subscription.sid;
    String durationid = widget.durationId;
    String offerid = widget.offerId;
    String couponid = widget.couponId;
    List bookPrize =
        widget.selectedBooks.map((e) => e['price'].toInt()).toList();
    List bookIds = widget.selectedBooks.map((e) => e['bookId']).toList();

    await Future.wait([
      store.onPurcaseSubscriptionApiCall(
          subscriptionId!,
          amount,
          month,
          durationid,
          response.paymentId!,
          response.orderId!,
          response.signature!,
          couponid,
          offerid),
      store.onPurcaseBookApiCall(widget.address?.sId ?? '', bookPrize, bookIds),
    ]);
    widget.isSingleUse == true
        ? await store.onPurcaseUserOfferApiCall(offerid)
        : null;
    RazorpayPayment.dispose();

    Navigator.of(context).pushNamed(Routes.paymentStatus, arguments: {
      'amount': amount,
      'dateTime': DateTime.now(),
      'paymentId': response.paymentId,
    });
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    int amount = widget.totalAmount.toInt();
    Navigator.of(context).pushNamed(Routes.paymentFailed, arguments: {
      'amount': amount,
      'dateTime': DateTime.now(),
    });
  }
}

// ============================================================
//                        Primitives
// ============================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTokens.accent(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Text(text, style: AppTokens.titleSm(context)),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.label,
    required this.amount,
    this.qtyLabel,
  });
  final String label;
  final String amount;
  final String? qtyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(
          color: AppTokens.accent(context).withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppTokens.accent(context),
            size: 22,
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.bodyLg(context).copyWith(
                color: AppTokens.ink(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (qtyLabel != null) ...[
            Text(
              qtyLabel!,
              style: AppTokens.caption(context).copyWith(
                color: AppTokens.ink2(context),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
          ],
          Text(
            amount,
            style: AppTokens.titleSm(context).copyWith(
              color: AppTokens.ink(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.name, required this.addressLine});
  final String name;
  final String addressLine;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: AppTokens.radius12,
            border: Border.all(color: AppTokens.border(context)),
            boxShadow: AppTokens.shadow1(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTokens.accent(context),
                    width: 2,
                  ),
                ),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppTokens.accent(context),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTokens.titleSm(context),
                    ),
                    const SizedBox(height: AppTokens.s4),
                    Text(
                      addressLine,
                      style: AppTokens.body(context).copyWith(
                        color: AppTokens.ink2(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: AppTokens.s8,
          right: AppTokens.s8,
          child: Icon(
            Icons.edit_rounded,
            color: AppTokens.accent(context),
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _AddAddressBtn extends StatelessWidget {
  const _AddAddressBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surface(context),
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
          decoration: BoxDecoration(
            borderRadius: AppTokens.radius12,
            border: Border.all(
              color: AppTokens.border(context),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 18,
                color: AppTokens.ink(context),
              ),
              const SizedBox(width: AppTokens.s4),
              Text(
                'Change Address',
                style: AppTokens.titleSm(context).copyWith(
                  color: AppTokens.ink(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.total, required this.onPurchase});
  final int total;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.s16,
        AppTokens.s16,
        AppTokens.s16,
        MediaQuery.of(context).padding.bottom + AppTokens.s16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppTokens.shadow2(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Payable Amount",
                  style: AppTokens.caption(context).copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        "₹ $total",
                        style: AppTokens.displayMd(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "inclusive GST",
                        style: AppTokens.caption(context).copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Material(
            color: Colors.white,
            borderRadius: AppTokens.radius12,
            child: InkWell(
              borderRadius: AppTokens.radius12,
              onTap: onPurchase,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s20,
                  vertical: AppTokens.s12,
                ),
                child: Text(
                  "Purchase Now",
                  style: AppTokens.titleSm(context).copyWith(
                    color: AppTokens.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
