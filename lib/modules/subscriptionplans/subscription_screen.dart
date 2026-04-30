// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, unused_field, unused_local_variable, dead_null_aware_expression, prefer_interpolation_to_compose_strings, use_build_context_synchronously, avoid_unnecessary_containers, library_private_types_in_public_api, duplicate_ignore, unused_element

import 'dart:io';
import '../../app/routes.dart';
import 'package:intl/intl.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/styles.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import '../../helpers/dimensions.dart';
import '../widgets/custom_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'model/get_all_user_order_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/no_internet_connection.dart';
import '../../models/subscribed_plan_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key, this.isHome = false});
  final bool isHome;
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const SubscriptionScreen(),
    );
  }
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final int _selectedIndex = 0;
  bool loggedIn = false;
  String formattedDateTime = '';
  Future<bool>? isLogged;

  @override
  void initState() {
    super.initState();
    _getOrderHistory();
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    store.onRegisterApiCall(context, true, false);
    // store.onRegisterApiCall(context,'');
    store.onGetSubscribedUserPlan();
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

  Future<void> _getOrderHistory() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetUserAllOrderHistory();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SubscriptionStore>(context);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      // appBar: AppBar(
      //   elevation: 0,
      //   automaticallyImplyLeading: false,
      //   backgroundColor: ThemeManager.white,
      //   leading: Padding(
      //     padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_SMALL),
      //     child:       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
      //       icon:  Icon(Icons.arrow_back_ios, color: ThemeManager.iconColor),
      //       onPressed: () {
      //         Navigator.of(context).pushNamed(Routes.dashboard);
      //       },
      //     ),
      //   ),
      //   title: Row(
      //     mainAxisAlignment: MainAxisAlignment.start,
      //     children: [
      //       // SvgPicture.asset("assets/image/bookmark_plan.svg"),
      //       // const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
      //       Text(
      //         "My Plan!",
      //         style: interRegular.copyWith(
      //           fontSize: Dimensions.fontSizeExtraLarge,
      //           fontWeight: FontWeight.w600,
      //           color: ThemeManager.black,
      //         ),
      //       ),
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
              padding: EdgeInsets.only(
                  top: (Platform.isMacOS || Platform.isWindows)
                      ? Dimensions.PADDING_SIZE_LARGE * 1.3
                      : Dimensions.PADDING_SIZE_LARGE * 2.7,
                  left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                  right: Dimensions.PADDING_SIZE_LARGE * 1.2,
                  bottom: Dimensions.PADDING_SIZE_SMALL * 1.3),
              child: Row(
                children: [
                  ...[
                    if (!widget.isHome)
                      IconButton(
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: AppColors.white,
                            size: 18,
                          )),
                    const SizedBox(
                      width: Dimensions.PADDING_SIZE_DEFAULT,
                    ),
                  ],
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: Text(
                      "My Plan & Orders ",
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
                    left: Dimensions.PADDING_SIZE_LARGE * 1.2,
                    right: Dimensions.PADDING_SIZE_LARGE * 1.2,
                    top: Dimensions.PADDING_SIZE_LARGE * 1.2),
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: (Platform.isMacOS || Platform.isWindows)
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Text(
                      'Active Plan',
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        fontWeight: FontWeight.w600,
                        color: ThemeManager.black,
                      ),
                    ),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_SMALL,
                    ),
                    Observer(
                      builder: (_) {
                        return store.isConnected
                            ? store.subscribedPlan.isNotEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        // left: Dimensions.PADDING_SIZE_LARGE,
                                        // top: Dimensions.PADDING_SIZE_DEFAULT,
                                        // right: Dimensions.PADDING_SIZE_LARGE,
                                        bottom: Dimensions.PADDING_SIZE_LARGE,
                                      ),
                                      child: store.isLoading
                                          ? Center(
                                              child: CircularProgressIndicator(
                                                  color: Theme.of(context)
                                                      .primaryColor))
                                          : Column(
                                              children: [
                                                buildSubscribedPlansView()
                                              ],
                                            ),
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                            height: Dimensions
                                                .PADDING_SIZE_EXTRA_LARGE),
                                        SizedBox(
                                          child: Text(
                                            'No Subscribed Plans Found',
                                            style: interRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeExtraLarge,
                                              fontWeight: FontWeight.w600,
                                              color: ThemeManager.black,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                            height: Dimensions
                                                .PADDING_SIZE_DEFAULT),
                                        CustomButton(
                                          onPressed: () {
                                            Navigator.of(context).pushNamed(
                                                Routes.subscriptionList);
                                          },
                                          buttonText: "Subscribe now",
                                          height: Dimensions
                                                  .PADDING_SIZE_EXTRA_LARGE *
                                              2,
                                          width:
                                              Dimensions.PADDING_SIZE_DEFAULT *
                                                  10,
                                          textAlign: TextAlign.center,
                                          radius: Dimensions.RADIUS_DEFAULT,
                                          transparent: true,
                                          bgColor:
                                              Theme.of(context).primaryColor,
                                          fontSize: Dimensions.fontSizeDefault,
                                        ),
                                      ],
                                    ),
                                  )
                            : const NoInternetScreen();
                      },
                    ),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_DEFAULT,
                    ),
                    Text(
                      'Order History',
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        fontWeight: FontWeight.w600,
                        color: ThemeManager.black,
                      ),
                    ),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_SMALL,
                    ),
                    Observer(builder: (context) {
                      return store.isConnected
                          ? store.orderUserHistory.isNotEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: Dimensions.PADDING_SIZE_LARGE,
                                    ),
                                    child: store.isLoading
                                        ? Center(
                                            child: CircularProgressIndicator(
                                                color: Theme.of(context)
                                                    .primaryColor))
                                        : Column(
                                            children: [
                                              ListView.builder(
                                                itemCount: store
                                                    .orderUserHistory.length,
                                                shrinkWrap: true,
                                                padding: EdgeInsets.zero,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  GetAllUserOrderModel?
                                                      orderHistory =
                                                      store.orderUserHistory[
                                                          index];

                                                  return Container(
                                                    margin: const EdgeInsets
                                                        .only(
                                                        bottom: Dimensions
                                                            .PADDING_SIZE_SMALL),
                                                    decoration: BoxDecoration(
                                                        color: ThemeManager
                                                                    .currentTheme ==
                                                                AppTheme.Dark
                                                            ? Colors.transparent
                                                            : const Color(
                                                                0xFFF2F8FF),
                                                        border: Border.all(
                                                            color: ThemeManager
                                                                .mainBorder),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(7)),
                                                    child: Column(
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets
                                                              .only(
                                                              left: Dimensions
                                                                  .PADDING_SIZE_DEFAULT,
                                                              top: Dimensions
                                                                  .PADDING_SIZE_DEFAULT,
                                                              right: Dimensions
                                                                  .PADDING_SIZE_DEFAULT),
                                                          child: Row(
                                                            children: [
                                                              Image.asset(
                                                                  "assets/image/bookCover.png",
                                                                  height: 80,
                                                                  width: 80),
                                                              // Image.network(orderHistory?.bookImg??'')
                                                              const SizedBox(
                                                                  width: Dimensions
                                                                      .PADDING_SIZE_DEFAULT),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerRight,
                                                                      child:
                                                                          Text(
                                                                        'Ordered on ${orderFormatDate(orderHistory?.created_at ?? '')}',
                                                                        style: interRegular
                                                                            .copyWith(
                                                                          fontSize:
                                                                              Dimensions.fontSizeExtraSmall,
                                                                          fontWeight:
                                                                              FontWeight.w400,
                                                                          color:
                                                                              ThemeManager.textColor3,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.4,
                                                                      child:
                                                                          Row(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.end,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        children: [
                                                                          Expanded(
                                                                            child:
                                                                                Text(
                                                                              orderHistory?.bookName ?? '',
                                                                              style: interRegular.copyWith(
                                                                                fontSize: Dimensions.fontSizeSmall,
                                                                                fontWeight: FontWeight.w500,
                                                                                color: ThemeManager.black,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          // Expanded(
                                                                          //   child: Text('(Qty - 1)',
                                                                          //     style: interRegular.copyWith(
                                                                          //       fontSize: Dimensions.fontSizeExtraSmall,
                                                                          //       fontWeight: FontWeight.w400,
                                                                          //       color: ThemeManager.textColor3,
                                                                          //     ),),
                                                                          // ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          Dimensions.PADDING_SIZE_EXTRA_SMALL *
                                                                              1.6,
                                                                    ),
                                                                    Row(
                                                                      children: [
                                                                        Text(
                                                                          "${orderHistory?.bookType}",
                                                                          style:
                                                                              interRegular.copyWith(
                                                                            fontSize:
                                                                                Dimensions.fontSizeExtraSmall,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                            color:
                                                                                ThemeManager.textColor3,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                Dimensions.PADDING_SIZE_EXTRA_SMALL),
                                                                        Container(
                                                                          height:
                                                                              Dimensions.PADDING_SIZE_SMALL * 1.7,
                                                                          alignment:
                                                                              Alignment.center,
                                                                          padding: const EdgeInsets
                                                                              .symmetric(
                                                                              horizontal: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.6),
                                                                          decoration: BoxDecoration(
                                                                              border: Border.all(color: ThemeManager.mainBorder),
                                                                              borderRadius: BorderRadius.circular(8.5),
                                                                              color: ThemeManager.primaryTrans),
                                                                          child:
                                                                              Text(
                                                                            "${orderHistory?.volume} Volumes",
                                                                            style:
                                                                                interRegular.copyWith(
                                                                              fontSize: Dimensions.fontSizeExtraSmall,
                                                                              fontWeight: FontWeight.w400,
                                                                              color: AppColors.white,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerRight,
                                                                      child:
                                                                          Text(
                                                                        '₹ ${orderHistory?.price}',
                                                                        style: interRegular
                                                                            .copyWith(
                                                                          fontSize:
                                                                              Dimensions.fontSizeExtraLarge,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                          color:
                                                                              ThemeManager.black,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: Dimensions
                                                              .PADDING_SIZE_SMALL,
                                                        ),
                                                        Divider(
                                                          color: ThemeManager
                                                                      .currentTheme ==
                                                                  AppTheme.Dark
                                                              ? ThemeManager
                                                                  .mainBorder
                                                              : ThemeManager
                                                                  .primaryColor
                                                                  .withOpacity(
                                                                      0.2),
                                                          thickness: 0.5,
                                                          height: 0,
                                                        ),
                                                        const SizedBox(
                                                          height: Dimensions
                                                              .PADDING_SIZE_SMALL,
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets
                                                              .only(
                                                              left: Dimensions
                                                                  .PADDING_SIZE_DEFAULT,
                                                              bottom: Dimensions
                                                                  .PADDING_SIZE_DEFAULT,
                                                              right: Dimensions
                                                                  .PADDING_SIZE_DEFAULT),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'Order details',
                                                                style:
                                                                    interRegular
                                                                        .copyWith(
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeExtraSmall,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color:
                                                                      ThemeManager
                                                                          .black,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: Dimensions
                                                                        .PADDING_SIZE_EXTRA_SMALL *
                                                                    1.6,
                                                              ),
                                                              Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        top: 3),
                                                                    child: SvgPicture
                                                                        .asset(
                                                                            "assets/image/orderLocation.svg"),
                                                                  ),
                                                                  const SizedBox(
                                                                      width: Dimensions
                                                                          .PADDING_SIZE_EXTRA_SMALL),
                                                                  Expanded(
                                                                    child: Text(
                                                                      [
                                                                        orderHistory
                                                                            ?.buildingNumber,
                                                                        orderHistory
                                                                            ?.landMark,
                                                                        orderHistory
                                                                            ?.city,
                                                                        orderHistory
                                                                            ?.state,
                                                                        orderHistory
                                                                            ?.pinCode,
                                                                      ]
                                                                          .where((element) =>
                                                                              true)
                                                                          .join(
                                                                              ", "),
                                                                      style: interRegular
                                                                          .copyWith(
                                                                        fontSize:
                                                                            Dimensions.fontSizeExtraSmall,
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                        color: ThemeManager
                                                                            .textColor3,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                height: Dimensions
                                                                        .PADDING_SIZE_EXTRA_SMALL *
                                                                    1.6,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    height: Dimensions
                                                                        .PADDING_SIZE_SMALL,
                                                                    width: Dimensions
                                                                        .PADDING_SIZE_SMALL,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    decoration: const BoxDecoration(
                                                                        color: Color(
                                                                            0xFF33AD48),
                                                                        shape: BoxShape
                                                                            .circle),
                                                                    child: Icon(
                                                                      Icons
                                                                          .check,
                                                                      size: 10,
                                                                      color: ThemeManager
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      width: Dimensions
                                                                          .PADDING_SIZE_EXTRA_SMALL),
                                                                  Expanded(
                                                                    child: orderHistory?.status ==
                                                                            'Completed'
                                                                        ? Text(
                                                                            'Order delivered on ${formatDate(orderHistory?.deliverDate ?? '')}',
                                                                            style:
                                                                                interRegular.copyWith(
                                                                              fontSize: Dimensions.fontSizeExtraSmall,
                                                                              fontWeight: FontWeight.w400,
                                                                              color: ThemeManager.textColor3,
                                                                            ),
                                                                          )
                                                                        : Text(
                                                                            'Order Pending',
                                                                            style:
                                                                                interRegular.copyWith(
                                                                              fontSize: Dimensions.fontSizeExtraSmall,
                                                                              fontWeight: FontWeight.w400,
                                                                              color: ThemeManager.textColor3,
                                                                            ),
                                                                          ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                              // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
                                              // CustomButton(
                                              //   onPressed: () {
                                              //     Navigator.of(context).pushNamed(Routes.subscriptionList);
                                              //   },
                                              //   buttonText: "View other plans",
                                              //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                                              //   textAlign: TextAlign.center,
                                              //   radius: Dimensions.RADIUS_DEFAULT,
                                              //   transparent: true,
                                              //   bgColor: Theme.of(context).primaryColor,
                                              //   fontSize: Dimensions.fontSizeDefault,
                                              // ),
                                            ],
                                          ),
                                  ),
                                )
                              : Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical:
                                            Dimensions.PADDING_SIZE_SMALL),
                                    child: Text(
                                      'No Order History Found',
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeExLarge,
                                        fontWeight: FontWeight.w600,
                                        color: ThemeManager.black,
                                      ),
                                    ),
                                  ),
                                )
                          : const NoInternetScreen();
                    }),
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

  String formatDate(String isoString) {
    DateTime dateTime = DateTime.parse(isoString);
    String formattedDate = DateFormat('d MMMM yyyy').format(dateTime);

    int day = dateTime.day;
    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }
    String dayWithSuffix = '$day$suffix';
    formattedDate = formattedDate.replaceFirst(RegExp(r'^\d+'), dayWithSuffix);

    return formattedDate;
  }

  String orderFormatDate(String isoString) {
    DateTime dateTime = DateTime.parse(isoString);
    String formattedDate = DateFormat('d MMMM').format(dateTime);

    int day = dateTime.day;
    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }
    String dayWithSuffix = '$day$suffix';
    formattedDate = formattedDate.replaceFirst(RegExp(r'^\d+'), dayWithSuffix);

    return formattedDate;
  }

  Widget buildSubscribedPlansView() {
    final store = Provider.of<SubscriptionStore>(context);
    return Platform.isWindows || Platform.isMacOS
        ? CustomDynamicHeightGridView(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 10,
            itemCount: store.subscribedPlan.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            builder: (BuildContext context, int index) {
              return buildSubscribedPlanItem(context, index);
            },
          )
        : ListView.builder(
            itemCount: store.subscribedPlan.length,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return buildSubscribedPlanItem(context, index);
            },
          );
  }
}

Widget buildSubscribedPlanItem(BuildContext context, int index) {
  final store = Provider.of<SubscriptionStore>(context);
  // Your existing item builder code
  SubscribedPlanModel? subscribedPlans = store.subscribedPlan[index];
  String? subPlanOffer = store.subscribedPlan[index]?.buyDuration?.offer
      ?.toString()
      .replaceAll("%", "");
  num offerPrice = (store.subscribedPlan[index]?.buyDuration?.price ??
      store.subscribedPlan[index]?.amount ??
      0);
  if (subPlanOffer != null && subPlanOffer.isNotEmpty) {
    try {
      double discountPercentage = double.parse(subPlanOffer);
      offerPrice *= (1 - (discountPercentage / 100));
    } catch (e) {
      debugPrint("catch");
    }
  }
  DateTime expiryDate = DateFormat("MMM dd, yyyy, hh:mm a")
      .parse(subscribedPlans?.expirationDate ?? '');
  DateTime startDate = DateFormat("yyyy-MM-ddTHH:mm:ss.SSSZ")
      .parse(subscribedPlans?.created_at ?? '');
  String formattedExpiryDate =
      DateFormat("MMMM dd'TH' yyyy").format(expiryDate);
  String formattedStartDate = DateFormat("MMMM dd'TH' yyyy").format(startDate);

  int monthsDifference = (expiryDate.year - startDate.year) * 12 +
      expiryDate.month -
      startDate.month;
  int yearsDifference = expiryDate.year - startDate.year;
  int daysDifference = monthsDifference * 30;

  return Container(
    margin: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_SMALL),
    decoration: BoxDecoration(
      color: ThemeManager.primaryTrans,
      border: Border.all(color: ThemeManager.mainBorder),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subscribedPlans?.plan_name ?? "",
                      style: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    "₹ ${offerPrice.toInt()}" ?? "",
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
              Row(
                children: [
                  Text(
                    'Starting Date : ',
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    formattedStartDate,
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
              Row(
                children: [
                  Text(
                    'Expiry Date : ',
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    formattedExpiryDate,
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
              Row(
                children: [
                  Text(
                    'Validity : ',
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    yearsDifference > 1
                        ? "$yearsDifference Years"
                        : daysDifference > 30
                            ? "$monthsDifference Months"
                            : "$daysDifference Days",
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(Routes.subscriptionList);
          },
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
                vertical: Dimensions.PADDING_SIZE_SMALL * 1.2),
            decoration: BoxDecoration(
                color: ThemeManager.blueprimary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                )),
            child: Text(
              "Renew Plan ",
              style: interRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
