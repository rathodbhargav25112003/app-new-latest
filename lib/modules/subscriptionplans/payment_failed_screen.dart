// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';

/// PaymentFailedScreen — shown after a declined payment. Informs the
/// user, displays the amount + timestamp, and offers a "Retry Payment"
/// CTA that pushes [Routes.dashboard].
///
/// Public surface preserved exactly:
///   • class [PaymentFailedScreen] + const constructor
///     `{super.key, required amount, required dateTime}`
///   • static [route] factory reading `arguments['amount']` +
///     `arguments['dateTime']`
///   • Same `paymentFailed.svg` hero + `payment_logo.png` backdrop
class PaymentFailedScreen extends StatefulWidget {
  final int amount;
  final DateTime dateTime;
  const PaymentFailedScreen({
    super.key,
    required this.amount,
    required this.dateTime,
  });

  @override
  State<PaymentFailedScreen> createState() => _PaymentFailedScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => PaymentFailedScreen(
        amount: arguments['amount'],
        dateTime: arguments['dateTime'],
      ),
    );
  }
}

class _PaymentFailedScreenState extends State<PaymentFailedScreen> {
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
                          "Payment Failed!",
                          style: AppTokens.titleLg(context).copyWith(
                            color: AppTokens.danger(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                            height: Dimensions.PADDING_SIZE_DEFAULT),
                        Text(
                          "Hey, seems like there was some trouble.\nWe are there with you, just hold back.",
                          style: AppTokens.body(context).copyWith(
                            color: AppTokens.ink2(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                        Text(
                          DateFormat("d'th' MMM, yyyy | hh:mm a")
                              .format(widget.dateTime),
                          style: AppTokens.caption(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                        _RetryCta(
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
                          color: AppTokens.dangerSoft(context),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          height: Dimensions.PADDING_SIZE_LARGE * 4.4,
                          width: Dimensions.PADDING_SIZE_LARGE * 4.4,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTokens.danger(context),
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset(
                              "assets/image/paymentFailed.svg"),
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

/// Gradient retry CTA — brand gradient with subtle shadow. Label and
/// navigation target unchanged.
class _RetryCta extends StatelessWidget {
  const _RetryCta({required this.onTap});
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
              "Retry Payment",
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
