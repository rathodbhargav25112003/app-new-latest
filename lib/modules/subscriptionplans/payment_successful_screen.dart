// ignore_for_file: deprecated_member_use, unused_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';

/// PaymentSuccessfulScreen — celebratory confirmation shown after a
/// successful purchase. Displays amount, payment ID, timestamp and a
/// CTA that drops the user into [Routes.dashboard].
///
/// Public surface preserved exactly:
///   • class [PaymentSuccessfulScreen] + const constructor
///     `{super.key, paymentId, required amount, required dateTime}`
///   • static [route] factory reading `arguments['paymentId']`,
///     `arguments['amount']`, `arguments['dateTime']`
///   • Same `paymentSuccess.svg` hero + `payment_logo.png` backdrop
class PaymentSuccessfulScreen extends StatefulWidget {
  final String? paymentId;
  final int amount;
  final DateTime dateTime;
  const PaymentSuccessfulScreen({
    super.key,
    this.paymentId,
    required this.amount,
    required this.dateTime,
  });

  @override
  State<PaymentSuccessfulScreen> createState() =>
      _PaymentSuccessfulScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => PaymentSuccessfulScreen(
        paymentId: arguments['paymentId'],
        amount: arguments['amount'],
        dateTime: arguments['dateTime'],
      ),
    );
  }
}

class _PaymentSuccessfulScreenState extends State<PaymentSuccessfulScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTokens.brand, AppTokens.brand2],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset("assets/image/payment_logo.png"),
            ),
            Expanded(
              flex: 2,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.only(
                      left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      right: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                      top: Dimensions.PADDING_SIZE_LARGE * 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.surface(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28.8),
                        topRight: Radius.circular(28.8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "inclusive of GST",
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.muted(context),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(
                          height: Dimensions.PADDING_SIZE_SMALL,
                        ),
                        Text(
                          "\u20B9 ${widget.amount}",
                          style: AppTokens.displayMd(context).copyWith(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink(context),
                          ),
                        ),
                        const SizedBox(
                          height: Dimensions.PADDING_SIZE_LARGE * 1.6,
                        ),
                        Text(
                          "Payment Successful!",
                          style: AppTokens.titleLg(context).copyWith(
                            color: AppTokens.success(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                            height: Dimensions.PADDING_SIZE_DEFAULT),
                        Text(
                          "Congratulations!! Your payment was successful.",
                          style: AppTokens.body(context).copyWith(
                            color: AppTokens.ink2(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                        Text(
                          "Payment ID : ${widget.paymentId}",
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                            height: Dimensions.PADDING_SIZE_DEFAULT),
                        Text(
                          DateFormat("d'th' MMM, yyyy | hh:mm a")
                              .format(widget.dateTime),
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                        _StartCta(
                          onTap: () {
                            Navigator.of(context).pushNamed(Routes.dashboard);
                          },
                        ),
                        const SizedBox(
                          height: Dimensions.PADDING_SIZE_LARGE * 1.3,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -59,
                    left: MediaQuery.of(context).size.width * 0.35,
                    child: Container(
                      height: Dimensions.PADDING_SIZE_LARGE * 5.9,
                      width: Dimensions.PADDING_SIZE_LARGE * 5.9,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTokens.surface(context),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Container(
                        height: Dimensions.PADDING_SIZE_LARGE * 5.2,
                        width: Dimensions.PADDING_SIZE_LARGE * 5.2,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTokens.successSoft(context),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          height: Dimensions.PADDING_SIZE_LARGE * 4.4,
                          width: Dimensions.PADDING_SIZE_LARGE * 4.4,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTokens.success(context),
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset(
                              "assets/image/paymentSuccess.svg"),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient primary CTA — same label "Let’s Start" and navigation
/// target as before, wrapped in a brand gradient with a soft shadow.
class _StartCta extends StatelessWidget {
  const _StartCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: Ink(
          height: Dimensions.PADDING_SIZE_LARGE * 2.2,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: [
              BoxShadow(
                color: AppTokens.brand.withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "Let\u2019s Start",
              style: AppTokens.body(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
