import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayPayment {
  static final Razorpay _razorpay = Razorpay();

  static Function(PaymentSuccessResponse)? _successCallback;
  static Function(PaymentFailureResponse)? _failureCallback;

  static void initialize(
      Function(PaymentSuccessResponse) successCallback,
      Function(PaymentFailureResponse) failureCallback,
      ) {
    _successCallback = successCallback;
    _failureCallback = failureCallback;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  static void openCheckout({required int amount, required String orderId, required String apiKey}) {
    var options = {
      'key': apiKey,
      'amount': amount,
      'name': 'Sushruta Educations LLP',
      'order_id': orderId,
      'description': 'Payment for Subscription Plan',
      'prefill': {'contact': '', 'email': 'test@razorpay.com'},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
      print("razorpay");
    } catch (e) {
      print(e.toString());
    }
  }

  static void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _successCallback?.call(response);
  }

  static void _handlePaymentFailure(PaymentFailureResponse response) {
    _failureCallback?.call(response);
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName!}');
  }

  static void dispose() {
    _razorpay.clear();
  }
}
