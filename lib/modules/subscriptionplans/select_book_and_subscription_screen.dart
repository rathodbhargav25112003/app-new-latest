// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, unused_field, unused_local_variable, dead_null_aware_expression, prefer_interpolation_to_compose_strings, use_build_context_synchronously, avoid_unnecessary_containers, library_private_types_in_public_api, duplicate_ignore, unused_element, avoid_print, unnecessary_string_interpolations, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shusruta_lms/modules/subscriptionplans/web_payment_page.dart';
import 'package:webview_flutter/webview_flutter.dart' as web;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/models/subscription_model.dart';
import 'package:shusruta_lms/modules/subscriptionplans/razorpay_payment.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';
import 'package:shusruta_lms/modules/subscriptionplans/macos_in_app_purchase.dart';
import 'package:http/http.dart' as http;
import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../widgets/bottom_toast.dart';
import 'model/get_address_model.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';
import 'package:shusruta_lms/modules/widgets/subscription_dialog.dart';

class SelectBookAndSubscriptionDetailScreen extends StatefulWidget {
  final SubscriptionModel subscription;
  final SubscriptionStore store;
  final num totalAmount;
  final List<Map<String, dynamic>> selectedBooks;
  final GetAddressModel address;
  const SelectBookAndSubscriptionDetailScreen(
      {super.key,
      required this.subscription,
      required this.store,
      required this.totalAmount,
      required this.address,
      required this.selectedBooks});

  @override
  State<SelectBookAndSubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SelectBookAndSubscriptionDetailScreen(
        subscription: arguments['subscription'],
        store: arguments['store'],
        totalAmount: arguments['totalAmount'],
        selectedBooks: arguments['selectedBooks'],
        address: arguments['address'],
      ),
    );
  }
}

