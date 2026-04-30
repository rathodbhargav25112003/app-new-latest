// payment_page.dart

// ignore_for_file: library_private_types_in_public_api, unused_element,
// deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../helpers/app_tokens.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// PaymentPage — stub wrapper for the (currently commented) Razorpay
/// checkout WebView. The platform-specific integration has been moved
/// out, so this screen now only renders a clean empty shell while the
/// real flow runs elsewhere (RazorpayPayment + payment_success /
/// payment_failed screens).
///
/// Public surface preserved exactly:
///   • class [PaymentPage] + const constructor `{super.key,
///     required apiKey, required orderId}`
///   • `_PaymentPageState._handlePaymentSuccess(Uri)` /
///     `_handlePaymentFailure()` / `showAlertDialog(...)` helpers
class PaymentPage extends StatefulWidget {
  final String apiKey;
  final String orderId;

  const PaymentPage({
    super.key,
    required this.apiKey,
    required this.orderId,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // late InAppWebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppTokens.surface(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppTokens.ink(context)),
        title: Text(
          "Payment",
          style: AppTokens.titleMd(context).copyWith(
            color: AppTokens.ink(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      // body: InAppWebView(
      //   initialUrlRequest: URLRequest(
      //     url: WebUri(
      //         'https://checkout.razorpay.com/v1/checkout.js?key=${widget.apiKey}&order_id=${widget.orderId}'),
      //   ),
      //   initialOptions: InAppWebViewGroupOptions(
      //     crossPlatform: InAppWebViewOptions(
      //       javaScriptEnabled: true,
      //     ),
      //   ),
      //   onWebViewCreated: (InAppWebViewController controller) {
      //     _webViewController = controller;
      //   },
      //   shouldOverrideUrlLoading: (controller, navigationAction) async {
      //     var uri = navigationAction.request.url;
      //
      //     if (uri.toString().contains('your-success-url.com')) {
      //       _handlePaymentSuccess(uri!);
      //       return NavigationActionPolicy.CANCEL;
      //     } else if (uri.toString().contains('your-failure-url.com')) {
      //       _handlePaymentFailure();
      //       return NavigationActionPolicy.CANCEL;
      //     }
      //
      //     return NavigationActionPolicy.ALLOW;
      //   },
      // ),
    );
  }

  void _handlePaymentSuccess(Uri url) {
    // Extract payment details from the URL and handle success logic
    if (url.queryParameters.containsKey('payment_id') &&
        url.queryParameters.containsKey('order_id') &&
        url.queryParameters.containsKey('signature')) {
      String paymentId = url.queryParameters['payment_id'] ?? '';
      String orderId = url.queryParameters['order_id'] ?? '';
      // ignore: unused_local_variable
      String signature = url.queryParameters['signature'] ?? '';

      // Handle payment success logic
      debugPrint(
          'Payment Success: Payment ID - $paymentId, Order ID - $orderId');
      showAlertDialog(
          context, 'Payment Success', 'Your payment was successful!');
    } else {
      debugPrint('Payment success URL does not contain required parameters.');
      showAlertDialog(
          context, 'Error', 'Unexpected response from the payment gateway.');
    }

    Navigator.of(context).pop(); // Navigate back after handling payment
  }

  void _handlePaymentFailure() {
    // Handle payment failure
    debugPrint('Payment failed. Redirecting to failure screen.');
    showAlertDialog(context, 'Payment Failed',
        'Your payment was not successful. Please try again.');
    Navigator.of(context).pop(); // Navigate back after handling payment
  }

  void showAlertDialog(BuildContext context, String title, String message) {
    Widget continueButton = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTokens.brand,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
        ),
      ),
      child: const Text("Continue"),
      onPressed: () {
        Navigator.of(context).pushNamed('/dashboard');
      },
    );
    AlertDialog alert = AlertDialog(
      backgroundColor: AppTokens.surface(context),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.r16),
      ),
      title: Text(
        title,
        style: AppTokens.titleMd(context).copyWith(
          color: AppTokens.ink(context),
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        message,
        style: AppTokens.body(context).copyWith(
          color: AppTokens.ink2(context),
        ),
      ),
      actions: [
        continueButton,
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
