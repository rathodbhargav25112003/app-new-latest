// ignore_for_file: deprecated_member_use, dead_null_aware_expression, unused_import, use_build_context_synchronously, avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../subscriptionplans/model/get_address_model.dart';
import '../subscriptionplans/razorpay_payment.dart';
import '../subscriptionplans/store/subscription_store.dart';

/// Confirm purchase bottom sheet for hardcopy books — redesigned with
/// AppTokens. Constructor, RazorpayPayment lifecycle, _checkIsLoggedIn,
/// _startPayment / _handlePaymentSuccess / _handlePaymentFailure flow, and
/// all navigation targets preserved.
class ConfirmHardCopyPurchaseBottomSheet extends StatefulWidget {
  final num totalAmount;
  final List<Map<String, dynamic>> selectedBooks;
  final GetAddressModel? address;
  final SubscriptionStore store;

  const ConfirmHardCopyPurchaseBottomSheet({
    super.key,
    required this.totalAmount,
    required this.selectedBooks,
    required this.address,
    required this.store,
  });

  @override
  State<ConfirmHardCopyPurchaseBottomSheet> createState() =>
      _ConfirmHardCopyPurchaseBottomSheetState();
}

class _ConfirmHardCopyPurchaseBottomSheetState
    extends State<ConfirmHardCopyPurchaseBottomSheet> {
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

  List<Map<String, dynamic>> _getUniqueBooks(
      List<Map<String, dynamic>> books) {
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
    final uniqueBooks = _getUniqueBooks(widget.selectedBooks);
    final addressLine = [
      widget.address?.buildingNumber,
      widget.address?.landMark,
      widget.address?.city,
      widget.address?.state,
      widget.address?.pincode,
    ].where((e) => e != null && '$e'.isNotEmpty).join(', ');

    return Material(
      color: AppTokens.surface(context),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.s12),
              child: Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: AppTokens.borderStrong(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Confirm Your Purchase',
              style: AppTokens.titleMd(context),
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              'Review your order and shipping address',
              style: AppTokens.caption(context),
            ),
            const SizedBox(height: AppTokens.s16),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionHeader(title: 'Order details'),
                    const SizedBox(height: AppTokens.s8),
                    ...uniqueBooks.map((book) => _OrderRow(
                          bookName: book['bookName']?.toString() ?? '',
                          quantity: (book['quantity'] ?? 1) as int,
                          price: (book['price'] as num).toInt() *
                              ((book['quantity'] ?? 1) as int),
                        )),
                    const SizedBox(height: AppTokens.s20),
                    _SectionHeader(title: 'Address details'),
                    const SizedBox(height: AppTokens.s8),
                    _AddressCard(
                      name: widget.address?.name ?? '',
                      address: addressLine,
                    ),
                    const SizedBox(height: AppTokens.s12),
                    _AddAddressBtn(
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: AppTokens.s16),
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
      ),
    );
  }

  Future<void> _startPayment(SubscriptionStore store) async {
    await store.onGetPaymentDetails(context);

    String apiKey = store.paymentDetails.value?.razorpayKey ??
        "rzp_test_mV7hVxiuC3ljvo";
    String apiSecret = store.paymentDetails.value?.razorpaySecretKey ??
        "sFN1bvTqaGVSPpA2kVfTk2q5";
    debugPrint('razorapikey: $apiKey');

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
      try {
        RazorpayPayment.openCheckout(
          apiKey: apiKey ?? "rzp_test_mV7hVxiuC3ljvo",
          amount: paymentData['amount'],
          orderId: responseData['id'],
        );
      } catch (e) {
        debugPrint('Error opening Razorpay Checkout: $e');
      }
    } else {
      debugPrint('Error creating order: ${response.body}');
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    SubscriptionStore store = widget.store;
    int amount = widget.totalAmount.toInt();
    List bookPrize =
        widget.selectedBooks.map((e) => e['price'].toInt()).toList();
    List bookIds = widget.selectedBooks.map((e) => e['bookId']).toList();

    await store.onPurcaseBookApiCall(
        widget.address?.sId ?? '', bookPrize, bookIds);
    RazorpayPayment.dispose();

    Navigator.of(context).pushNamed(
      Routes.paymentStatus,
      arguments: {
        'amount': amount,
        'dateTime': DateTime.now(),
        'paymentId': response.paymentId,
      },
    );
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    int amount = widget.totalAmount.toInt();
    Navigator.of(context).pushNamed(
      Routes.paymentFailed,
      arguments: {
        'amount': amount,
        'dateTime': DateTime.now(),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTokens.accent(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Text(
          title,
          style: AppTokens.titleSm(context),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Order row
// ---------------------------------------------------------------------------

class _OrderRow extends StatelessWidget {
  final String bookName;
  final int quantity;
  final int price;
  const _OrderRow({
    required this.bookName,
    required this.quantity,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppTokens.s8),
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(color: AppTokens.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppTokens.accent(context),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bookName,
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (quantity > 1)
                  Text(
                    'Qty × $quantity',
                    style: AppTokens.caption(context),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Text(
            '₹$price',
            style: AppTokens.titleSm(context).copyWith(
              color: AppTokens.ink2(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Address card
// ---------------------------------------------------------------------------

class _AddressCard extends StatelessWidget {
  final String name;
  final String address;
  const _AddressCard({required this.name, required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft(context),
        borderRadius: AppTokens.radius12,
        border: Border.all(
          color: AppTokens.accent(context).withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTokens.accent(context),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTokens.titleSm(context),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: AppTokens.body(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add address button
// ---------------------------------------------------------------------------

class _AddAddressBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddAddressBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppTokens.s12,
          ),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: AppTokens.radius12,
            border: Border.all(
              color: AppTokens.border(context),
              style: BorderStyle.solid,
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
              const SizedBox(width: 6),
              Text(
                'Change Address',
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Checkout bar
// ---------------------------------------------------------------------------

class _CheckoutBar extends StatelessWidget {
  final int total;
  final VoidCallback onPurchase;
  const _CheckoutBar({required this.total, required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s16,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Payable Amount',
                style: AppTokens.caption(context).copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹$total',
                    style: AppTokens.displayMd(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      'inclusive GST',
                      style: AppTokens.caption(context).copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Material(
              color: Colors.white,
              borderRadius: AppTokens.radius12,
              child: InkWell(
                borderRadius: AppTokens.radius12,
                onTap: onPurchase,
                child: Container(
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTokens.s12),
                  child: Text(
                    'Purchase Now',
                    style: AppTokens.titleSm(context).copyWith(
                      color: AppTokens.brand,
                      fontWeight: FontWeight.w800,
                    ),
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
