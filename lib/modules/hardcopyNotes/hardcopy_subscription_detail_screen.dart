// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Durations;
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/models/subscription_model.dart';
import 'package:shusruta_lms/modules/subscriptionplans/razorpay_payment.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../widgets/bottom_toast.dart';

/// Hardcopy subscription detail screen — redesigned with AppTokens. Shows the
/// plan's benefits, durations, coupon field, and available offers in a clean
/// bottom-sheet-style layout over a brand gradient header. All state fields,
/// Provider wiring, SharedPreferences login check, navigation to
/// [Routes.selectedSubscriptionPlanScreen] with the full argument map, and the
/// coupon/offer discount arithmetic are preserved verbatim.
class HardCopySubscriptionDetailScreen extends StatefulWidget {
  final SubscriptionModel subscription;
  final SubscriptionStore store;

  const HardCopySubscriptionDetailScreen({
    super.key,
    required this.subscription,
    required this.store,
  });

  @override
  State<HardCopySubscriptionDetailScreen> createState() =>
      _HardCopySubscriptionDetailScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => HardCopySubscriptionDetailScreen(
        subscription: arguments["subscription"],
        store: arguments["store"],
      ),
    );
  }
}

class _HardCopySubscriptionDetailScreenState
    extends State<HardCopySubscriptionDetailScreen> {
  int _selectedIndex = 0;
  int discountedPrice = 0;
  int discountOffer = 0;
  int discountCoupon = 0;
  int? _currentindex;
  bool apply = false;
  bool isSingleUse = false;
  String? offerId;
  String? durationId;
  String? selectedPlanMonth;
  int? originalPrice;
  String? couponId;
  Future<bool>? isLogged;
  bool loggedIn = false;
  String encryptedToken = '';
  final TextEditingController couponController = TextEditingController();
  final _couponKey = GlobalKey<FormFieldState<String>>();
  final _prepParingKey = GlobalKey<FormFieldState<String>>();
  final bool _iscouponValid = false;
  final bool _isPreparingValid = false;
  String selectedValue = '';
  final FocusNode _focusNode = FocusNode();
  int appliedIndex = -1;

  final List<String> availableIcons = const [
    'assets/image/SubMcq.svg',
    'assets/image/SubNote.svg',
    'assets/image/SubVideo.svg',
    'assets/image/SubLive.svg',
  ];
  int? _selectedValue2;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    store.onGetAllCouponUserApiCall(widget.subscription.sid ?? "");
    store.onGetAllOfferUserApiCall(widget.subscription.sid ?? "");
    isLogged = _checkIsLoggedIn();
    isLogged!.then((value) {
      setState(() {
        loggedIn = value;
      });
    });

    Durations? subPlan = widget.subscription.duration?[0];
    String? subPlanOffer = subPlan?.offer?.replaceAll("%", "");
    double parsedOffer = 0;
    if (subPlanOffer != null && subPlanOffer.isNotEmpty) {
      subPlanOffer = subPlanOffer.replaceAll("%", "").trim();
      try {
        parsedOffer = double.parse(subPlanOffer);
      } catch (e) {
        print("Error parsing subPlanOffer: $e");
      }
    }
    double offerPrice = (subPlan?.price ?? 0) * ((100 - parsedOffer) / 100);
    selectedPlanMonth = subPlan?.day;
    durationId = subPlan?.durationId;
    discountedPrice = offerPrice.toInt();
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

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    RazorpayPayment.dispose();
    super.dispose();
  }

  String formatTime(int numberOfDays) {
    if (numberOfDays >= 365) {
      int years = numberOfDays ~/ 365;
      return years == 1 ? '1 Year' : '$years years';
    } else if (numberOfDays >= 30) {
      int months = numberOfDays ~/ 30;
      return months == 1 ? '1 month' : '$months months';
    } else {
      return '$numberOfDays days';
    }
  }

  void getOfferDiscount(SubscriptionStore store) {
    final discountPercentage =
        store.getAllOfferUser[_currentindex!]?.discountPercentage ?? 0;
    final discountPrize =
        store.getAllOfferUser[_currentindex!]?.discountPrize ?? 0;

    if (discountPrize != 0) {
      discountOffer = discountPrize.toInt();
    } else {
      discountOffer =
          (discountedPrice * ((discountPercentage / 100))).toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SubscriptionStore>(context);
    final total = discountedPrice - -discountCoupon - discountOffer;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _Header(
            title: widget.subscription.plan_name ?? "",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTokens.r28),
                  topRight: Radius.circular(AppTokens.r28),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.s16,
                        AppTokens.s24,
                        AppTokens.s16,
                        AppTokens.s24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(text: "What you will get?"),
                          const SizedBox(height: AppTokens.s12),
                          _BenefitsWrap(
                            benefits: widget.subscription.benifit ?? [],
                            availableIcons: availableIcons,
                          ),
                          const SizedBox(height: AppTokens.s24),
                          _SectionTitle(text: "Benefits"),
                          const SizedBox(height: AppTokens.s8),
                          Html(
                            data: '''
                              <div style="color: ${ThemeManager.currentTheme == AppTheme.Dark ? 'white' : 'black'};">
                              ${widget.subscription.description ?? ""}
                              </div>
                              ''',
                          ),
                          const SizedBox(height: AppTokens.s24),
                          _SectionTitle(text: "Select Duration"),
                          const SizedBox(height: AppTokens.s12),
                          Wrap(
                            spacing: AppTokens.s12,
                            runSpacing: AppTokens.s12,
                            children: List.generate(
                              widget.subscription.duration?.length ?? 0,
                              (index) {
                                Durations? subPlan =
                                    widget.subscription.duration?[index];
                                String? subPlanOffer =
                                    subPlan?.offer?.replaceAll("%", "");
                                double parsedOffer = 0;
                                if (subPlanOffer != null &&
                                    subPlanOffer.isNotEmpty) {
                                  subPlanOffer = subPlanOffer
                                      .replaceAll("%", "")
                                      .trim();
                                  try {
                                    parsedOffer = double.parse(subPlanOffer);
                                  } catch (e) {
                                    print("Error parsing subPlanOffer: $e");
                                  }
                                }
                                double offerPrice = (subPlan?.price ?? 0) *
                                    ((100 - parsedOffer) / 100);
                                bool isSelected = index == _selectedIndex;

                                return _DurationTile(
                                  label: formatTime(
                                      int.parse(subPlan?.day ?? "")),
                                  originalPrice: subPlan?.price ?? 0,
                                  discountedPrice: subPlan?.offer == null
                                      ? (subPlan?.price ?? 0).toDouble()
                                      : offerPrice,
                                  hasOffer: subPlan?.offer != null,
                                  selected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      selectedPlanMonth = subPlan?.day;
                                      durationId = subPlan?.durationId;
                                      discountedPrice = offerPrice.toInt();
                                      originalPrice = subPlan?.price;
                                      _selectedIndex = index;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppTokens.s24),
                          Observer(
                            builder: (BuildContext context) {
                              if (store.isLoading) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: AppTokens.accent(context),
                                  ),
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(text: "Enter Coupon Code"),
                                  const SizedBox(height: AppTokens.s12),
                                  _CouponField(
                                    controller: couponController,
                                    applied: apply,
                                    onApply: () {
                                      setState(() {
                                        if (apply) {
                                          couponController.clear();
                                          apply = false;
                                        }
                                        var matchingCoupon = store
                                            .getAllCouponUser
                                            .firstWhere(
                                          (element) =>
                                              element?.code ==
                                              couponController.text,
                                          orElse: () => null,
                                        );
                                        if (matchingCoupon != null) {
                                          apply = true;
                                          discountCoupon =
                                              matchingCoupon.discountPrize ??
                                                  0;
                                          couponId = matchingCoupon.sId;
                                        } else {
                                          couponController.clear();
                                          BottomToast
                                              .showBottomToastOverlay(
                                            context: context,
                                            errorMessage:
                                                "Invalid Coupon Code",
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppTokens.s24),
                          Observer(
                            builder: (context) {
                              if (store.isLoading) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: AppTokens.accent(context),
                                  ),
                                );
                              }
                              if (store.getAllOfferUser.isEmpty) {
                                return const SizedBox();
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(text: "Offers"),
                                  const SizedBox(height: AppTokens.s12),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: store.getAllOfferUser.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      final offer =
                                          store.getAllOfferUser[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: AppTokens.s8),
                                        child: _OfferTile(
                                          description:
                                              offer?.description ?? '',
                                          selected: _currentindex == index,
                                          onTap: () {
                                            setState(() {
                                              if (_currentindex == index) {
                                                _currentindex = null;
                                                discountOffer = 0;
                                                apply = false;
                                              } else {
                                                _currentindex = index;
                                                offerId = store
                                                    .getAllOfferUser[index]
                                                    ?.sId;
                                                getOfferDiscount(store);
                                                apply = true;
                                              }
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppTokens.s32),
                        ],
                      ),
                    ),
                  ),
                  _CheckoutBar(
                    total: total,
                    onContinue: () {
                      if (_currentindex != null) {
                        isSingleUse = store
                                    .getAllOfferUser[_currentindex!]
                                    ?.isSingleUse ==
                                true
                            ? true
                            : false;
                      }
                      Navigator.of(context).pushNamed(
                          Routes.selectedSubscriptionPlanScreen,
                          arguments: {
                            'store': widget.store,
                            'subscription': widget.subscription,
                            'subTotalAmount': discountedPrice -
                                discountCoupon -
                                discountOffer,
                            "selectedPlanMonth": selectedPlanMonth,
                            "durationId": durationId,
                            "offerId": offerId,
                            "couponId": couponId,
                            "isSingleUse": isSingleUse,
                          });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//                        Primitives
// ============================================================

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.s8,
        MediaQuery.of(context).padding.top + AppTokens.s12,
        AppTokens.s16,
        AppTokens.s24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTokens.brand.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _CircleBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.titleMd(context).copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
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

class _BenefitsWrap extends StatelessWidget {
  const _BenefitsWrap({
    required this.benefits,
    required this.availableIcons,
  });
  final List<String?> benefits;
  final List<String> availableIcons;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      children: List.generate(benefits.length, (index) {
        final String? benefit = benefits[index];
        String icon;
        if (index < 4) {
          icon = availableIcons[index];
        } else {
          int repeatIndex =
              (index - 4) % (availableIcons.length - 4) + 3;
          icon = availableIcons[repeatIndex];
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s4,
            AppTokens.s4,
            AppTokens.s12,
            AppTokens.s4,
          ),
          decoration: BoxDecoration(
            color: AppTokens.surface(context),
            borderRadius: BorderRadius.circular(64),
            border: Border.all(color: AppTokens.border(context)),
            boxShadow: AppTokens.shadow1(context),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.accentSoft(context),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(icon, width: 16, height: 16),
              ),
              const SizedBox(width: AppTokens.s8),
              Text(
                benefit ?? '',
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.ink(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({
    required this.label,
    required this.originalPrice,
    required this.discountedPrice,
    required this.hasOffer,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final num originalPrice;
  final double discountedPrice;
  final bool hasOffer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.ink2(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        InkWell(
          borderRadius: AppTokens.radius12,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16,
              vertical: AppTokens.s8,
            ),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [AppTokens.brand, AppTokens.brand2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selected ? null : AppTokens.surface(context),
              borderRadius: AppTokens.radius12,
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : AppTokens.border(context),
              ),
              boxShadow:
                  selected ? AppTokens.shadow2(context) : AppTokens.shadow1(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasOffer)
                  Text(
                    "₹ $originalPrice",
                    style: AppTokens.caption(context).copyWith(
                      color: selected
                          ? Colors.white.withOpacity(0.8)
                          : AppTokens.ink2(context),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                if (hasOffer) const SizedBox(height: AppTokens.s4),
                Text(
                  "₹ ${discountedPrice.toStringAsFixed(0)}",
                  style: AppTokens.numeric(
                    context,
                    size: selected ? 18 : 16,
                  ).copyWith(
                    color: selected ? Colors.white : AppTokens.ink(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CouponField extends StatelessWidget {
  const _CouponField({
    required this.controller,
    required this.applied,
    required this.onApply,
  });
  final TextEditingController controller;
  final bool applied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      cursorColor: AppTokens.accent(context),
      style: AppTokens.body(context).copyWith(color: AppTokens.ink(context)),
      decoration: AppTokens.inputDecoration(
        context,
        hint: 'Enter Coupon Code',
        suffix: Padding(
          padding: const EdgeInsets.all(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: onApply,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s16,
                vertical: AppTokens.s8,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTokens.brand, AppTokens.brand2],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              alignment: Alignment.center,
              child: Text(
                applied ? "Applied" : "Apply",
                style: AppTokens.caption(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.description,
    required this.selected,
    required this.onTap,
  });
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppTokens.radius12,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTokens.s12),
        decoration: BoxDecoration(
          color: selected
              ? AppTokens.accentSoft(context)
              : AppTokens.surface(context),
          borderRadius: AppTokens.radius12,
          border: Border.all(
            color: selected
                ? AppTokens.accent(context)
                : AppTokens.border(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.surface(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppTokens.accent(context)
                      : AppTokens.borderStrong(context),
                  width: 2,
                ),
              ),
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTokens.accent(context),
                        shape: BoxShape.circle,
                      ),
                    )
                  : const SizedBox(),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Text(
                description,
                style: AppTokens.body(context).copyWith(
                  color: AppTokens.ink(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.total, required this.onContinue});
  final int total;
  final VoidCallback onContinue;

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
              onTap: onContinue,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s20,
                  vertical: AppTokens.s12,
                ),
                alignment: Alignment.center,
                child: Text(
                  "Continue",
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