class _SubscriptionDetailScreenState
    extends State<SelectBookAndSubscriptionDetailScreen> {
  int _selectedIndex = 0;
  int discountOffer = 0;
  int discountCoupon = 0;
  int? _currentindex;
  bool apply = false;
  int discountedPrice = 0;
  String? offerId;
  String? durationId;
  String? selectedPlanMonth;
  int? originalPrice;
  // int? discountPrice;
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
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    store.onGetAllCouponUserApiCall(widget.subscription.sid ?? "");
    store.onGetAllOfferUserApiCall(widget.subscription.sid ?? "");
    RazorpayPayment.initialize(_handlePaymentSuccess, _handlePaymentFailure);
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

  List<String> availableIcons = [
    'assets/image/SubMcq.svg',
    'assets/image/SubNote.svg',
    'assets/image/SubVideo.svg',
    'assets/image/SubLive.svg',
  ];
  int? _selectedValue2;
  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SubscriptionStore>(context);
    List<Map<String, dynamic>> uniqueBooks =
        _getUniqueBooks(widget.selectedBooks);
    List<material.DropdownMenuItem<String>> dropdownItems =
        store.getAllCouponUser.map((item) {
      final couponCode = item?.code;
      return material.DropdownMenuItem<String>(
        value: couponCode,
        child: Text(couponCode!),
      );
    }).toList();

    return material.Scaffold(
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
            Padding(
              padding: (Platform.isWindows || Platform.isMacOS)
                  ? const EdgeInsets.symmetric(
                      vertical: Dimensions.PADDING_SIZE_LARGE * 1,
                      horizontal: Dimensions.PADDING_SIZE_LARGE * 1.2)
                  : const EdgeInsets.only(
                      top: Dimensions.PADDING_SIZE_LARGE * 3,
                      left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                      right: Dimensions.PADDING_SIZE_LARGE * 1.2,
                      bottom: Dimensions.PADDING_SIZE_SMALL * 1.3),
              child: Row(
                children: [
                  material.IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        material.Icons.arrow_back_ios,
                        color: AppColors.white,
                        size: 18,
                      )),
                  const SizedBox(
                    width: Dimensions.PADDING_SIZE_DEFAULT,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: Text(
                      widget.subscription.plan_name ?? "",
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(
                    // left: Dimensions.PADDING_SIZE_LARGE*1.2,
                    // right: Dimensions.PADDING_SIZE_LARGE*1.2,
                    top: Dimensions.PADDING_SIZE_LARGE),
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: (Platform.isWindows || Platform.isMacOS)
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: Dimensions.PADDING_SIZE_DEFAULT,
                          right: Dimensions.PADDING_SIZE_DEFAULT,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children:
                                  List.generate(uniqueBooks.length, (index) {
                                Map<String, dynamic> bookDetails =
                                    uniqueBooks[index];
                                int bookQuantity = bookDetails['quantity'];
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: const EdgeInsets.only(
                                      bottom: Dimensions.PADDING_SIZE_DEFAULT),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: ThemeManager.mainBorder),
                                    color: ThemeManager.currentTheme ==
                                            AppTheme.Dark
                                        ? null
                                        : const Color(0xFFF2F8FF),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          height: 54,
                                          child: Image.asset(
                                              "assets/image/bookCover.png")),
                                      const SizedBox(
                                          width:
                                              Dimensions.PADDING_SIZE_DEFAULT),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.4,
                                                      child: Text(
                                                        bookDetails[
                                                                'bookName'] ??
                                                            '',
                                                        style: interRegular
                                                            .copyWith(
                                                          fontSize: Dimensions
                                                              .fontSizeExtraSmall,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: ThemeManager
                                                              .black,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      bookDetails['bookType'] ??
                                                          '',
                                                      style:
                                                          interRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeExtraSmall,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: ThemeManager
                                                            .textColor3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    const SizedBox(
                                                      height: 2,
                                                    ),
                                                    Text(
                                                      "₹ ${bookDetails['price'].toInt() * bookQuantity}",
                                                      style:
                                                          interRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeDefault,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            ThemeManager.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      "Delivery Fee Extra",
                                                      style:
                                                          interRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeExtraSmall,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: ThemeManager
                                                            .textColor3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: Dimensions
                                                          .PADDING_SIZE_SMALL,
                                                      vertical: 2),
                                                  margin: const EdgeInsets.only(
                                                      bottom: 3),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.5),
                                                    color:
                                                        const Color(0xFFD0E3FA),
                                                  ),
                                                  child: Text(
                                                    "View More",
                                                    style:
                                                        interRegular.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeExtraSmall,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color:
                                                          AppColors.textColor3,
                                                      height: 0,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  'Qty : $bookQuantity',
                                                  style: interRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeSmall,
                                                    fontWeight: FontWeight.w500,
                                                    color: ThemeManager.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                          width:
                                              Dimensions.PADDING_SIZE_DEFAULT),
                                    ],
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(
                              height: Dimensions.PADDING_SIZE_SMALL,
                            ),
                            material.ExpansionTile(
                              expandedAlignment: Alignment.topLeft,
                              initiallyExpanded: false,
                              iconColor: ThemeManager.black,
                              collapsedIconColor: ThemeManager.black,
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              collapsedShape: Border(
                                  bottom: BorderSide(
                                      color:
                                          ThemeManager.black.withOpacity(0.2))),
                              shape: Border(
                                  bottom: BorderSide(
                                      color:
                                          ThemeManager.black.withOpacity(0.2))),
                              title: Text(
                                "What you will get?",
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeManager.black,
                                ),
                              ),
                              children: [
                                Wrap(
                                  spacing:
                                      Dimensions.PADDING_SIZE_DEFAULT * 1.1,
                                  runSpacing:
                                      Dimensions.PADDING_SIZE_SMALL * 1.2,
                                  children: List.generate(
                                      widget.subscription.benifit?.length ?? 0,
                                      (index) {
                                    String? benefits =
                                        widget.subscription.benifit![index];
                                    String icon;

                                    if (index < 4) {
                                      icon = availableIcons[index];
                                    } else {
                                      int repeatIndex = (index - 4) %
                                              (availableIcons.length - 4) +
                                          3;
                                      icon = availableIcons[repeatIndex];
                                    }
                                    return Container(
                                      padding: const EdgeInsets.only(
                                        left: Dimensions
                                                .PADDING_SIZE_EXTRA_SMALL *
                                            1.6,
                                        right: Dimensions.PADDING_SIZE_DEFAULT,
                                        top:
                                            Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                        bottom:
                                            Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                      ),
                                      decoration: BoxDecoration(
                                          color: ThemeManager.white,
                                          borderRadius:
                                              BorderRadius.circular(64.68),
                                          border: Border.all(
                                            color: ThemeManager.black
                                                .withOpacity(0.28),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                                offset: const Offset(0, 1.85),
                                                blurRadius: 12.94,
                                                spreadRadius: -6.47,
                                                color: ThemeManager.black
                                                    .withOpacity(0.16))
                                          ]),
                                      child: Row(
                                        children: [
                                          Container(
                                            width:
                                                Dimensions.PADDING_SIZE_SMALL *
                                                    2.7,
                                            height:
                                                Dimensions.PADDING_SIZE_SMALL *
                                                    2.7,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                                color:
                                                    ThemeManager.blueFinalTrans,
                                                shape: BoxShape.circle),
                                            child: SvgPicture.asset(icon),
                                          ),
                                          const SizedBox(
                                            width:
                                                Dimensions.PADDING_SIZE_SMALL *
                                                    1.1,
                                          ),
                                          Expanded(
                                            child: Text(
                                              benefits,
                                              style: interRegular.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                                fontWeight: FontWeight.w500,
                                                color: ThemeManager.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(
                                  height: Dimensions.PADDING_SIZE_SMALL,
                                ),
                              ],
                            ),
                            material.ExpansionTile(
                              initiallyExpanded: false,
                              tilePadding: EdgeInsets.zero,
                              iconColor: ThemeManager.black,
                              collapsedIconColor: ThemeManager.black,
                              collapsedShape: Border(
                                  bottom: BorderSide(
                                      color:
                                          ThemeManager.black.withOpacity(0.2))),
                              shape: Border(
                                  bottom: BorderSide(
                                      color:
                                          ThemeManager.black.withOpacity(0.2))),
                              title: Text(
                                "Benefits:",
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeManager.black,
                                ),
                              ),
                              children: [
                                Html(
                                  data: '''
                                  <div style="color: ${ThemeManager.currentTheme == AppTheme.Dark ? 'white' : 'black'};">
                                  ${widget.subscription.description ?? ""}
                                  </div>
                                  ''',
                                )
                              ],
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                            Text(
                              "Select Duration",
                              style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                fontWeight: FontWeight.w600,
                                color: ThemeManager.black,
                              ),
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_DEFAULT),
                            Wrap(
                              spacing: Dimensions.PADDING_SIZE_DEFAULT * 1.1,
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
                                  subPlanOffer =
                                      subPlanOffer.replaceAll("%", "").trim();
                                  try {
                                    parsedOffer = double.parse(subPlanOffer);
                                  } catch (e) {
                                    print("Error parsing subPlanOffer: $e");
                                  }
                                }
                                double offerPrice = (subPlan?.price ?? 0) *
                                    ((100 - parsedOffer) / 100);
                                bool isSelected = index == _selectedIndex;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      formatTime(int.parse(subPlan?.day ?? "")),
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeExtraSmall,
                                        fontWeight: FontWeight.w400,
                                        color: ThemeManager.black,
                                      ),
                                    ),
                                    const SizedBox(
                                      height:
                                          Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                    ),
                                    material.InkWell(
                                      onTap: () {
                                        // String applePlanName='';
                                        setState(() {
                                          selectedPlanMonth = subPlan?.day;
                                          durationId = subPlan?.durationId;
                                          discountedPrice = offerPrice.toInt();
                                          originalPrice = subPlan?.price;
                                          _selectedIndex = index;
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? ThemeManager.blueFinal
                                              : material.Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: isSelected
                                                  ? material.Colors.transparent
                                                  : ThemeManager.black
                                                      .withOpacity(0.28)),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: Dimensions
                                                  .PADDING_SIZE_DEFAULT,
                                              vertical: Dimensions
                                                  .PADDING_SIZE_EXTRA_SMALL),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "₹ ${subPlan?.offer == null ? subPlan?.price : offerPrice.toStringAsFixed(0)}",
                                                style: interRegular.copyWith(
                                                  fontSize: isSelected
                                                      ? Dimensions.fontSizeLarge
                                                      : Dimensions
                                                          .fontSizeDefaultLarge,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: isSelected
                                                      ? ThemeManager.white
                                                      : ThemeManager.black,
                                                ),
                                              ),
                                              Text(
                                                'Inclusive GST',
                                                style: interRegular.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeExtraSmall,
                                                  fontWeight: FontWeight.w400,
                                                  color: isSelected
                                                      ? ThemeManager.white
                                                      : ThemeManager.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_DEFAULT * 2),
                            Observer(
                              builder: (BuildContext context) {
                                if (store.isLoading) {
                                  return Center(
                                    child: material.CircularProgressIndicator(
                                      color: ThemeManager.primaryColor,
                                    ),
                                  );
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Enter Coupon Code",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        fontWeight: FontWeight.w600,
                                        color: ThemeManager.black,
                                      ),
                                    ),
                                    const SizedBox(
                                        height:
                                            Dimensions.PADDING_SIZE_DEFAULT),
                                    SizedBox(
                                      height:
                                          Dimensions.PADDING_SIZE_EXTRA_LARGE *
                                              2,
                                      child: material.TextFormField(
                                        controller: couponController,
                                        cursorColor: ThemeManager.black,
                                        // controller: testNameController,
                                        // validator: (value) {
                                        //   if (value == null || value.isEmpty) {
                                        //     setState(() {
                                        //       isNameValid = false;
                                        //     });
                                        //     return 'Please enter name of test';
                                        //   }
                                        //   setState(() {
                                        //     isNameValid = true;
                                        //   });
                                        //   return null;
                                        // },
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          color: ThemeManager.black,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        decoration: material.InputDecoration(
                                          hintStyle: interRegular.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeDefault,
                                            color: ThemeManager.black,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          suffixIcon: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: Dimensions
                                                    .PADDING_SIZE_DEFAULT,
                                                vertical: Dimensions
                                                        .PADDING_SIZE_EXTRA_SMALL *
                                                    1.6),
                                            child: material.InkWell(
                                              onTap: () {
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
                                                        matchingCoupon
                                                                .discountPrize ??
                                                            0;
                                                    couponId =
                                                        matchingCoupon.sId;
                                                  } else {
                                                    couponController.clear();
                                                    BottomToast
                                                        .showBottomToastOverlay(
                                                      context: context,
                                                      errorMessage:
                                                          "Invalid Coupon Code",
                                                      backgroundColor:
                                                          material.Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .error,
                                                    );
                                                  }
                                                });
                                              },
                                              child: Container(
                                                width: Dimensions
                                                        .PADDING_SIZE_LARGE *
                                                    3,
                                                height: Dimensions
                                                        .PADDING_SIZE_SMALL *
                                                    2.7,
                                                decoration: BoxDecoration(
                                                    color:
                                                        ThemeManager.blueFinal,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            40)),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  apply == false
                                                      ? "Apply"
                                                      : "Applied",
                                                  style: interRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeExtraSmall,
                                                    fontWeight: FontWeight.w500,
                                                    color: ThemeManager.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          hintText: 'Enter Coupon Code',
                                          border: material.OutlineInputBorder(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                bottomLeft:
                                                    Radius.circular(3.4),
                                                bottomRight:
                                                    Radius.circular(3.4),
                                              ),
                                              borderSide: BorderSide(
                                                  color: ThemeManager.grey1,
                                                  width: 0.85)),
                                          disabledBorder:
                                              material.OutlineInputBorder(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    bottomLeft:
                                                        Radius.circular(3.4),
                                                    bottomRight:
                                                        Radius.circular(3.4),
                                                  ),
                                                  borderSide: BorderSide(
                                                      color: ThemeManager.grey1,
                                                      width: 0.85)),
                                          enabledBorder:
                                              material.OutlineInputBorder(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    bottomLeft:
                                                        Radius.circular(3.4),
                                                    bottomRight:
                                                        Radius.circular(3.4),
                                                  ),
                                                  borderSide: BorderSide(
                                                      color: ThemeManager.grey1,
                                                      width: 0.85)),
                                          focusedBorder:
                                              material.OutlineInputBorder(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                    bottomLeft:
                                                        Radius.circular(3.4),
                                                    bottomRight:
                                                        Radius.circular(3.4),
                                                  ),
                                                  borderSide: BorderSide(
                                                      color: ThemeManager.grey1,
                                                      width: 0.85)),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(
                                height:
                                    Dimensions.PADDING_SIZE_EXTRA_LARGE * 1.4),
                            Observer(builder: (context) {
                              if (store.isLoading) {
                                return Center(
                                  child: material.CircularProgressIndicator(
                                    color: ThemeManager.primaryColor,
                                  ),
                                );
                              }
                              if (store.getAllOfferUser.isEmpty) {
                                return const SizedBox();
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Offers",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeManager.black,
                                    ),
                                  ),
                                  const SizedBox(
                                      height:
                                          Dimensions.PADDING_SIZE_SMALL * 1.4),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: store.getAllOfferUser.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: Dimensions
                                                .PADDING_SIZE_DEFAULT),
                                        child: material.InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (_currentindex == index) {
                                                _currentindex = null;
                                                discountOffer = 0;
                                                apply = false;
                                              } else {
                                                _currentindex =
                                                    index; // Select the item
                                                offerId = store
                                                    .getAllOfferUser[index]
                                                    ?.sId;
                                                getOfferDiscount(store);
                                                apply =
                                                    true; // Make sure apply is set to true when an item is selected
                                              }
                                            });
                                          },
                                          child: Container(
                                              padding: const EdgeInsets.only(
                                                left: Dimensions
                                                    .PADDING_SIZE_SMALL,
                                                right: Dimensions
                                                        .PADDING_SIZE_DEFAULT *
                                                    2.2,
                                                top: Dimensions
                                                        .PADDING_SIZE_SMALL *
                                                    1.4,
                                                bottom: Dimensions
                                                        .PADDING_SIZE_SMALL *
                                                    1.4,
                                              ),
                                              decoration: BoxDecoration(
                                                  color: ThemeManager.white,
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  3.4),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  3.4)),
                                                  border: Border.all(
                                                    color: ThemeManager.grey1,
                                                  )),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: Dimensions
                                                        .PADDING_SIZE_LARGE,
                                                    height: Dimensions
                                                        .PADDING_SIZE_LARGE,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                        color:
                                                            ThemeManager.white,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                            color: const Color(
                                                                0xFFE6EAED),
                                                            width: 2)),
                                                    child: _currentindex ==
                                                            index
                                                        ? Container(
                                                            width: Dimensions
                                                                .PADDING_SIZE_SMALL,
                                                            height: Dimensions
                                                                .PADDING_SIZE_SMALL,
                                                            alignment: Alignment
                                                                .center,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: ThemeManager
                                                                  .primaryColor,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                          )
                                                        : const SizedBox(),
                                                  ),
                                                  const SizedBox(
                                                      width: Dimensions
                                                              .PADDING_SIZE_SMALL *
                                                          1.2),
                                                  Expanded(
                                                    child: Text(
                                                      store
                                                              .getAllOfferUser[
                                                                  index]
                                                              ?.description ??
                                                          '',
                                                      style:
                                                          interRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeSmall,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color:
                                                            ThemeManager.black,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            }),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_SMALL * 1.4),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                          vertical: Dimensions.PADDING_SIZE_LARGE),
                      color: ThemeManager.primaryColor,
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Payable Amount ",
                                style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(
                                  height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "₹ ${(discountedPrice - discountCoupon - discountOffer) + widget.totalAmount.toInt()}",
                                    style: interRegular.copyWith(
                                      fontSize:
                                          Dimensions.fontSizeExtraExtraLarge,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(
                                      width: Dimensions.PADDING_SIZE_SMALL),
                                  Text(
                                    "inclusive GST",
                                    style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeExtraSmall,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.white,
                                        height: 0),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: Dimensions.PADDING_SIZE_LARGE * 2.4,
                          ),
                          if (!(Platform.isWindows || Platform.isMacOS)) ...[
                            Expanded(
                              child: material.InkWell(
                                onTap: () {
                                  if (Platform.isMacOS || Platform.isWindows) {
                                    material.showDialog<void>(
                                        context: context,
                                        barrierDismissible:
                                            false, // Set to false if you don't want the dialog to be dismissed by tapping outside
                                        builder: (BuildContext context) {
                                          return material.Dialog(
                                            backgroundColor:
                                                material.Colors.transparent,
                                            child: confirm(store, uniqueBooks),
                                          );
                                        });
                                  } else {
                                    material.showModalBottomSheet<void>(
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(25),
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAliasWithSaveLayer,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return confirm(store, uniqueBooks);
                                      },
                                    );
                                  }
                                },
                                child: Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 400),
                                  alignment: Alignment.center,
                                  height: Dimensions.PADDING_SIZE_LARGE * 2.2,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Purchase Now",
                                    style: interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      fontWeight: FontWeight.w700,
                                      color: ThemeManager.primaryBlack,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if ((Platform.isWindows || Platform.isMacOS)) ...[
                            const Spacer(),
                            material.InkWell(
                              onTap: () {
                                if (Platform.isMacOS || Platform.isWindows) {
                                  material.showDialog<void>(
                                      context: context,
                                      barrierDismissible:
                                          false, // Set to false if you don't want the dialog to be dismissed by tapping outside
                                      builder: (BuildContext context) {
                                        return material.Dialog(
                                          backgroundColor:
                                              material.Colors.transparent,
                                          child: confirm(store, uniqueBooks),
                                        );
                                      });
                                } else {
                                  material.showModalBottomSheet<void>(
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(25),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return confirm(store, uniqueBooks);
                                    },
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                    horizontal: 100),
                                alignment: Alignment.center,
                                height: Dimensions.PADDING_SIZE_LARGE * 2.2,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Purchase Now",
                                  style: interRegular.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeManager.primaryBlack,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
             ),
            ],
          ),
        ),
    );
  }

  Widget confirm(store, uniqueBooks) {
    return FractionallySizedBox(
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
              color: ThemeManager.white,
              borderRadius: (Platform.isMacOS || Platform.isWindows)
                  ? BorderRadius.circular(15)
                  : null),
          // height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              const SizedBox(
                height: Dimensions.PADDING_SIZE_LARGE,
              ),
              if (!(Platform.isMacOS || Platform.isWindows)) ...[
                Container(
                  width: Dimensions.PADDING_SIZE_LARGE * 2,
                  height: 2,
                  decoration: BoxDecoration(
                      color: const Color(0xFFCDCDCD),
                      borderRadius: BorderRadius.circular(
                          Dimensions.PADDING_SIZE_LARGE * 2)),
                ),
                const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: !(Platform.isMacOS || Platform.isWindows)
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Confirm Your Purchase',
                      style: interSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeDefaultLarge,
                        fontWeight: FontWeight.w600,
                        color: ThemeManager.black,
                      ),
                    ),
                    if (Platform.isMacOS || Platform.isWindows) ...[
                      material.InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: material.Icon(
                          material.Icons.close,
                          color: ThemeManager.black,
                        ),
                      )
                    ]
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.PADDING_SIZE_DEFAULT),
                child: Column(
                  children: [
                    const SizedBox(height: Dimensions.PADDING_SIZE_SMALL * 1.7),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Order details',
                        style: interSemiBold.copyWith(
                          fontSize: Dimensions.fontSizeDefaultLarge,
                          fontWeight: FontWeight.w500,
                          color: ThemeManager.black,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: ListView(
                        children: [
                          const SizedBox(
                              height: Dimensions.PADDING_SIZE_SMALL * 1.6),
                          Container(
                            padding: const EdgeInsets.all(
                                Dimensions.PADDING_SIZE_LARGE),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: ThemeManager.blueFinal, width: 0.84),
                              borderRadius: BorderRadius.circular(33.44),
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                    "assets/image/confirmTick.svg"),
                                const SizedBox(
                                    width: Dimensions.PADDING_SIZE_SMALL),
                                Text(
                                  widget.subscription.plan_name ?? '',
                                  style: interSemiBold.copyWith(
                                    fontSize: Dimensions.fontSizeSmallLarge,
                                    fontWeight: FontWeight.w500,
                                    color: ThemeManager.black,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '₹ ${(discountedPrice - discountCoupon - discountOffer)}',
                                  style: interSemiBold.copyWith(
                                    fontSize: Dimensions.fontSizeSmallLarge,
                                    fontWeight: FontWeight.w500,
                                    color: ThemeManager.textColor3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              children:
                                  List.generate(uniqueBooks.length, (index) {
                                Map<String, dynamic> bookDetails =
                                    uniqueBooks[index];
                                int bookQuantity = bookDetails['quantity'];
                                return Container(
                                  margin: const EdgeInsets.only(
                                      top: Dimensions.PADDING_SIZE_SMALL),
                                  padding: const EdgeInsets.all(
                                      Dimensions.PADDING_SIZE_LARGE),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: ThemeManager.blueFinal,
                                        width: 0.84),
                                    borderRadius: BorderRadius.circular(33.44),
                                  ),
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                          "assets/image/confirmTick.svg"),
                                      const SizedBox(
                                          width: Dimensions.PADDING_SIZE_SMALL),
                                      Text(
                                        bookDetails['bookName'],
                                        style: interSemiBold.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "₹ ${bookDetails['price'].toInt() * bookQuantity}",
                                        style: interSemiBold.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeSmallLarge,
                                          fontWeight: FontWeight.w500,
                                          color: ThemeManager.textColor3,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(
                              height: Dimensions.PADDING_SIZE_DEFAULT * 2),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Address details',
                        style: interSemiBold.copyWith(
                          fontSize: Dimensions.fontSizeDefaultLarge,
                          fontWeight: FontWeight.w500,
                          color: ThemeManager.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.PADDING_SIZE_SMALL * 1.6),
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(
                              left: Dimensions.PADDING_SIZE_SMALL * 1.8,
                              right: Dimensions.PADDING_SIZE_SMALL * 1.4,
                              top: Dimensions.PADDING_SIZE_LARGE,
                              bottom: Dimensions.PADDING_SIZE_LARGE),
                          decoration: BoxDecoration(
                              color: ThemeManager.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFE6EAED),
                              ),
                              boxShadow: [
                                BoxShadow(
                                    offset: const Offset(0, 1),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                    color: ThemeManager.black.withOpacity(0.05))
                              ]),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(
                                    top: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                                width: Dimensions.PADDING_SIZE_LARGE,
                                height: Dimensions.PADDING_SIZE_LARGE,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: ThemeManager.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFFE6EAED),
                                        width: 2)),
                                child: Container(
                                  width: Dimensions.PADDING_SIZE_SMALL,
                                  height: Dimensions.PADDING_SIZE_SMALL,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: ThemeManager.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                  width: Dimensions.PADDING_SIZE_LARGE),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.address.name ?? '',
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        fontWeight: FontWeight.w400,
                                        color: ThemeManager.black,
                                      ),
                                    ),
                                    Text(
                                      [
                                        widget.address.buildingNumber,
                                        widget.address.landMark,
                                        widget.address.city,
                                        widget.address.state,
                                        widget.address.pincode,
                                      ].where((element) => true).join(", "),
                                      // "A-403 Orient apartment, Vastrtal, Ahmedabad, Gujarat, 380058 India",
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        fontWeight: FontWeight.w400,
                                        color:
                                            ThemeManager.black.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                            top: Dimensions.PADDING_SIZE_SMALL,
                            right: Dimensions.PADDING_SIZE_SMALL * 1.4,
                            child: SvgPicture.asset(
                                "assets/image/editAddress.svg"))
                      ],
                    ),
                    const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                    material.InkWell(
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(Routes.addressDetailScreen, arguments: {
                          'subscription': widget.subscription,
                          'store': widget.store,
                          'totalAmount': widget.totalAmount,
                          'selectedBooks': widget.selectedBooks,
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.PADDING_SIZE_DEFAULT),
                        decoration: BoxDecoration(
                          color: ThemeManager.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFE6EAED),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset("assets/image/confirmPlus.svg"),
                            Text(
                              ' Add Address',
                              style: interSemiBold.copyWith(
                                fontSize: Dimensions.fontSizeSmallLarge,
                                fontWeight: FontWeight.w400,
                                color: ThemeManager.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.PADDING_SIZE_LARGE),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                    vertical: Dimensions.PADDING_SIZE_LARGE),
                decoration: BoxDecoration(
                    color: ThemeManager.primaryColor,
                    borderRadius: (Platform.isMacOS || Platform.isWindows)
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(15))
                        : null),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Payable Amount ",
                          style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            fontWeight: FontWeight.w400,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(
                            height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹ ${(discountedPrice - discountCoupon - discountOffer) + widget.totalAmount.toInt()}",
                              style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeExtraExtraLarge,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(
                                width: Dimensions.PADDING_SIZE_SMALL),
                            Text(
                              "inclusive GST",
                              style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.white,
                                  height: 0),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(
                      width: Dimensions.PADDING_SIZE_LARGE * 2.4,
                    ),
                    Expanded(
                      child: material.InkWell(
                        onTap: () {
                          loggedIn == true
                              ? _startPayment(store)
                              : Navigator.of(context).pushNamed(Routes.login);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: Dimensions.PADDING_SIZE_LARGE * 2.2,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Purchase Now",
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              fontWeight: FontWeight.w700,
                              color: ThemeManager.primaryBlack,
                            ),
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
      ),
    );
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

    // debugPrint("discountPercentage: $discountPercentage");
    // debugPrint("discountPrize: $discountPrize");

    if (discountPrize != 0) {
      discountOffer = discountPrize.toInt();
    } else {
      discountOffer = (discountedPrice * ((discountPercentage / 100))).toInt();
      // (discountedPrice * (1 - (discountPercentage / 100))).toInt();
    }
  }

  Future<void> _startPayment(SubscriptionStore store) async {
    if (Platform.isIOS || Platform.isMacOS) {
      final loginStore = Provider.of<LoginStore>(context, listen: false);
      if (loginStore.settingsData.value == null) {
        await loginStore.onGetSettingsData();
      }
      final bool isIAPEnabled =
          loginStore.settingsData.value?.isInAPurchases == true;
      if (isIAPEnabled) {
        // Use in-app purchase for iOS/macOS when enabled in settings
        await _handleApplePurchase(store);
      } else {
        // Show mobile app purchase dialog when IAP is disabled for iOS/macOS
        material.showDialog(
          context: context,
          builder: (_) => SubscriptionDialog(),
        );
      }
    } else {
      // Use existing Razorpay flow for other platforms
      await _startRazorpayPayment(store);
    }
  }

  Future<void> _handleApplePurchase(SubscriptionStore store) async {
    try {
      // Initialize in-app purchase if not already done
      bool isAvailable = await AppleInAppPurchase.initialize();
      
      if (!isAvailable) {
        // Fallback to web-based purchase or show error
        _showApplePurchaseError();
        return;
      }
      
      // Find the product that matches the selected subscription
      var product = _findMatchingProduct();
      
      if (product != null) {
        bool success = await AppleInAppPurchase.purchaseProduct(
          product,
          onSuccess: (purchaseDetails) async {
            await _handleApplePurchaseSuccess(purchaseDetails, store);
          },
          onError: (message) {
            _showApplePurchaseError();
          },
        );
        if (!success) {
          _showApplePurchaseError();
        }
      } else {
        _showApplePurchaseError();
      }
    } catch (e) {
      print('Error in Apple in-app purchase: $e');
      _showApplePurchaseError();
    }
  }

  Future<void> _handleApplePurchaseSuccess(dynamic details, SubscriptionStore store) async {
    try {
      final String? subscriptionId = widget.subscription.sid;
      final String? month = selectedPlanMonth;
      final String? durationid = durationId;
      // Align amount calculation with Razorpay order creation
      final int amount = (discountedPrice - discountCoupon - discountOffer) + widget.totalAmount.toInt();
      final double planDiscountAmount = (discountCoupon + discountOffer).toDouble();

      if (subscriptionId == null) {
        _showApplePurchaseError();
        return;
      }

      await store.onCreateAppleInAppPurchaseOrder(
        planId: subscriptionId,
        amount: amount,
        day: int.tryParse(month ?? '') ?? 0,
        durationId: durationid,
      );

      // Consume single-use offer if applied
      if (_currentindex != null) {
        final bool isSingleUse = store.getAllOfferUser[_currentindex!]?.isSingleUse == true;
        if (isSingleUse) {
          final String? offerid = offerId;
          if (offerid != null && offerid.isNotEmpty) {
            await store.onPurcaseUserOfferApiCall(offerid);
          }
        }
      }

      Navigator.of(context).pushNamed(Routes.paymentStatus, arguments: {
        'amount': amount,
        'dateTime': DateTime.now(),
        'paymentId': details?.purchaseID ?? details?.productID,
      });
    } catch (e) {
      print('Error processing Apple in-app purchase: $e');
      _showApplePurchaseError();
    }
  }

  dynamic _findMatchingProduct() {
    // Map your subscription to Apple product IDs
    String productId = _getProductIdForSubscription();
    
    var products = AppleInAppPurchase.products;
    try {
      return products.firstWhere((product) => product.id == productId);
    } catch (e) {
      print('Product not found: $productId');
      return null;
    }
  }

  String _getProductIdForSubscription() {
    // Map your subscription details to Apple product IDs
    // This should match what you configure in App Store Connect
    if (Platform.isIOS) {
      return '6751168008'; // iOS product ID
    } else if (Platform.isMacOS) {
      return '6751168007'; // macOS product ID
    }
    return '6751168007'; // fallback
  }

  void _showApplePurchaseError() {
    material.showDialog(
      context: context,
      builder: (context) => material.AlertDialog(
        title: material.Text('Purchase Unavailable'),
        content: material.Text('In-app purchase is not available. Please try again later.'),
        actions: [
          material.TextButton(
            onPressed: () => Navigator.pop(context),
            child: material.Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _startRazorpayPayment(SubscriptionStore store) async {
    await store.onGetPaymentDetails(context);
    String apiKey =
        store.paymentDetails.value?.razorpayKey ?? "rzp_test_mV7hVxiuC3ljvo";
    String apiSecret = store.paymentDetails.value?.razorpaySecretKey ??
        "sFN1bvTqaGVSPpA2kVfTk2q5";
    debugPrint('razorapikey$apiKey');

    Map<String, dynamic> paymentData = {
      'amount': ((discountedPrice - discountCoupon - discountOffer) +
              widget.totalAmount.toInt()) *
          100,
      'currency': 'INR',
      'receipt': 'order_receipt',
      'payment_capture': '1',
    };

    String apiUrl = 'https://api.razorpay.com/v1.0/orders';
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

      if (kIsWeb || Platform.isWindows) {
        // Open in-app webview for desktop platforms (excluding macOS)
        Navigator.of(context).push(material.MaterialPageRoute(
            builder: (context) => PaymentPage(
                apiKey: store.paymentDetails.value?.razorpayKey ?? "rzp_test_mV7hVxiuC3ljvo",
                orderId: responseData['id'])));
      } else {
        // Use InAppWebView for mobile platforms (iOS/Android)
        RazorpayPayment.openCheckout(
          apiKey: store.paymentDetails.value?.razorpayKey ?? "rzp_test_mV7hVxiuC3ljvo",
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
    String? month = selectedPlanMonth;
    int amount = (discountedPrice - discountCoupon - discountOffer) +
        widget.totalAmount.toInt();
    String? subscriptionId = widget.subscription.sid;
    String? durationid = durationId;
    String? offerid = offerId;
    List bookPrize =
        widget.selectedBooks.map((e) => e['price'].toInt()).toList();
    List bookIds = widget.selectedBooks.map((e) => e['bookId']).toList();
    await store.onPurcaseSubscriptionApiCall(
        subscriptionId!,
        amount,
        month ?? "",
        durationid ?? "",
        response.paymentId!,
        response.orderId!,
        response.signature!,
        couponId ?? '',
        offerid ?? '');
    await store.onPurcaseBookApiCall(
        widget.address.sId ?? '', bookPrize, bookIds);
    if (_currentindex != null) {
      store.getAllOfferUser[_currentindex!]?.isSingleUse == true
          ? await store.onPurcaseUserOfferApiCall(offerid ?? '')
          : null;
    }
    RazorpayPayment.dispose();

    Navigator.of(context).pushNamed(Routes.paymentStatus, arguments: {
      'amount': amount,
      'dateTime': DateTime.now(),
      'paymentId': response.paymentId
    });
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    int amount = (discountedPrice - discountCoupon - discountOffer) +
        widget.totalAmount.toInt();

    Navigator.of(context).pushNamed(Routes.paymentFailed, arguments: {
      'amount': amount,
      'dateTime': DateTime.now(),
    });
  }

  void showAlertDialog(BuildContext context, String title, String message) {
    Widget continueButton = material.ElevatedButton(
      child: const Text("Continue"),
      onPressed: () {
        Navigator.of(context).pushNamed(Routes.dashboard);
      },
    );
    material.AlertDialog alert = material.AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        continueButton,
      ],
    );
    material.showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void _handlePaymentSuccess1(Uri url) {
    // Assuming the success URL contains query parameters with payment details
    // e.g., https://your-success-url.com?payment_id=pay_29QQoUBi66xm2f&order_id=order_DslnoIgkIDL8Zt&signature=...
    if (url.queryParameters.containsKey('payment_id') &&
        url.queryParameters.containsKey('order_id') &&
        url.queryParameters.containsKey('signature')) {
      String paymentId = url.queryParameters['payment_id'] ?? '';
      String orderId = url.queryParameters['order_id'] ?? '';
      String signature = url.queryParameters['signature'] ?? '';

      // Proceed with the next steps, e.g., calling your backend API to verify the payment
      debugPrint(
          'Payment Success: Payment ID - $paymentId, Order ID - $orderId');

      // You can also show a success dialog or navigate to the success screen
      showAlertDialog(
          context, 'Payment Success', 'Your payment was successful!');

      // Optionally, call your backend API to verify the payment and update records
      // For example, using a method like `verifyPaymentOnServer(paymentId, orderId, signature);`
    } else {
      // If expected parameters are not found, handle the scenario appropriately
      debugPrint('Payment success URL does not contain required parameters.');
      showAlertDialog(
          context, 'Error', 'Unexpected response from the payment gateway.');
    }
  }

  void _handlePaymentFailure1() {
    // Show an alert or navigate to the payment failed screen
    // This can be based on observing a certain URL pattern or a response status
    debugPrint('Payment failed. Redirecting to failure screen.');

    showAlertDialog(context, 'Payment Failed',
        'Your payment was not successful. Please try again.');

    // Optionally navigate to a failure screen or retry logic
    Navigator.of(context).pushNamed(Routes.paymentFailed);
  }
}
