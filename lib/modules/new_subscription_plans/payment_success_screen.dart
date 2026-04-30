// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import 'package:provider/provider.dart';
import 'store/ordered_book_store.dart';
import 'ordered_book_list.dart';

/// PaymentSuccessScreen — revamped success confirmation with a brand
/// gradient header, a centered success badge, and cards summarising the
/// plan the user subscribed to and (optionally) the hardcopy book order.
///
/// Public surface preserved exactly:
///   • class [PaymentSuccessScreen] + const constructor
///     `{super.key, required amount, required paymentId, required planName, hardcopyBookName}`
///   • static [route] factory reading four arguments
///   • WillPop pops back to `Routes.dashboard`
///   • Start Learning button → `Routes.dashboard`
///   • Track Order button → `OrderedBookListScreen` with a fresh
///     `OrderedBookStore` provider
class PaymentSuccessScreen extends StatelessWidget {
  final String amount;
  final String paymentId;
  final String planName;
  final String? hardcopyBookName;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.paymentId,
    required this.planName,
    this.hardcopyBookName,
  });

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => PaymentSuccessScreen(
        amount: args['amount'] as String,
        paymentId: args['paymentId'] as String,
        planName: args['planName'] as String,
        hardcopyBookName: args['hardcopyBookName'] as String?,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    final horizontalPadding = isDesktop || isTablet ? 32.0 : 16.0;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.dashboard,
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTokens.scaffold(context),
        body: Column(
          children: [
            // Brand gradient hero
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTokens.brand, AppTokens.brand2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: horizontalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/image/app_logo.png',
                            width: 180,
                            height: 180,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
            // Content panel
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -40),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTokens.scaffold(context),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTokens.r28),
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Column(
                            children: [
                              Text(
                                "inclusive of GST",
                                style: AppTokens.caption(context).copyWith(
                                  color: AppTokens.muted(context),
                                ),
                              ),
                              const SizedBox(height: AppTokens.s8),
                              Text(
                                "\u20B9$amount",
                                style: AppTokens.displayMd(context).copyWith(
                                  color: AppTokens.ink(context),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppTokens.s20),
                              Text(
                                "Payment Successful!",
                                style: AppTokens.titleLg(context).copyWith(
                                  color: AppTokens.ink(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppTokens.s8),
                              Text(
                                "Congratulations!! Your payment was \nsuccessful.",
                                textAlign: TextAlign.center,
                                style: AppTokens.body(context).copyWith(
                                  color: AppTokens.muted(context),
                                ),
                              ),
                              const SizedBox(height: AppTokens.s16),
                              Text(
                                "Payment ID : $paymentId",
                                style: AppTokens.caption(context).copyWith(
                                  color: AppTokens.muted(context),
                                ),
                              ),
                              const SizedBox(height: AppTokens.s16),
                              // Plan card
                              Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding),
                                decoration: BoxDecoration(
                                  color: AppTokens.successSoft(context),
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.r16),
                                  border: Border.all(
                                      color: AppTokens.border(context)),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(AppTokens.s16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTokens.surface(context),
                                          borderRadius: BorderRadius.circular(
                                              AppTokens.r8),
                                        ),
                                        child: Icon(
                                          Icons.workspace_premium_rounded,
                                          color: AppTokens.success(context),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Your Plan",
                                              style: AppTokens.caption(context)
                                                  .copyWith(
                                                color: AppTokens.muted(context),
                                              ),
                                            ),
                                            Text(
                                              planName,
                                              style: AppTokens.body(context)
                                                  .copyWith(
                                                color: AppTokens.ink(context),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _TinyCta(
                                        label: "Start Learning",
                                        color: AppTokens.success(context),
                                        onTap: () {
                                          Navigator.of(context)
                                              .pushNamedAndRemoveUntil(
                                            Routes.dashboard,
                                            (route) => false,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Hardcopy card (conditional)
                              if (hardcopyBookName != null)
                                Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: horizontalPadding),
                                  decoration: BoxDecoration(
                                    color: AppTokens.accentSoft(context),
                                    borderRadius:
                                        BorderRadius.circular(AppTokens.r16),
                                    border: Border.all(
                                        color: AppTokens.border(context)),
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(AppTokens.s16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTokens.surface(context),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    AppTokens.r8),
                                          ),
                                          child: const Icon(
                                            Icons.book_rounded,
                                            color: AppTokens.brand,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Your Order",
                                                style: AppTokens.caption(context)
                                                    .copyWith(
                                                  color:
                                                      AppTokens.muted(context),
                                                ),
                                              ),
                                              Text(
                                                hardcopyBookName!,
                                                style: AppTokens.body(context)
                                                    .copyWith(
                                                  color: AppTokens.ink(context),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _TinyCta(
                                          label: "Track Order",
                                          color: AppTokens.brand,
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    Provider<OrderedBookStore>(
                                                  create: (_) =>
                                                      OrderedBookStore(),
                                                  child:
                                                      const OrderedBookListScreen(),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      // Success badge overlapping hero
                      Positioned(
                        top: -60,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppTokens.surface(context),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color:
                                      AppTokens.success(context).withOpacity(0.18),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 72,
                                height: 72,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTokens.success(context),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTokens.success(context)
                                          .withOpacity(0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

/// Small gradient/flat-color chip-shaped CTA used inside the plan /
/// order cards for "Start Learning" / "Track Order".
class _TinyCta extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TinyCta({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r8),
        onTap: onTap,
        child: Ink(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTokens.r8),
          ),
          child: Text(
            label,
            style: AppTokens.caption(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
