// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, unused_field, unused_local_variable, dead_null_aware_expression, prefer_interpolation_to_compose_strings, use_build_context_synchronously, avoid_unnecessary_containers, library_private_types_in_public_api, duplicate_ignore, unused_element, avoid_print, unnecessary_string_interpolations, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/models/subscription_model.dart';
import 'package:shusruta_lms/modules/subscriptionplans/razorpay_payment.dart';
import 'package:shusruta_lms/modules/subscriptionplans/select_bottom_hardcopy_bottom_sheet.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';
import 'package:shusruta_lms/modules/subscriptionplans/macos_in_app_purchase.dart';
import 'package:http/http.dart' as http;
import 'package:shusruta_lms/modules/subscriptionplans/web_payment_page.dart';
import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';
import 'package:shusruta_lms/modules/login/store/login_store.dart';
import 'package:shusruta_lms/modules/widgets/subscription_dialog.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  final SubscriptionModel subscription;
  final SubscriptionStore store;
  const SubscriptionDetailScreen(
      {super.key, required this.subscription, required this.store});

  @override
  State<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SubscriptionDetailScreen(
        subscription: arguments["subscription"],
        store: arguments["store"],
      ),
    );
  }
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
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
  bool isFixValidity = false;
  double fixedOfferPrice=0;
  String? formattedDate="";

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

    String? fixedPlanOffer = widget.subscription.fixedValidityPlan?.offer?.replaceAll("%", "");
    double parsedFixedOffer = 0;
    if (fixedPlanOffer != null && fixedPlanOffer.isNotEmpty) {
      fixedPlanOffer = fixedPlanOffer.replaceAll("%", "").trim();
      try {
        parsedFixedOffer = double.parse(fixedPlanOffer);
      } catch (e) {
        print("Error parsing fixedPlanOffer: $e");
      }
    }
    fixedOfferPrice = (widget.subscription.fixedValidityPlan?.price ?? 0) * ((100 - parsedFixedOffer) / 100);
    formattedDate = widget.subscription.fixedValidityPlan?.toTime != null
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(widget.subscription.fixedValidityPlan?.toTime??""))
        : '';
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
      // appBar:  material.AppBar(
      //   elevation: 0,
      //   automaticallyImplyLeading: false,
      //   backgroundColor:  ThemeManager.white,
      //   leading: Padding(
      //     padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_SMALL),
      //     child:  material.      IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
      //       icon:  Icon( material.Icons.arrow_back_ios, color: ThemeManager.iconColor),
      //       onPressed: () {
      //         Navigator.pop(context);
      //       },
      //     ),
      //   ),
      //   title: Row(
      //     mainAxisAlignment: MainAxisAlignment.start,
      //     children: [
      //       const SizedBox(width: Dimensions.PADDING_SIZE_LARGE),
      //       SvgPicture.asset("assets/image/bookmark_plan.svg"),
      //       const SizedBox(
      //         width: Dimensions.PADDING_SIZE_LARGE,
      //       ),
      //       Text(
      //         widget.subscription.plan_name??"",
      //         style: interRegular.copyWith(
      //           fontSize: Dimensions.fontSizeLarge,
      //           fontWeight: FontWeight.w500,
      //           color:  ThemeManager.black,
      //         ),
      //       )
      //     ],
      //   ),
      // ),
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
                          topLeft: Radius.circular(28.8),
                          topRight: Radius.circular(28.8),
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
                            material.InkWell(
                              onTap: () {
                                if (Platform.isAndroid || Platform.isIOS) {
                                  // For mobile platforms, show the bottom sheet
                                  material.showModalBottomSheet<void>(
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(25),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return SelectHardCopyNotesBottomSheet(
                                        subscription: widget.subscription,
                                        store: widget.store,
                                      );
                                    },
                                  );
                                } else if (Platform.isMacOS ||
                                    Platform.isWindows) {
                                  // For desktop platforms, show the dialog
                                  material.showDialog<void>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return material.Dialog(
                                        backgroundColor: material.Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                        child: SelectHardCopyNotesBottomSheet(
                                          subscription: widget.subscription,
                                          store: widget.store,
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.only(
                                  top: Dimensions.PADDING_SIZE_LARGE * 1.1,
                                  left: Dimensions.PADDING_SIZE_LARGE * 1.2,
                                  right: Dimensions.PADDING_SIZE_SMALL * 1.9,
                                ),
                                decoration: BoxDecoration(
                                  color: ThemeManager.black,
                                  borderRadius: BorderRadius.circular(14.25),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                        "assets/image/hardNotes.svg"),
                                    const SizedBox(
                                      width:
                                          Dimensions.PADDING_SIZE_SMALL * 1.8,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Add Hardcopy Notes ",
                                          style: interRegular.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeDefaultLarge,
                                            fontWeight: FontWeight.w600,
                                            color: ThemeManager.white,
                                          ),
                                        ),
                                        const SizedBox(
                                            height: Dimensions
                                                .PADDING_SIZE_EXTRA_SMALL),
                                        Text(
                                          "Elevate your learning with our clear, \nconcise hardcopy notes designed \nfor optimal understanding.",
                                          style: interRegular.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeExtraSmall,
                                            fontWeight: FontWeight.w400,
                                            color: ThemeManager.white
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                        const SizedBox(
                                            height:
                                                Dimensions.PADDING_SIZE_SMALL),
                                      ],
                                    ),
                                    const SizedBox(
                                      width:
                                          Dimensions.PADDING_SIZE_EXTRA_SMALL *
                                              1.2,
                                    ),
                                    Container(
                                        height:
                                            Dimensions.PADDING_SIZE_LARGE * 2,
                                        width:
                                            Dimensions.PADDING_SIZE_LARGE * 2,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: ThemeManager.white
                                              .withOpacity(0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Container(
                                          height:
                                              Dimensions.PADDING_SIZE_DEFAULT *
                                                  2,
                                          width:
                                              Dimensions.PADDING_SIZE_DEFAULT *
                                                  2,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: ThemeManager.white
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            material
                                                .Icons.arrow_forward_rounded,
                                            color: ThemeManager.white,
                                          ),
                                        ))
                                  ],
                                ),
                              ),
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
                                // SizedBox(
                                //   width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 9,
                                //   child: ListView.builder(
                                //     itemCount: widget.subscription.benifit?.length,
                                //     shrinkWrap: true,
                                //     padding: EdgeInsets.zero,
                                //     itemBuilder: (BuildContext context, int index) {
                                //       String? benefits = widget.subscription.benifit![index];
                                //       // return Padding(
                                //       //   padding: const EdgeInsets.only(top: 8.0),
                                //       //   child: Text(
                                //       //     '$benefits',
                                //       //     style: interRegular.copyWith(
                                //       //       fontSize: Dimensions.fontSizeSmall,
                                //       //       fontWeight: FontWeight.w400,
                                //       //       color:  material.Theme.of(context).hintColor,
                                //       //     ),
                                //       //   ),
                                //       // );
                                //       return Container(
                                //         padding: const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_EXTRA_SMALL*1.6,vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                                //         decoration: BoxDecoration(
                                //           color: ThemeManager.white,
                                //           border: Border.all(
                                //             color: ThemeManager.black.withOpacity(0.28),
                                //           ),
                                //           boxShadow: [
                                //             BoxShadow(
                                //               offset: Offset(0, 1.85),
                                //               blurRadius: 12.94,
                                //               spreadRadius: -6.47,
                                //               color: ThemeManager.black.withOpacity(0.16)
                                //             )
                                //           ]
                                //         ),
                                //         child: Row(
                                //           children: [
                                //             Container(
                                //               width: 26.8,
                                //               height: 26.8,
                                //               decoration: BoxDecoration(
                                //                 color: ThemeManager.blueFinal,
                                //                 shape: BoxShape.circle
                                //               ),
                                //             ),
                                //             const SizedBox(width: Dimensions.PADDING_SIZE_SMALL*1.1,),
                                //             Flexible(
                                //               child: Text(
                                //                 "$benefits",
                                //                 style: interRegular.copyWith(
                                //                   fontSize: Dimensions.fontSizeSmall,
                                //                   fontWeight: FontWeight.w500,
                                //                   color:ThemeManager.black,
                                //                 ),
                                //               ),
                                //             ),
                                //           ],
                                //         ),
                                //       );
                                //     },
                                //   ),
                                // ),
                              ],
                            ),
                            // Row(
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   children: [
                            //     Column(
                            //       crossAxisAlignment: CrossAxisAlignment.start,
                            //       children: [
                            //         Text(
                            //           "What you will get:",
                            //           style: interRegular.copyWith(
                            //             fontSize: Dimensions.fontSizeLarge,
                            //             fontWeight: FontWeight.w500,
                            //             color:  ThemeManager.black,
                            //           ),
                            //         ),
                            //         const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                            //         SizedBox(
                            //           width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 9,
                            //           child: ListView.builder(
                            //             itemCount: widget.subscription.benifit?.length,
                            //             shrinkWrap: true,
                            //             padding: EdgeInsets.zero,
                            //             itemBuilder: (BuildContext context, int index) {
                            //               String? benefits = widget.subscription.benifit![index];
                            //               return Padding(
                            //                 padding: const EdgeInsets.only(top: 8.0),
                            //                 child: Text(
                            //                   '\u2022 $benefits',
                            //                   style: interRegular.copyWith(
                            //                     fontSize: Dimensions.fontSizeSmall,
                            //                     fontWeight: FontWeight.w400,
                            //                     color:  material.Theme.of(context).hintColor,
                            //                   ),
                            //                 ),
                            //               );
                            //             },
                            //           ),
                            //         ),
                            //       ],
                            //     ),
                            //     ///offer
                            //     // Container(
                            //     //   decoration: BoxDecoration(
                            //     //     color: Theme.of(context).primaryColor,
                            //     //     borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT)
                            //     //   ),
                            //     //   child: Padding(
                            //     //     padding: const EdgeInsets.only(left: 10,right: 10,top: 6,bottom: 6),
                            //     //     child: Text("Offer 50% off",
                            //     //       style: interRegular.copyWith(
                            //     //         fontSize: Dimensions.fontSizeExtraSmall,
                            //     //         fontWeight: FontWeight.w400,
                            //     //         color: ThemeManager.white,
                            //     //       ),),
                            //     //   ),
                            //     // )
                            //   ],
                            // ),
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
                            // const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                            // Text(
                            //   widget.subscription.description??"",
                            //   style: interRegular.copyWith(
                            //     fontSize: Dimensions.fontSizeSmall,
                            //     fontWeight: FontWeight.w400,
                            //     color:  ThemeManager.black,
                            //   ),
                            // ),
                            // const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                            // Text(
                            //   "There are many variations of passages of Lorem Ipsum available, but the majority have suffered alteration in some form",
                            //   style: interRegular.copyWith(
                            //     fontSize: Dimensions.fontSizeSmall,
                            //     fontWeight: FontWeight.w400,
                            //     color: ThemeManager.black,
                            //   ),
                            // ),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                            Text(
                              "Select Duration",
                              style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefaultLarge,
                                fontWeight: FontWeight.w700,
                                color: ThemeManager.black,
                              ),
                            ),
                            const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                            // SizedBox(
                            //   width: MediaQuery.of(context).size.width,
                            //   child: GridView.builder(
                            //     shrinkWrap: true,
                            //     itemCount: widget.subscription.duration?.length,
                            //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            //       crossAxisCount: 2,
                            //       crossAxisSpacing: 20.0,
                            //       mainAxisSpacing: 20.0,
                            //       childAspectRatio: (MediaQuery.of(context).size.width / 2 - 20.0) / (MediaQuery.of(context).size.height / 10),
                            //     ),
                            //     itemBuilder: (context, index) {
                            //       Durations? subPlan = widget.subscription.duration?[index];
                            //       String? subPlanOffer = subPlan?.offer?.replaceAll("%", "");
                            //       double parsedOffer = 0;
                            //       if (subPlanOffer != null && subPlanOffer.isNotEmpty) {
                            //         subPlanOffer = subPlanOffer.replaceAll("%", "").trim();
                            //         try {
                            //           parsedOffer = double.parse(subPlanOffer);
                            //         } catch (e) {
                            //           print("Error parsing subPlanOffer: $e");
                            //         }
                            //       }
                            //       double offerPrice = (subPlan?.price ?? 0) * ((100 - parsedOffer) / 100);
                            //       bool isSelected = index == _selectedIndex;
                            //       return FractionallySizedBox(
                            //         widthFactor: 1,
                            //         heightFactor: 1,
                            //         child:  Column(
                            //           crossAxisAlignment: CrossAxisAlignment.start,
                            //           children: [
                            //             Text(
                            //               formatTime(int.parse(subPlan?.day??"")),
                            //               style: interRegular.copyWith(
                            //                 fontSize: Dimensions.fontSizeDefault,
                            //                 fontWeight: FontWeight.w400,
                            //                 color: ThemeManager.black,
                            //               ),
                            //             ),
                            //             material.InkWell(
                            //               onTap: (){
                            //                 // String applePlanName='';
                            //                 setState(() {
                            //                   selectedPlanMonth = subPlan?.day;
                            //                   durationId = subPlan?.durationId;
                            //                   discountedPrice = offerPrice.toInt();
                            //                   originalPrice = subPlan?.price;
                            //                   // if (selectedPlanMonth != null) {
                            //                   //   applePlanName = '${widget.subscription.plan_name??""} - ${formatTime(int.parse(selectedPlanMonth??""))}';
                            //                   // }
                            //                   _selectedIndex = index;
                            //                   // _paymentItems.add(
                            //                   //   PaymentItem(
                            //                   //     label: applePlanName,
                            //                   //     amount: discountedPrice.toString(),
                            //                   //     status: PaymentItemStatus.final_price,
                            //                   //   ));
                            //                 });
                            //               },
                            //               child: Container(
                            //                 decoration: BoxDecoration(
                            //                   color: isSelected ?  ThemeManager.blueFinal : material.Colors.transparent,
                            //                   borderRadius: BorderRadius.circular(4),
                            //                   border: Border.all(color: isSelected ? material.Colors.transparent : ThemeManager.black.withOpacity(0.28)),
                            //                 ),
                            //                 child: Padding(
                            //                   padding: const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT),
                            //                   child: Column(
                            //                     crossAxisAlignment: CrossAxisAlignment.center,
                            //                     mainAxisAlignment: MainAxisAlignment.center,
                            //                     children: [
                            //                       Text(
                            //                         "₹ ${subPlan?.offer == null ? subPlan?.price : offerPrice.toStringAsFixed(0)}",
                            //                         style: interRegular.copyWith(
                            //                           fontSize: Dimensions.fontSizeLarge,
                            //                           fontWeight: FontWeight.w700,
                            //                           color: isSelected ?  material.Colors.white :  (ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white : ThemeManager.black),
                            //                         ),
                            //                       ),
                            //                       // const SizedBox(width: Dimensions.PADDING_SIZE_SMALL,),
                            //                       // subPlan?.offer==""?Container():
                            //                       // Text(
                            //                       //   "₹ ${subPlan?.price}",
                            //                       //   style: interRegular.copyWith(
                            //                       //     fontSize: Dimensions.fontSizeDefault,
                            //                       //     fontWeight: FontWeight.w600,
                            //                       //     color: isSelected ?  ThemeManager.white :  (ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white : ThemeManager.black),
                            //                       //     decoration: TextDecoration.lineThrough,
                            //                       //   ),
                            //                       // ),
                            //                       Text(
                            //                         '+ 18% GST',
                            //                         style: interRegular.copyWith(
                            //                           fontSize: Dimensions.fontSizeExtraSmall,
                            //                           fontWeight: FontWeight.w400,
                            //                           color: isSelected ?  material.Colors.white :  (ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white : ThemeManager.black),
                            //                         ),
                            //                       ),
                            //                     ],
                            //                   ),
                            //                 ),
                            //               ),
                            //             ),
                            //           ],
                            //         ),
                            //       );
                            //     },
                            //   ),
                            // ),
                            Wrap(
                              spacing: Dimensions.PADDING_SIZE_DEFAULT * 1.1,
                              children: List.generate(
                                widget.subscription.duration?.length ?? 0,
                                    (index) {
                                  Durations? subPlan = widget.subscription.duration?[index];
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
                                  bool isSelected = index == _selectedIndex;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        formatTime(int.parse(subPlan?.day ?? "")),
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          fontWeight: FontWeight.w400,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                      ),
                                      material.InkWell(
                                        onTap: () {
                                          setState(() {
                                            selectedPlanMonth = subPlan?.day;
                                            durationId = subPlan?.durationId;
                                            discountedPrice = offerPrice.toInt();
                                            originalPrice = subPlan?.price;
                                            _selectedIndex = index;
                                            isFixValidity = false;
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isSelected ? ThemeManager.blueFinal : material.Colors.transparent,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: isSelected
                                                  ? material.Colors.transparent
                                                  : ThemeManager.black.withOpacity(0.28),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                                              vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                if (subPlan?.offer != null)
                                                  Text(
                                                    "₹ ${subPlan?.price}",
                                                    style: interRegular.copyWith(
                                                      fontSize: Dimensions.fontSizeDefaultLarge,
                                                      fontWeight: FontWeight.w500,
                                                      color: isSelected ? ThemeManager.white : ThemeManager.black.withOpacity(0.8),
                                                      decoration: TextDecoration.lineThrough,
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "₹ ${subPlan?.offer == null ? subPlan?.price : offerPrice.toStringAsFixed(0)}",
                                                  style: interRegular.copyWith(
                                                    fontSize: isSelected ? Dimensions.fontSizeLarge : Dimensions.fontSizeDefaultLarge,
                                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                    color: isSelected ? ThemeManager.white : ThemeManager.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                            if (widget.subscription.fixedValidityPlan?.price != 0)
                              Wrap(
                                spacing: Dimensions.PADDING_SIZE_DEFAULT * 1.1,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${widget.subscription.fixedValidityPlan?.text} - $formattedDate",
                                        style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeDefaultLarge,
                                          fontWeight: FontWeight.w700,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                      ),
                                      material.InkWell(
                                        onTap: () {
                                          String? fixedPlanOffer = widget.subscription.fixedValidityPlan?.offer?.replaceAll("%", "");
                                          double parsedFixedOffer = 0;
                                          if (fixedPlanOffer != null && fixedPlanOffer.isNotEmpty) {
                                            fixedPlanOffer = fixedPlanOffer.replaceAll("%", "").trim();
                                            try {
                                              parsedFixedOffer = double.parse(fixedPlanOffer);
                                            } catch (e) {
                                              print("Error parsing fixedPlanOffer: $e");
                                            }
                                          }
                                          double fixedOfferPrice = (widget.subscription.fixedValidityPlan?.price ?? 0) * ((100 - parsedFixedOffer) / 100);

                                          setState(() {
                                            selectedPlanMonth = widget.subscription.fixedValidityPlan?.text;
                                            discountedPrice = fixedOfferPrice.toInt();
                                            originalPrice = widget.subscription.fixedValidityPlan?.price;
                                            isFixValidity = true;
                                            _selectedIndex = -1;
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isFixValidity ? ThemeManager.blueFinal : material.Colors.transparent,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: isFixValidity
                                                  ? material.Colors.transparent
                                                  : ThemeManager.black.withOpacity(0.28),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                                              vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                if (widget.subscription.fixedValidityPlan?.offer != null)
                                                  Text(
                                                    "₹ ${widget.subscription.fixedValidityPlan?.price}",
                                                    style: interRegular.copyWith(
                                                      fontSize: Dimensions.fontSizeDefaultLarge,
                                                      fontWeight: FontWeight.w500,
                                                      color: isFixValidity ? ThemeManager.white : ThemeManager.black.withOpacity(0.8),
                                                      decoration: TextDecoration.lineThrough,
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "₹ ${widget.subscription.fixedValidityPlan?.offer == null ? widget.subscription.fixedValidityPlan?.price : fixedOfferPrice.toStringAsFixed(0)}",
                                                  style: interRegular.copyWith(
                                                    fontSize: isFixValidity ? Dimensions.fontSizeLarge : Dimensions.fontSizeDefaultLarge,
                                                    fontWeight: isFixValidity ? FontWeight.w700 : FontWeight.w600,
                                                    color: isFixValidity ? ThemeManager.white : ThemeManager.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            else
                              const SizedBox(),
                            const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT * 2),
                            Observer(builder: (BuildContext context) {
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
                                      height: Dimensions.PADDING_SIZE_DEFAULT),
                                  SizedBox(
                                    height:
                                        Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
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
                                          fontSize: Dimensions.fontSizeDefault,
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
                                                  couponId = matchingCoupon.sId;
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
                                                  color: ThemeManager.blueFinal,
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
                                              bottomLeft: Radius.circular(3.4),
                                              bottomRight: Radius.circular(3.4),
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
                            }),
                            const SizedBox(
                                height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 1.4),
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
                                                _currentindex = index;
                                                offerId = store
                                                    .getAllOfferUser[index]
                                                    ?.sId;
                                                getOfferDiscount(store);
                                                apply = true;
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
                                height: Dimensions.PADDING_SIZE_DEFAULT),
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
                                    "₹ ${discountedPrice - discountCoupon - discountOffer}",
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
                                  loggedIn == true
                                      ? _startPayment(store)
                                      :
                                      // Navigator.of(context).pushNamed(Routes.loginWithPass);
                                      Navigator.of(context)
                                          .pushNamed(Routes.login);
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
                          if ((Platform.isWindows || Platform.isMacOS)) ...[
                            const Spacer(),
                            material.InkWell(
                              onTap: () {
                                loggedIn == true
                                    ? _startPayment(store)
                                    :
                                    // Navigator.of(context).pushNamed(Routes.loginWithPass);
                                    Navigator.of(context)
                                        .pushNamed(Routes.login);
                              },
                              child: Container(
                                alignment: Alignment.center,
                                height: Dimensions.PADDING_SIZE_LARGE * 2.2,
                                padding: const EdgeInsetsDirectional.symmetric(
                                    horizontal: 100),
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
                          ]
                        ],
                      ),
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text(
                    //       "Total Payable amount",
                    //       style: interMedium.copyWith(
                    //         fontSize: Dimensions.fontSizeExtraLarge,
                    //         fontWeight: FontWeight.w500,
                    //         color:  ThemeManager.black,
                    //       ),
                    //     ),
                    //     Text(
                    //       "₹ ${discountedPrice - (discountPrice??0))*100:${(discountedPrice - discountCoupon - discountOffer) * 100}",
                    //       style: interMedium.copyWith(
                    //         fontSize: Dimensions.fontSizeExtraLarge,
                    //         fontWeight: FontWeight.w500,
                    //         color:  ThemeManager.black,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                    //
                    // CustomButton(
                    //   onPressed: () {
                    //     loggedIn==true?
                    //     _startPayment(store):
                    //     // Navigator.of(context).pushNamed(Routes.loginWithPass);
                    //     Navigator.of(context).pushNamed(Routes.login);
                    //   },
                    //   buttonText: "Continue to Purchase",
                    //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                    //   textAlign: TextAlign.center,
                    //   radius: Dimensions.RADIUS_DEFAULT,
                    //   transparent: true,
                    //   bgColor:  material.Theme.of(context).primaryColor,
                    //   fontSize: Dimensions.fontSizeDefault,
                    // ),
                    // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                  ],
                ),
              ),
            ),
          ],
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

    debugPrint("discountPercentage: $discountPercentage");
    debugPrint("discountPrize: $discountPrize");

    if (discountPrize != 0) {
      discountOffer = discountPrize.toInt();
    } else {
      discountOffer = (discountedPrice * ((discountPercentage / 100))).toInt();
    }

    debugPrint("discountedPrice: $discountedPrice");
    debugPrint("Calculated discountOffer: $discountOffer");
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
    String apiKey = store.paymentDetails.value?.razorpayKey ?? "rzp_test_mV7hVxiuC3ljvo";
    String apiSecret = store.paymentDetails.value?.razorpaySecretKey ?? "sFN1bvTqaGVSPpA2kVfTk2q5";
    debugPrint('razorapikey$apiKey');
    // String apiKey = 'rzp_test_mV7hVxiuC3ljvo';
    // String apiSecret = 'sFN1bvTqaGVSPpA2kVfTk2q5';

    Map<String, dynamic> paymentData = {
      'amount': (discountedPrice - discountCoupon - discountOffer) * 100,
      'currency': 'INR',
      'receipt': 'order_receipt',
      'payment_capture': '1',
    };

    debugPrint(" (discountedPrice - (discountPrice??0))*100:${(discountedPrice - discountCoupon - discountOffer) * 100}");
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
        Navigator.of(context).push(material.MaterialPageRoute(
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
    final SubscriptionStore store = widget.store;
    final String? month = selectedPlanMonth;
    final int amount = discountedPrice - discountCoupon - discountOffer;
    final String? subscriptionId = widget.subscription.sid;
    final String? durationid = durationId;
    final String? offerid = offerId;

    if (subscriptionId == null) return;

    await store.onPurcaseSubscriptionApiCall(
      subscriptionId,
      amount,
      month ?? "",
      durationid ?? "",
      response.paymentId!,
      response.orderId!,
      response.signature!,
      couponId ?? '',
      offerid ?? '',
    );

    if (_currentindex != null) {
      final bool isSingleUse = store.getAllOfferUser[_currentindex!]?.isSingleUse == true;
      if (isSingleUse) {
        await store.onPurcaseUserOfferApiCall(offerid ?? '');
      }
    }

    RazorpayPayment.dispose();

    Navigator.of(context).pushNamed(Routes.paymentStatus, arguments: {
      'amount': amount,
      'dateTime': DateTime.now(),
      'paymentId': response.paymentId
    });
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    final int amount = discountedPrice - discountCoupon - discountOffer;
    Navigator.of(context).pushNamed(Routes.paymentFailed, arguments: {
      'amount': amount,
      'dateTime': DateTime.now(),
    });
  }

  Future<void> _handleApplePurchaseSuccess(dynamic details, SubscriptionStore store) async {
    try {
      final String? subscriptionId = widget.subscription.sid;
      final String? month = selectedPlanMonth;
      final String? durationid = durationId;
      // Align amount calculation with Razorpay order creation
      final int amount = discountedPrice - discountCoupon - discountOffer;
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
}
